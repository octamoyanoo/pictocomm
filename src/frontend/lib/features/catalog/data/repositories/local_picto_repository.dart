import 'dart:async';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/data_url.dart';
import 'dart:ui' show Color;

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';
import '../datasources/custom_catalog_data_source.dart';
import '../datasources/local_catalog_data_source.dart';
import '../datasources/remote_catalog_cache_data_source.dart';
import '../datasources/remote_catalog_data_source.dart';
import '../datasources/remote_outbox_data_source.dart';

final class LocalPictoRepository implements CategoryRepository, PictoRepository {
  LocalPictoRepository({
    required this.localDataSource,
    required this.customDataSource,
    required this.remoteDataSource,
    this.cacheDataSource = const RemoteCatalogCacheDataSource(),
    this.outboxDataSource = const RemoteOutboxDataSource(),
    this.syncPageLimit = 100,
    this.onUploadEnqueued,
  });

  final LocalCatalogDataSource localDataSource;

  final CustomCatalogDataSource customDataSource;

  final RemoteCatalogDataSource remoteDataSource;

  /// Cache local del catálogo remoto (REQ-BCK-01). Las lecturas salen de
  /// acá, nunca de la red (local-first, RF-5.11).
  final RemoteCatalogCacheDataSource cacheDataSource;

  /// Cola de salida de la subida bidireccional (REQ-BCK-02, RF-5.17). Los
  /// cambios custom entran acá y se suben al backend con reintentos.
  final RemoteOutboxDataSource outboxDataSource;

  /// Tamaño de página del sync incremental (RF-5.7): el loop corta cuando
  /// el backend devuelve menos que esto (fin de datos).
  final int syncPageLimit;

