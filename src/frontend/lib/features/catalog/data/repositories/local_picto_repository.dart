import '../../../../core/error/app_exception.dart';
import 'dart:ui' show Color;

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';
import '../models/picto_model.dart';
import '../datasources/custom_catalog_data_source.dart';
import '../datasources/local_catalog_data_source.dart';
import '../datasources/remote_catalog_cache_data_source.dart';
import '../datasources/remote_catalog_data_source.dart';

final class LocalPictoRepository implements CategoryRepository, PictoRepository {
  LocalPictoRepository({
    required this.localDataSource,
    required this.customDataSource,
    required this.remoteDataSource,
    this.cacheDataSource = const RemoteCatalogCacheDataSource(),
    this.syncPageLimit = 100,
  });

  final LocalCatalogDataSource localDataSource;

  final CustomCatalogDataSource customDataSource;

  final RemoteCatalogDataSource remoteDataSource;

  /// Cache local del catálogo remoto (REQ-BCK-01). Las lecturas salen de
  /// acá, nunca de la red (local-first, RF-5.11).
  final RemoteCatalogCacheDataSource cacheDataSource;

  /// Tamaño de página del sync incremental (RF-5.7): el loop corta cuando
  /// el backend devuelve menos que esto (fin de datos).
  final int syncPageLimit;

  /// Ids únicos aunque dos creaciones caigan en el mismo microsegundo.
  static int _idCounter = 0;

  @override
  Future<List<Category>> getCategories() async {
    final assets = await localDataSource.bundledImageAssets();
    final categoryIds = <String>{};
    for (final asset in assets) {
      final categoryId = _assetCategory(asset);
      if (categoryId != null) {
        categoryIds.add(categoryId);
      }
    }
    final bundledCategories = categoryIds.map((id) => Category(id: id, name: _humanize(id))).toList();
    // Las categorías persistidas siempre son personalizadas (RF3.9).
    final customCategories = [
      for (final stored in await customDataSource.loadCategories()) Category(
        id: stored.id,
        name: stored.name,
        color: stored.color,
        icon: stored.icon,
        custom: true,
      ),
    ];
    // REQ-BCK-01 (RF-5.8): el remoto cacheado se mergea por lectura, sin
    // duplicar ids ya presentes (bundled/custom ganan).
    final knownCategoryIds = <String>{
      for (final category in bundledCategories) category.id,
      for (final category in customCategories) category.id,
    };
    final remoteCategories = [
      for (final stored in await cacheDataSource.loadCategories())
        if (!knownCategoryIds.contains(stored.id))
          Category(id: stored.id, name: stored.name, color: Color(stored.color), icon: stored.icon),
    ];
    return [...bundledCategories, ...customCategories, ...remoteCategories];
  }

