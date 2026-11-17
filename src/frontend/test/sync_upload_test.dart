import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/custom_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/local_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

/// REQ-BCK-02: subida bidireccional — outbox (RF-5.16/RF-5.17), conflictos
/// (RNF-5.10), tumbas (RF-5.14/RF-5.15) y dedup de dueño (RF-5.18).
///
/// Repositorio real + SharedPreferences simulado + backend en memoria.
void main() {
  final t0 = DateTime.utc(2026, 11, 10, 10);

  Picto draftPicto(String label, {String? childId}) {
    return Picto(
      id: '',
      label: label,
      categoryIds: ['alimentos'],
      source: PictoSource.custom,
      imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
      childProfileId: childId,
      createdAt: t0,
      updatedAt: t0,
    );
  }

  LocalPictoRepository repositoryWith(RemoteCatalogDataSource remote) {
    return LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: remote,
    );
  }

  test('RF-5.16/CA-5.10: crear picto con dueño lo sube y vacía el outbox', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);

    final created = await repository.createPicto(draftPicto('banana', childId: 'nina'));
    await repository.flushOutbox();

    expect(remote.writeCalls, contains('post:${created.id}'));
    expect(await repository.pendingUploadsCount(), 0);
    // En el backend quedó el picto subido, servido como remote.
    final remotePictos = await remote.getPictos();
    expect(remotePictos.map((p) => p.id), contains(created.id));
    expect(remotePictos.firstWhere((p) => p.id == created.id).source, PictoSource.remote);
  });

  test('RF-5.16: los pictos legacy sin dueño no suben', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);

    final created = await repository.createPicto(draftPicto('sin dueno'));
    await repository.flushOutbox();

    expect(remote.writeCalls, isEmpty);
    expect(await repository.pendingUploadsCount(), 0);
    expect(created.childProfileId, isNull);
  });

  test('RF-5.17/CA-5.14: sin backend el cambio queda en el outbox y sube después', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final offline = FakeRemoteCatalogDataSource(error: () => const DataSourceException('backend caído'));
    final repository = repositoryWith(offline);

    final created = await repository.createPicto(draftPicto('banana', childId: 'nina'));
    await repository.flushOutbox();

    // Silencioso: la op queda esperando.
    expect(await repository.pendingUploadsCount(), 1);
    expect(offline.writeCalls, isEmpty);

    // El backend vuelve: el flush vacía la cola sin intervención.
    final online = FakeRemoteCatalogDataSource();
    final recovered = repositoryWith(online);
    await recovered.flushOutbox();

    expect(online.writeCalls, contains('post:${created.id}'));
    expect(await recovered.pendingUploadsCount(), 0);
  });

  test('RF-5.13/CA-5.12: conflicto — el server tenía una versión más nueva y el local la adopta (datos)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);

    final created = await repository.createPicto(draftPicto('banana', childId: 'nina'));
    await repository.flushOutbox();

    // Otro dispositivo editó el mismo picto más tarde y ya subió (una
    // versión del "futuro" respecto del reloj de este dispositivo).
    final newer = PictoModel(
      id: created.id,
      label: 'banana dulce',
      categoryIds: ['alimentos', 'merienda'],
      imageUrl: 'http://localhost:8080/images/uploads/${created.id}.png',
      source: PictoSource.remote,
      createdAt: t0,
      updatedAt: DateTime.utc(2099, 1, 1),
      childProfileId: 'nina',
    );
    await remote.putPicto(newer, imageBase64: 'iVBORw0KGgo=', imageMime: 'image/png');

    // Este dispositivo edita algo más viejo: el server gana y el local adopta.
    await repository.updatePicto(created.copyWith(label: 'banana local vieja'), childProfileId: 'nina');
    await repository.flushOutbox();

    final stored = await repository.getPicto(created.id);
    expect(stored!.label, 'banana dulce', reason: 'adopta los DATOS del server (RNF-5.10)');
    expect(stored.categoryIds, ['alimentos', 'merienda']);
    // La imagen local se conserva: el dueño sigue funcionando offline.
    expect(stored.imageUrl, startsWith('data:image/png;base64,'));
  });

  test('RF-5.14/CA-5.13: borrar picto con dueño encola DELETE y otro dispositivo lo purga en el sync', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);

    final created = await repository.createPicto(draftPicto('banana', childId: 'nina'));
    await repository.flushOutbox();

    // El "otro dispositivo" ya tiene el picto en SU cache remoto.
    await repository.cacheDataSource.save(categories: const [], pictos: remote.pictos, syncedAt: t0);

    await repository.deletePicto(created.id, childProfileId: 'nina');
    await repository.flushOutbox();

    expect(remote.writeCalls, contains('delete:${created.id}'));

    // El otro dispositivo sincroniza: la tumba purga su cache.
    final other = repositoryWith(remote);
    await other.syncFromRemote();
    final visible = await other.getPictos();
    expect(visible.map((p) => p.id), isNot(contains(created.id)));
  });

  test('CA-5.18: error del backend deja la op en el outbox para reintentar', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final rejecting = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(rejecting);

    final created = await repository.createPicto(draftPicto('banana', childId: 'nina'));
    await repository.flushOutbox();
    expect(await repository.pendingUploadsCount(), 0);

    // Ahora el backend empieza a rechazar: la op nueva espera el reintento.
    rejecting.setError(() => const DataSourceException('backend rechaza todo'));
    await repository.updatePicto(created.copyWith(label: 'cambio'), childProfileId: 'nina');
    await repository.flushOutbox();

    expect(await repository.pendingUploadsCount(), 1, reason: 'la op NO se descarta: se reintenta (RF-5.17)');
  });

  test('RF-5.18: un remoto cuyo id ya existe como custom local no se duplica en lectura', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final local = CustomCatalogDataSource();
    final custom = await local.savePicto(Picto(
      id: 'custom-dup',
      label: 'banana local',
      categoryIds: ['alimentos'],
      source: PictoSource.custom,
      imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
      childProfileId: 'nina',
      createdAt: t0,
      updatedAt: t0,
    ));

    final remote = FakeRemoteCatalogDataSource(pictos: [
      PictoModel(
        id: 'custom-dup',
        label: 'banana del server',
        categoryIds: ['alimentos'],
        imageUrl: 'http://localhost:8080/images/custom-dup.png',
        source: PictoSource.remote,
        createdAt: t0,
        updatedAt: t0,
        childProfileId: 'nina',
      ),
    ]);
    final repository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: local,
      remoteDataSource: remote,
    );

    final pictos = await repository.getPictos(childProfileId: 'nina');
    final dupes = pictos.where((picto) => picto.id == 'custom-dup').toList();
    expect(dupes, hasLength(1));
    expect(dupes.single.label, custom.label, reason: 'gana la copia local del dispositivo dueño');
  });

  test('RF-5.15: categoría custom sube (POST) y su edición sube (PUT)', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);

    final category = await repository.createCategory(Category(id: '', name: 'Estudio', color: const Color(0xFF4CAF50)));
    await repository.flushOutbox();
    expect(remote.writeCalls, contains('post:${category.id}'));
    expect(await repository.pendingUploadsCount(), 0);

    await repository.updateCategory(Category(id: category.id, name: 'Estudio Casa', custom: true));
    await repository.flushOutbox();
    expect(remote.writeCalls, contains('put:${category.id}'));
    expect(remote.writtenCategories.any((c) => c.name == 'Estudio Casa'), isTrue);
  });

  test('RF-5.19: SyncService refleja estados offline / synced / pending', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final remote = FakeRemoteCatalogDataSource();
    final repository = repositoryWith(remote);
    final service = SyncService(catalogRepository: repository);

    // Backend caído → offline.
    remote.setError(() => const DataSourceException('caído'));
    await service.syncNow();
    expect(service.status, SyncStatus.offline);

    // Backend disponible, sin pendientes → synced.
    remote.setError(null);
    await service.syncNow();
    expect(service.status, SyncStatus.synced);

    // Cambio con backend rechazando → pending (la op espera).
    remote.setError(() => const DataSourceException('rechaza'));
    final repository2 = repositoryWith(remote);
    await repository2.createPicto(draftPicto('banana', childId: 'nina'));
    await repository2.flushOutbox();
    final service2 = SyncService(catalogRepository: repository2);
    await service2.syncNow();
    expect(service2.status, SyncStatus.pending);
    expect(service2.pendingCount, 1);
  });
}
