import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/custom_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/http_remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/local_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_cache_data_source.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/data/repositories/local_picto_repository.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

/// Backend que pagina chico: recorta cada página a [pageSize] para forzar
/// el loop de paginado del sync (RF-5.7) con pocos items.
final class CappedRemoteDataSource implements RemoteCatalogDataSource {
  CappedRemoteDataSource({required this.pageSize, required this._inner});

  final int pageSize;
  final FakeRemoteCatalogDataSource _inner;

  /// Valores de `since` recibidos por `getPictos`, en orden (del fake interno).
  List<DateTime?> get pictosSinceCalls => _inner.pictosSinceCalls;

  @override
  Future<List<CategoryModel>> getCategories() => _inner.getCategories();

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) {
    return _inner.getPictos(categoryId: categoryId, since: since, limit: limit < pageSize ? limit : pageSize);
  }

  @override
  Future<PictoModel> getPicto(String id) => _inner.getPicto(id);
}

/// REQ-BCK-01: backend + sync de solo descarga del catálogo.
///
/// Repositorio real + SharedPreferences simulado + backend en memoria
/// (`FakeRemoteCatalogDataSource`): mismo contrato que el HTTP real.
void main() {
  final t1 = DateTime.utc(2026, 11, 1, 12);
  final t2 = DateTime.utc(2026, 11, 2, 12);
  final t3 = DateTime.utc(2026, 11, 3, 12);

  PictoModel remotePicto(String id, String label, String categoryId, DateTime updatedAt) {
    return PictoModel(
      id: 'remote-$id',
      label: label,
      categoryId: categoryId,
      imageUrl: 'http://localhost:8080/images/$id.png',
      source: PictoSource.remote,
      createdAt: t1,
      updatedAt: updatedAt,
    );
  }

  FakeRemoteCatalogDataSource backendWith({
    List<CategoryModel> categories = const <CategoryModel>[],
    List<PictoModel> pictos = const <PictoModel>[],
    Object? Function()? error,
  }) {
    return FakeRemoteCatalogDataSource(categories: categories, pictos: pictos, error: error);
  }

  LocalPictoRepository repositoryWith(RemoteCatalogDataSource remote) {
    return LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: remote,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('RF-5.5/RF-5.8: al sincronizar, el catálogo remoto se mergea con el local', () async {
    final remote = backendWith(
      categories: [
        const CategoryModel(id: 'lugares', name: 'Lugares', color: 0xFF2E86AB, icon: 'place'),
      ],
      pictos: [remotePicto('casa', 'casa', 'lugares', t1), remotePicto('agua', 'agua', 'alimentos', t1)],
    );
    final repository = repositoryWith(remote);

    await repository.syncFromRemote();

    final categories = await repository.getCategories();
    expect(categories.map((c) => c.id), contains('lugares'));
    // Sin duplicar: 'lugares' aparece una sola vez.
    expect(categories.where((c) => c.id == 'lugares'), hasLength(1));

    // El custom creado por el adulto y el remoto conviven (RF-5.8).
    await repository.createCategory(const Category(id: 'comida', name: 'Comida'));
    expect((await repository.getCategories()).map((c) => c.id), containsAll(['lugares', 'comida']));
    // Colisión: el remoto ya existe → la creación custom se rechaza.
    await expectLater(
      repository.createCategory(const Category(id: 'lugares', name: 'Lugares')),
      throwsA(isA<DuplicateCatalogException>()),
    );

    final pictos = await repository.getPictos();
    expect(pictos.map((p) => p.id), containsAll(['remote-casa', 'remote-agua']));
    expect(pictos.where((p) => p.source == PictoSource.remote), hasLength(2));

    final detail = await repository.getPicto('remote-casa');
    expect(detail, isNotNull);
    expect(detail!.label, 'casa');

    // RF-5.6: quedó cacheado → lecturas posteriores salen de local.
    expect(await repository.getPictos(categoryId: 'lugares'), hasLength(1));
  });

  test('RF-5.7: el sync es incremental — el segundo pedido usa since = último updatedAt', () async {
    final remote = backendWith(pictos: [
      remotePicto('a', 'a', 'lugares', t1),
      remotePicto('b', 'b', 'lugares', t2),
      remotePicto('c', 'c', 'lugares', t3),
    ]);
    final repository = repositoryWith(remote);

    await repository.syncFromRemote();
    // Primer sync: sin cache → since = epoch (descarga todo).
    expect(remote.pictosSinceCalls.first, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

    // Re-sync sin cambios: since = t3 (el más nuevo recibido) y no trae nada.
    await repository.syncFromRemote();
    expect(remote.pictosSinceCalls[1], t3);

    // El backend agrega un picto más nuevo; el sync trae solo ese.
    remote.addPicto(remotePicto('d', 'd', 'lugares', t3.add(const Duration(hours: 1))));
    await repository.syncFromRemote();
    final secondPage = remote.pictosSinceCalls[2];
    expect(secondPage, t3);
    expect(await repository.getPictos(), hasLength(4));
  });

  test('RF-5.7: el sync pagina cuando el remoto devuelve páginas completas', () async {
    final remote = CappedRemoteDataSource(
      pageSize: 2,
      inner: FakeRemoteCatalogDataSource(pictos: [
        remotePicto('1', '1', 'lugares', t1),
        remotePicto('2', '2', 'lugares', t1),
        remotePicto('3', '3', 'lugares', t2),
        remotePicto('4', '4', 'lugares', t2),
        remotePicto('5', '5', 'lugares', t3),
      ]),
    );
    // Página de 2 con 5 pictos → 3 páginas; el cursor avanza por página y no
    // se pierde ningún item.
    final repository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: remote,
      // El fake corta cada página a 2; el repo pide 2 por página para que
      // "página completa" signifique "hay más datos" (contrato de limit).
      syncPageLimit: 2,
    );

    await repository.syncFromRemote();
    expect(await repository.getPictos(), hasLength(5));
  });

  test('RF-5.10: backend caído → sync silencioso y catálogo local intacto', () async {
    final remote = backendWith(error: () => const DataSourceException('connection refused'));
    final repository = repositoryWith(remote);

    // No lanza: falla en silencio.
    await repository.syncFromRemote();

    final categories = await repository.getCategories();
    expect(categories.map((c) => c.id), isNot(contains('lugares')));
    expect(await repository.getPictos(), isEmpty);
  });

  test('RF-5.9: los remotos cacheados no se pueden borrar desde la app', () async {
    final remote = backendWith(
      categories: [const CategoryModel(id: 'lugares', name: 'Lugares', color: 0xFF2E86AB, icon: 'place')],
      pictos: [remotePicto('casa', 'casa', 'lugares', t1)],
    );
    final repository = repositoryWith(remote);
    await repository.syncFromRemote();

    await expectLater(
      repository.deletePicto('remote-casa', childProfileId: 'nina'),
      throwsA(isA<DataSourceException>()),
    );
    await expectLater(repository.deleteCategory('lugares'), throwsA(isA<DataSourceException>()));
    // El picto sigue ahí después del intento de borrado.
    expect(await repository.getPicto('remote-casa'), isNotNull);
  });

  test('RF-5.11: las lecturas nunca tocan la red — con remote "explosivo" el catálogo cacheado se sirve igual', () async {
    // Cache pre-poblado directo: simula un sync anterior exitoso.
    const cache = RemoteCatalogCacheDataSource();
    await cache.save(
      categories: [const CategoryModel(id: 'lugares', name: 'Lugares', color: 0xFF2E86AB, icon: 'place')],
      pictos: [remotePicto('casa', 'casa', 'lugares', t1)],
      syncedAt: t1,
    );

    final repository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: const ExplodingRemoteDataSource(),
    );

    // getCategories/getPictos/getPicto no explotan: salen del cache.
    expect((await repository.getCategories()).map((c) => c.id), contains('lugares'));
    expect((await repository.getPictos()).map((p) => p.id), contains('remote-casa'));
    expect((await repository.getPicto('remote-casa'))!.label, 'casa');
  });

  test('RF-5.6: el cache persiste con upsert por id y registra la última sync', () async {
    const cache = RemoteCatalogCacheDataSource();
    expect(await cache.loadCategories(), isEmpty);
    expect(await cache.lastSyncAt(), isNull);

    await cache.save(
      categories: [const CategoryModel(id: 'lugares', name: 'Lugares', color: 0xFF2E86AB, icon: 'place')],
      pictos: [remotePicto('casa', 'casa', 'lugares', t1)],
      syncedAt: t1,
    );

    // Upsert: mismo id, nombre cambiado → reemplaza, no duplica.
    await cache.save(
      categories: [const CategoryModel(id: 'lugares', name: 'Lugares!', color: 0xFF2E86AB, icon: 'place')],
      pictos: [remotePicto('parque', 'parque', 'lugares', t2)],
      syncedAt: t2,
    );

    final categories = await cache.loadCategories();
    expect(categories, hasLength(1));
    expect(categories.single.name, 'Lugares!');
    expect((await cache.loadPictos()).map((p) => p.id), containsAll(['remote-casa', 'remote-parque']));
    expect(await cache.lastSyncAt(), t2);
  });

  test('RF-5.1/RF-5.2: el cliente HTTP parsea la API y envía los filtros', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      if (request.url.path == '/api/v1/pictos') {
        return http.Response(
          '{"pictos": [{"id": "remote-casa", "label": "casa", "categoryId": "lugares",'
          ' "imageUrl": "http://localhost:8080/images/casa.png", "source": "remote",'
          ' "createdAt": "2026-11-01T12:00:00.000Z", "updatedAt": "2026-11-01T12:00:00.000Z",'
          ' "childProfileId": null}]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{"error": "no encontrado"}', 404, headers: {'content-type': 'application/json'});
    });
    final dataSource = HttpRemoteCatalogDataSource(
      client: client,
      baseUrl: 'http://localhost:8080',
    );

    final pictos = await dataSource.getPictos(
      categoryId: 'lugares',
      since: t1,
      limit: 50,
    );
    expect(requestedUri.path, '/api/v1/pictos');
    expect(requestedUri.queryParameters['categoryId'], 'lugares');
    expect(requestedUri.queryParameters['since'], '2026-11-01T12:00:00.000Z');
    expect(requestedUri.queryParameters['limit'], '50');
    expect(pictos, hasLength(1));
    expect(pictos.single.source, PictoSource.remote);
    expect(pictos.single.label, 'casa');

    await expectLater(dataSource.getPicto('remote-no-existe'), throwsA(isA<DataSourceException>()));
  });

  test('RF-5.10: error HTTP y timeout del backend → DataSourceException', () async {
    final failing = HttpRemoteCatalogDataSource(
      client: MockClient((request) async => http.Response('boom', 500)),
      baseUrl: 'http://localhost:8080',
    );
    await expectLater(failing.getCategories(), throwsA(isA<DataSourceException>()));

    final hanging = HttpRemoteCatalogDataSource(
      client: MockClient((request) => Completer<http.Response>().future),
      baseUrl: 'http://localhost:8080',
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(hanging.getCategories(), throwsA(isA<DataSourceException>()));
  });

  test('RF-5.8: pictos remotos con dueño respetan la visibilidad del chico activo', () async {
    final remote = backendWith(pictos: [
      remotePicto('compartido', 'compartido', 'lugares', t1),
      PictoModel(
        id: 'remote-privado',
        label: 'privado',
        categoryId: 'lugares',
        imageUrl: 'http://localhost:8080/images/privado.png',
        source: PictoSource.remote,
        createdAt: t1,
        updatedAt: t1,
        childProfileId: 'nina',
      ),
    ]);
    final repository = repositoryWith(remote);
    await repository.syncFromRemote();

    final nina = await repository.getPictos(childProfileId: 'nina');
    expect(nina.map((p) => p.id), containsAll(['remote-compartido', 'remote-privado']));

    final benja = await repository.getPictos(childProfileId: 'benja');
    expect(benja.map((p) => p.id), contains('remote-compartido'));
    expect(benja.map((p) => p.id), isNot(contains('remote-privado')));
  });
}