  @override
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId}) async {
    final bundledPictos = await _bundledPictos();
    final customPictos = await customDataSource.loadPictos();
    // RF3.6: con chico activo, la vista incluye los custom sin dueño (RF3.7)
    // y los de ese chico. Sin filtro, la gestión ve todos.
    final visibleCustomPictos = childProfileId == null
        ? customPictos
        : customPictos.where((picto) => picto.childProfileId == null || picto.childProfileId == childProfileId).toList();
    // REQ-BCK-01 (RF-5.6/RF-5.8): los remotos salen del cache local con la
    // misma regla de visibilidad (hoy llegan sin dueño, visibles para todos).
    final remotePictos = [
      for (final stored in await cacheDataSource.loadPictos()) stored.toEntity(),
    ];
    final visibleRemotePictos = childProfileId == null
        ? remotePictos
        : remotePictos.where((picto) => picto.childProfileId == null || picto.childProfileId == childProfileId).toList();
    final all = [...bundledPictos, ...visibleCustomPictos, ...visibleRemotePictos];
    if (categoryId == null) {
      return all;
    }
    return all.where((picto) => picto.categoryId == categoryId).toList();
  }

  @override
  Future<void> deletePicto(String id, {String? childProfileId}) async {
    final stored = await customDataSource.loadPictos();
    final target = stored.where((picto) => picto.id == id).firstOrNull;
    if (target == null) {
      throw const DataSourceException('Solo se pueden borrar pictogramas personalizados (RF3.8)');
    }
    // RF3.6/RF3.8: con sesión activa, no se puede borrar el picto de otro
    // chico. Los custom sin dueño (RF3.7) siguen borrables desde gestión.
    final activeChild = childProfileId;
    if (activeChild != null && target.childProfileId != null && target.childProfileId != activeChild) {
      throw const DataSourceException('El pictograma pertenece a otro chico (RF3.8)');
    }
    await customDataSource.deletePicto(id);
  }

  @override
  Future<void> deletePictosForChild(String childProfileId) async {
    await customDataSource.deletePictosForChild(childProfileId);
  }

  @override
  Future<void> deleteCategory(String id, {String? childProfileId}) async {
    final bundledIds = await _bundledCategoryIds();
    if (bundledIds.contains(id)) {
      throw const DataSourceException('El catálogo incluido no se puede borrar (RF3.9)');
    }
    final stored = await customDataSource.loadCategories();
    if (!stored.any((category) => category.id == id)) {
      throw const DataSourceException('La categoría no existe');
    }
    await customDataSource.deleteCategory(id, childProfileId: childProfileId);
  }

  @override
  Future<Picto?> getPicto(String id) async {
    final pictos = await getPictos();
    for (final picto in pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  @override
  Future<Category> createCategory(Category category) async {
    final name = category.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre de la categoría no puede estar vacío');
    }
    final id = _slugify(name);
    final existing = await getCategories();
    for (final stored in existing) {
      if (stored.id == id) {
        throw DuplicateCatalogException('Ya existe una categoría "$name"');
      }
    }
    return customDataSource.saveCategory(Category(id: id, name: name, color: category.color, custom: true));
  }

  @override
  Future<Picto> createPicto(Picto picto) async {
    final label = picto.label.trim();
    if (label.isEmpty) {
      throw const DataSourceException('El nombre del pictograma no puede estar vacío');
    }
    if (picto.imageUrl == null || picto.imageUrl!.isEmpty) {
      throw const DataSourceException('Elegí una imagen para el pictograma');
    }
    final now = DateTime.now().toUtc();
    final id = 'custom-${now.microsecondsSinceEpoch}-${_idCounter++}';
    return customDataSource.savePicto(
      Picto(
        id: id,
        label: label,
        categoryId: picto.categoryId,
        source: PictoSource.custom,
        imageUrl: picto.imageUrl,
        childProfileId: picto.childProfileId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// REQ-BCK-01: sync de solo descarga (RF-5.5 a RF-5.7).
  ///
  /// Descarga categorías y pictos nuevos del backend (`updatedAt` posterior
  /// al último sync), los cachea con upsert por id y avanza la fecha del
  /// sync. Se pagina con el `limit` máximo para no perder items cuando el
  /// catálogo remoto supera una página.
  ///
  /// Si el backend no está disponible (RF-5.10) falla en silencio: la app
  /// sigue con su catálogo local y sin errores visibles.
  Future<void> syncFromRemote() async {
    final pageLimit = syncPageLimit;
    try {
      final remoteCategories = await remoteDataSource.getCategories();
      var cursor = await cacheDataSource.lastSyncAt() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final fetched = <PictoModel>[];
      while (true) {
        final page = await remoteDataSource.getPictos(since: cursor, limit: pageLimit);
        if (page.isEmpty) {
          break;
        }
        fetched.addAll(page);
        if (page.length < pageLimit) {
          break;
        }
        final newest = page.map((picto) => picto.updatedAt).reduce(_newest);
        if (!newest.isAfter(cursor)) {
          // Guarda anti-loop: la página no avanzó el cursor.
          break;
        }
        cursor = newest;
      }
      final lastSync = fetched.isEmpty ? null : fetched.map((picto) => picto.updatedAt).reduce(_newest);
      await cacheDataSource.save(categories: remoteCategories, pictos: fetched, syncedAt: lastSync);
    } on AppException {
      // RF-5.10: backend caído / sin conexión / timeout → silencio.
    } on FormatException {
      // Respuesta malformada → también silenciosa (local-first).
    }
  }

  static DateTime _newest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  Future<Set<String>> _bundledCategoryIds() async {
    final assets = await localDataSource.bundledImageAssets();
    return {
      for (final asset in assets) ?_assetCategory(asset),
    };
  }

  Future<List<Picto>> _bundledPictos() async {
    final assets = await localDataSource.bundledImageAssets();
    final pictos = <Picto>[];
    for (final asset in assets) {
      final parsed = _parseAsset(asset);
      if (parsed == null) {
        continue;
      }
      final (pictoId, assetCategory, label) = parsed;
      pictos.add(
        Picto(
          id: pictoId,
          label: label,
          categoryId: assetCategory,
          source: PictoSource.bundled,
          imageUrl: asset,
          createdAt: _epoch,
          updatedAt: _epoch,
        ),
      );
    }
    return pictos;
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  (String id, String categoryId, String label)? _parseAsset(String asset) {
    final categoryId = _assetCategory(asset);
    if (categoryId == null) {
      return null;
    }
    final filename = asset.split('/').last;
    final dotIndex = filename.lastIndexOf('.');
    final label = dotIndex <= 0 ? filename : filename.substring(0, dotIndex);
    return (asset, categoryId, label);
  }

  String? _assetCategory(String asset) {
    final segments = asset.split('/');
    if (segments.length < 4) {
      return null;
    }
    return segments[2];
  }

  String _humanize(String id) {
    final words = id.split('-').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1));
    return words.join(' ');
  }

  String _slugify(String name) {
    final lowered = name.toLowerCase().trim();
    final buffer = StringBuffer();
    var previousWasSeparator = true;
    for (final rune in lowered.runes) {
      final character = String.fromCharCode(rune);
      final isAsciiLetterOrDigit = (rune >= 0x30 && rune <= 0x39) || (rune >= 0x61 && rune <= 0x7A);
      if (isAsciiLetterOrDigit) {
        buffer.write(character);
        previousWasSeparator = false;
      } else if (!previousWasSeparator) {
        buffer.write('-');
        previousWasSeparator = true;
      }
    }
    final slug = buffer.toString();
    return slug.endsWith('-') ? slug.substring(0, slug.length - 1) : slug;
  }
}
