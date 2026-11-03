import '../../../../core/error/app_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';
import '../datasources/custom_catalog_data_source.dart';
import '../datasources/local_catalog_data_source.dart';
import '../datasources/remote_catalog_data_source.dart';

final class LocalPictoRepository implements CategoryRepository, PictoRepository {
  LocalPictoRepository({
    required this.localDataSource,
    required this.customDataSource,
    required this.remoteDataSource,
  });

  final LocalCatalogDataSource localDataSource;

  final CustomCatalogDataSource customDataSource;

  final RemoteCatalogDataSource remoteDataSource;

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
    final customCategories = await customDataSource.loadCategories();
    return [...bundledCategories, ...customCategories];
  }

  @override
  Future<List<Picto>> getPictos({String? categoryId}) async {
    final bundledPictos = await _bundledPictos();
    final customPictos = await customDataSource.loadPictos();
    final all = [...bundledPictos, ...customPictos];
    if (categoryId == null) {
      return all;
    }
    return all.where((picto) => picto.categoryId == categoryId).toList();
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
    return customDataSource.saveCategory(Category(id: id, name: name, color: category.color));
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
    final id = 'custom-${now.microsecondsSinceEpoch}';
    return customDataSource.savePicto(
      Picto(
        id: id,
        label: label,
        categoryId: picto.categoryId,
        source: PictoSource.custom,
        imageUrl: picto.imageUrl,
        createdAt: now,
        updatedAt: now,
      ),
    );
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