  /// REQ-BCK-02 (RF-5.19): aviso de que el estado de subida cambió (la UI de
  /// sync refresca el contador). Asignado por el injector después de crear
  /// el repositorio.
  void Function()? onUploadEnqueued;

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
    // RF-5.18 (REQ-BCK-02): un remoto con id igual a un custom local se
    // descarta — gana la copia local del dispositivo dueño.
    final cachedRemotePictos = await cacheDataSource.loadPictos();
    final customIds = {for (final picto in visibleCustomPictos) picto.id};
    final remotePictos = [
      for (final stored in cachedRemotePictos)
        if (!customIds.contains(stored.id)) stored.toEntity(),
    ];
    final visibleRemotePictos = childProfileId == null
        ? remotePictos
        : remotePictos.where((picto) => picto.childProfileId == null || picto.childProfileId == childProfileId).toList();
    final all = [...bundledPictos, ...visibleCustomPictos, ...visibleRemotePictos];
    if (categoryId == null) {
      return all;
    }
    // REQ-CAT-02 (RF-3.15): filtro por pertenencia — un picto
    // multicategoría aparece en cada una de sus categorías.
    return all.where((picto) => picto.belongsTo(categoryId)).toList();
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
    // REQ-BCK-02 (RF-5.16): el borrado viaja al backend (lógico). Los
    // legacy sin dueño nunca subieron: nada que encolar.
    if (target.childProfileId != null) {
      await _enqueue(kind: RemoteOutboxDataSource.kindPicto, op: RemoteOutboxDataSource.opDelete, id: id);
    }
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
    // REQ-BCK-02 (RF-5.17): la cascada también viaja — pictos que pierden
    // la membresía suben su versión nueva (PUT) y los eliminados van como
    // DELETE. Se registran antes del borrado (la membresía original) y se
    // encolan después (el datasource avanzó updatedAt de los sobrevivientes).
    final affected = (await customDataSource.loadPictos()).where((picto) => picto.categoryIds.contains(id)).toList();
    await customDataSource.deleteCategory(id, childProfileId: childProfileId);
    final afterDelete = await customDataSource.loadPictos();
    final survivors = {for (final picto in afterDelete) picto.id};
    for (final picto in affected) {
      if (survivors.contains(picto.id)) {
        if (picto.childProfileId != null) {
          final updated = afterDelete.where((existing) => existing.id == picto.id).firstOrNull;
          if (updated != null) {
            await _enqueuePicto(updated, RemoteOutboxDataSource.opPut);
          }
        }
        continue;
      }
      if (picto.childProfileId != null) {
        // Cascado del chico activo (o sin dueño que no subió nunca).
        await _enqueue(kind: RemoteOutboxDataSource.kindPicto, op: RemoteOutboxDataSource.opDelete, id: picto.id);
      }
    }
    await _enqueue(kind: RemoteOutboxDataSource.kindCategory, op: RemoteOutboxDataSource.opDelete, id: id);
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
    return customDataSource.saveCategory(Category(id: id, name: name, color: category.color, custom: true))
        .then((created) async {
      // REQ-BCK-02 (RF-5.16): la categoría custom sube al backend.
      await _enqueueCategory(created, RemoteOutboxDataSource.opPost);
      return created;
    });
  }

  /// REQ-CAT-02 (RF-3.17): renombra/recolorea una categoría custom sin
  /// cambiar el id (la pertenencia de los pictos es por id).
  @override
  Future<Category> updateCategory(Category category) async {
    final name = category.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre de la categoría no puede estar vacío');
    }
    final bundledIds = await _bundledCategoryIds();
    final stored = await customDataSource.loadCategories();
    final target = stored.where((existing) => existing.id == category.id).firstOrNull;
    if (target == null) {
      throw const DataSourceException('La categoría no existe');
    }
    // El id no cambia, pero si el nombre nuevo colisiona con el slug de otra
    // categoría (incluidas las bundled) lo rechazamos: crearla luego sería
    // imposible (CA-3.19 usa el mismo criterio que createCategory).
    final newSlug = _slugify(name);
    if (newSlug != category.id) {
      final otherIds = <String>{
        ...bundledIds,
        for (final existing in stored)
          if (existing.id != category.id) existing.id,
      };
      if (otherIds.contains(newSlug)) {
        throw DuplicateCatalogException('Ya existe una categoría "$name"');
      }
    }
    final saved = await customDataSource.saveCategory(Category(
      id: category.id,
      name: name,
      color: category.color,
      icon: target.icon,
      custom: true,
    ));
    // REQ-BCK-02 (RF-5.16): la edición de la categoría sube al backend.
    await _enqueueCategory(saved, RemoteOutboxDataSource.opPut);
    return saved;
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
    // REQ-CAT-02 (RF-3.13): al menos una categoría.
    if (picto.categoryIds.isEmpty) {
      throw const DataSourceException('Elegí al menos una categoría para el pictograma');
    }
    final now = DateTime.now().toUtc();
    final id = 'custom-${now.microsecondsSinceEpoch}-${_idCounter++}';
    final persisted = await customDataSource.savePicto(
      Picto(
        id: id,
        label: label,
        categoryIds: [...picto.categoryIds],
        source: PictoSource.custom,
        imageUrl: picto.imageUrl,
        childProfileId: picto.childProfileId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // REQ-BCK-02 (RF-5.16): sube en background. Los legacy sin dueño (RF3.7)
    // no suben hasta que se les asigne chico (RF-3.19/RF-5.16).
    if (persisted.childProfileId != null) {
      await _enqueuePicto(persisted, RemoteOutboxDataSource.opPost);
    }
    return persisted;
  }

  /// REQ-CAT-02 (RF-3.16/RF-3.18/RF-3.19): edita un picto custom. Mismas
  /// validaciones que crear; solo customs editables y, con sesión, solo los
  /// del chico activo. El dueño solo cambia si el picto no tenía (RF-3.19,
  /// asignación de legacy).
  @override
  Future<Picto> updatePicto(Picto picto, {String? childProfileId}) async {
    final label = picto.label.trim();
    if (label.isEmpty) {
      throw const DataSourceException('El nombre del pictograma no puede estar vacío');
    }
    if (picto.imageUrl == null || picto.imageUrl!.isEmpty) {
      throw const DataSourceException('Elegí una imagen para el pictograma');
    }
    if (picto.categoryIds.isEmpty) {
      throw const DataSourceException('Elegí al menos una categoría para el pictograma');
    }
    final stored = await customDataSource.loadPictos();
    final target = stored.where((existing) => existing.id == picto.id).firstOrNull;
    if (target == null || target.source != PictoSource.custom) {
      throw const DataSourceException('Solo se pueden editar pictogramas personalizados (RF-3.18)');
    }
    final activeChild = childProfileId;
    if (activeChild != null && target.childProfileId != null && target.childProfileId != activeChild) {
      throw const DataSourceException('El pictograma pertenece a otro chico (RF-3.18)');
    }
    final now = DateTime.now().toUtc();
    final persisted = await customDataSource.savePicto(
      Picto(
        id: target.id,
        label: label,
        categoryIds: [...picto.categoryIds],
        source: PictoSource.custom,
        imageUrl: picto.imageUrl,
        childProfileId: target.childProfileId ?? picto.childProfileId,
        createdAt: target.createdAt,
        updatedAt: now,
      ),
    );
    // REQ-BCK-02 (RF-5.16): la edición sube al backend. Un legacy sigue sin
    // dueño si nadie lo asignó: no sube (RF-5.16).
    if (persisted.childProfileId != null) {
      await _enqueuePicto(persisted, RemoteOutboxDataSource.opPut, imageChanged: picto.imageUrl != target.imageUrl);
    }
    return persisted;
  }

  /// REQ-BCK-02 (RF-5.19): resultado del último sync de descarga. `true` si
  /// falló (backend caído, sin conexión, timeout) — alimenta el indicador
  /// "sin conexión". Se resetea en cada intento.
  bool lastSyncFailed = false;

  /// REQ-BCK-01: sync de solo descarga (RF-5.5 a RF-5.7) + purga de tumbas
  /// (REQ-BCK-02, RF-5.14/RF-5.15).
  ///
  /// Descarga categorías y pictos nuevos del backend (`updatedAt` posterior
  /// al último sync), los cachea con upsert por id y avanza la fecha del
  /// sync. Se pagina con el `limit` máximo para no perder items cuando el
  /// catálogo remoto supera una página. Los items borrados lógicamente
  /// llegan como tumbas y se **purgan** del cache local.
  ///
  /// Si el backend no está disponible (RF-5.10) falla en silencio: la app
  /// sigue con su catálogo local y sin errores visibles.
  Future<void> syncFromRemote() async {
    final pageLimit = syncPageLimit;
    lastSyncFailed = false;
    try {
      final remoteCategories = await remoteDataSource.getCategories();
      final aliveCategories = remoteCategories.where((category) => category.deletedAt == null).toList();
      final deletedCategoryIds = [
        for (final category in remoteCategories)
          if (category.deletedAt != null) category.id,
      ];
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
        final newest = page.map(_versionDate).reduce(_newest);
        if (!newest.isAfter(cursor)) {
          // Guarda anti-loop: la página no avanzó el cursor.
          break;
        }
        cursor = newest;
      }
      final alivePictos = fetched.where((picto) => picto.deletedAt == null).toList();
      final deletedPictoIds = [
        for (final picto in fetched)
          if (picto.deletedAt != null) picto.id,
      ];
      // El cursor también avanza con las tumbas: su fecha es la del borrado.
      final lastSync = fetched.isEmpty ? null : fetched.map(_versionDate).reduce(_newest);
      await cacheDataSource.save(categories: aliveCategories, pictos: alivePictos, syncedAt: lastSync);
      await cacheDataSource.purgeCategories(deletedCategoryIds);
      await cacheDataSource.purgePictos(deletedPictoIds);
    } on AppException {
      // RF-5.10: backend caído / sin conexión / timeout → silencio (pero el
      // indicador de sync lo refleja, RF-5.19).
      lastSyncFailed = true;
    } on FormatException {
      // Respuesta malformada → también silenciosa (local-first).
      lastSyncFailed = true;
    }
  }

  static DateTime _versionDate(PictoModel picto) => picto.deletedAt ?? picto.updatedAt;

  /// REQ-BCK-02 (RF-5.20): sincronización completa — vacía la cola de
  /// subida y después descarga lo nuevo del backend. Es lo que corre el
  /// botón "Sincronizar ahora" (y el arranque de la app).
  Future<void> syncNow() async {
    await flushOutbox();
    await syncFromRemote();
  }

  /// REQ-BCK-02 (RF-5.17): intenta vaciar el outbox contra el backend,
  /// en orden. Cualquier op subida se quita de la cola; si el backend no
  /// está (RF-5.10) corta en silencio y la cola espera el próximo intento.
  Future<void> flushOutbox() async {
    final ops = await outboxDataSource.load();
    for (final op in ops) {
      try {
        await _flushOne(op);
      } on AppException {
        // RF-5.10: backend caído / sin conexión / timeout. La op (y las
        // restantes) quedan en la cola para el próximo flush.
        return;
      }
      await outboxDataSource.remove(kind: op.kind, op: op.op, id: op.id);
      onUploadEnqueued?.call();
    }
  }

  /// REQ-BCK-02 (RF-5.17): cantidad de cambios pendientes de subida.
  Future<int> pendingUploadsCount() => outboxDataSource.count();

  Future<void> _flushOne(OutboxOperation op) async {
    switch (op.kind) {
      case RemoteOutboxDataSource.kindPicto:
        await _flushPicto(op);
      case RemoteOutboxDataSource.kindCategory:
        await _flushCategory(op);
      default:
        // Op desconocida: la descartamos para no trabar la cola.
        return;
    }
  }

  Future<void> _flushPicto(OutboxOperation op) async {
    if (op.op == RemoteOutboxDataSource.opDelete) {
      // Borrado lógico propagado; la tumba solo le interesa al server.
      await remoteDataSource.deletePicto(op.id);
      return;
    }
    final model = op.picto;
    if (model == null) {
      return;
    }
    switch (op.op) {
      case RemoteOutboxDataSource.opPost:
      case RemoteOutboxDataSource.opPut:
        final (mime, base64) = _imagePayload(model.imageUrl);
        if (base64 == null) {
          // Imagen no subible (no es data URL): el cambio queda solo local.
          return;
        }
        final remote = op.op == RemoteOutboxDataSource.opPost
            ? await remoteDataSource.postPicto(model, imageBase64: base64, imageMime: mime)
            : await remoteDataSource.putPicto(model, imageBase64: base64, imageMime: mime);
        // RNF-5.10 (adopción): si el server tenía una versión más nueva
        // (409), el picto local adopta los DATOS del server pero conserva
        // su imagen local (data URL) para seguir funcionando offline.
        if (remote.updatedAt.isAfter(model.updatedAt)) {
          await _adoptRemotePictoData(remote);
        }
    }
  }

  Future<void> _flushCategory(OutboxOperation op) async {
    if (op.op == RemoteOutboxDataSource.opDelete) {
      await remoteDataSource.deleteCategory(op.id);
      return;
    }
    final model = op.category;
    if (model == null) {
      return;
    }
    switch (op.op) {
      case RemoteOutboxDataSource.opPost:
      case RemoteOutboxDataSource.opPut:
        final remote = op.op == RemoteOutboxDataSource.opPost
            ? await remoteDataSource.postCategory(model)
            : await remoteDataSource.putCategory(model);
        // Adopción: si el server tenía otra versión (409), gana la suya.
        if (remote.name != model.name || remote.color != model.color) {
          await customDataSource.saveCategory(Category(
            id: remote.id,
            name: remote.name,
            color: Color(remote.color),
            icon: remote.icon,
            custom: true,
          ));
        }
    }
  }

  /// Adopción de la versión ganadora (RNF-5.10): actualiza el storage local
  /// del picto custom con label/categorías del server, conservando imagen y
  /// dueño locales (la copia offline del dispositivo dueño manda).
  Future<void> _adoptRemotePictoData(PictoModel remote) async {
    final stored = await customDataSource.loadPictos();
    final target = stored.where((picto) => picto.id == remote.id).firstOrNull;
    if (target == null) {
      return;
    }
    await customDataSource.savePicto(Picto(
      id: target.id,
      label: remote.label,
      categoryIds: remote.categoryIds,
      source: PictoSource.custom,
      imageUrl: target.imageUrl,
      childProfileId: target.childProfileId,
      createdAt: target.createdAt,
      updatedAt: remote.updatedAt,
    ));
  }

  /// (mime, base64) de la imagen del picto; base64 `null` si no es un data
  /// URL subible.
  (String, String?) _imagePayload(String? imageUrl) {
    if (imageUrl == null || !DataUrl.isDataUrl(imageUrl)) {
      return ('image/png', null);
    }
    try {
      final (mime, base64) = DataUrl.split(imageUrl);
      return (mime, base64);
    } on FormatException {
      return ('image/png', null);
    }
  }

  Future<void> _enqueuePicto(Picto picto, String op, {bool imageChanged = true}) async {
    final model = PictoModel.fromEntity(picto);
    await outboxDataSource.enqueue(
      kind: RemoteOutboxDataSource.kindPicto,
      op: op,
      id: picto.id,
      picto: model,
    );
    onUploadEnqueued?.call();
    // RF-5.16: fire-and-forget — se intenta subir ya mismo; si falla, el
    // outbox espera el próximo arranque/flush.
    unawaited(flushOutbox());
  }

  Future<void> _enqueueCategory(Category category, String op) async {
    final model = CategoryModel.fromEntity(category);
    await outboxDataSource.enqueue(
      kind: RemoteOutboxDataSource.kindCategory,
      op: op,
      id: category.id,
      category: model,
    );
    onUploadEnqueued?.call();
    unawaited(flushOutbox());
  }

  Future<void> _enqueue({required String kind, required String op, required String id}) async {
    await outboxDataSource.enqueue(kind: kind, op: op, id: id);
    onUploadEnqueued?.call();
    unawaited(flushOutbox());
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
          categoryIds: [assetCategory],
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
