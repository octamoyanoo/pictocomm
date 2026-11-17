import 'dart:convert';
import 'dart:io';

import 'package:pictocomm_backend/pictocomm_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const String _base = 'http://localhost:8080';

/// REQ-BCK-02: subida bidireccional (RF-5.12 a RF-5.15, CA-5.10 a CA-5.19).
///
/// Cada test arranca un store real con seed del repo + uploads en un
/// directorio temporal: `uploads.json` y `data/images/uploads/`.
void main() {
  late Directory tempDir;
  late CatalogStore store;
  late Router router;
  late String uploadsPath;
  late String imagesDir;

  Future<Response> call(String method, String path, {Object? body}) {
    final uri = Uri.parse('$_base$path');
    final request = Request(method, uri, body: body == null ? null : jsonEncode(body));
    return router.call(request);
  }

  Future<Map<String, dynamic>> callJson(String method, String path, {Object? body}) async {
    final response = await call(method, path, body: body);
    return <String, dynamic>{
      'status': response.statusCode,
      'body': jsonDecode(await response.readAsString()) as Map<String, dynamic>,
    };
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pictocomm_uploads');
    uploadsPath = '${tempDir.path}${Platform.pathSeparator}uploads.json';
    imagesDir = '${tempDir.path}${Platform.pathSeparator}images';
    store = CatalogStore.loadFrom('data${Platform.pathSeparator}seed.json', uploadsPath: uploadsPath);
    router = buildApiRouter(store: store, imagesDirectory: imagesDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Map<String, Object> uploadBody({
    String? id,
    String label = 'leche',
    List<String> categoryIds = const ['alimentos'],
    String imageData = 'iVBORw0KGgo=',
    String imageMime = 'image/png',
    String updatedAt = '2026-11-10T10:00:00.000Z',
    String? childProfileId,
  }) {
    return <String, Object>{
      if (id != null) 'id': id,
      'label': label,
      'categoryIds': categoryIds,
      'imageData': imageData,
      'imageMime': imageMime,
      'updatedAt': updatedAt,
      if (childProfileId != null) 'childProfileId': childProfileId,
    };
  }

  test('RF-5.12/CA-5.10: POST /api/v1/pictos responde 201, guarda imagen y queda servible', () async {
    final response = await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-test-leche'));
    expect(response['status'], 201);
    expect(response['body']['source'], 'remote');
    expect(response['body']['categoryIds'], ['alimentos']);
    expect(response['body']['imageUrl'], '$_base/images/uploads/custom-test-leche.png');

    // El archivo existe y la imagen se sirve con su mime (RNF-5.9).
    final file = File('$imagesDir${Platform.pathSeparator}uploads${Platform.pathSeparator}custom-test-leche.png');
    expect(file.existsSync(), isTrue);
    final image = await call('GET', '/images/uploads/custom-test-leche.png');
    expect(image.statusCode, 200);
    expect(image.headers['content-type'], 'image/png');
    expect((await image.read().toList()).expand((b) => b).length, greaterThan(0));

    // Aparece en el listado con imageUrl absoluta.
    final listed = await callJson('GET', '/api/v1/pictos');
    final ids = (listed['body']['pictos'] as List).map((p) => (p as Map)['id']);
    expect(ids, contains('custom-test-leche'));
  });

  test('RF-5.12/CA-5.18: subidas inválidas responden 400 con error JSON', () async {
    expect((await callJson('POST', '/api/v1/pictos', body: uploadBody(label: ' ')))['status'], 400);
    expect((await callJson('POST', '/api/v1/pictos', body: uploadBody(categoryIds: <String>[])))['status'], 400);
    expect((await callJson('POST', '/api/v1/pictos', body: uploadBody(imageData: '')))['status'], 400);
    expect((await callJson('POST', '/api/v1/pictos', body: uploadBody(imageData: 'no-es-base64!!')))['status'], 400);
    expect((await callJson('POST', '/api/v1/pictos', body: uploadBody(imageMime: 'text/html')))['status'], 400);
    final noDate = uploadBody();
    noDate.remove('updatedAt');
    expect((await callJson('POST', '/api/v1/pictos', body: noDate))['status'], 400);
  });

  test('RF-5.12: POST con id duplicado responde 409 con la versión guardada', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-dup', updatedAt: '2026-11-11T10:00:00.000Z'));
    final second = await callJson(
      'POST',
      '/api/v1/pictos',
      body: uploadBody(id: 'custom-dup', label: 'otra', updatedAt: '2026-11-12T10:00:00.000Z'),
    );
    expect(second['status'], 409);
    expect(second['body']['label'], 'leche');
  });

  test('RF-5.13/CA-5.11: PUT edita nombre/categorías y el updatedAt refleja la edición', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-edit'));
    final updated = await callJson(
      'PUT',
      '/api/v1/pictos/custom-edit',
      body: <String, Object>{
        'label': 'leche en polvo',
        'categoryIds': ['alimentos', 'rutina'],
        'updatedAt': '2026-11-11T09:00:00.000Z',
      },
    );
    expect(updated['status'], 200);
    expect(updated['body']['label'], 'leche en polvo');
    expect(updated['body']['categoryIds'], ['alimentos', 'rutina']);
    expect(updated['body']['updatedAt'], '2026-11-11T09:00:00.000Z');
  });

  test('RF-5.13/CA-5.12: last-write-wins — la edición más vieja no pisa la más nueva', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-lww', updatedAt: '2026-11-12T12:00:00.000Z'));
    final stale = await callJson(
      'PUT',
      '/api/v1/pictos/custom-lww',
      body: <String, Object>{'label': 'versión vieja', 'updatedAt': '2026-11-11T12:00:00.000Z'},
    );
    expect(stale['status'], 200);
    expect(stale['body']['label'], 'leche', reason: 'la respuesta SIEMPRE trae la versión ganadora');
  });

  test('RF-5.13: PUT sobre seed responde 403, inexistente 404', () async {
    final seed = await callJson('PUT', '/api/v1/pictos/remote-lugares-casa', body: {
      'label': 'hack',
      'updatedAt': '2026-11-11T09:00:00.000Z',
    });
    expect(seed['status'], 403);
    final missing = await callJson('PUT', '/api/v1/pictos/custom-no-existe', body: {
      'updatedAt': '2026-11-11T09:00:00.000Z',
    });
    expect(missing['status'], 404);
  });

  test('RF-5.14/CA-5.13: DELETE marca deletedAt, deja de listarse y viaja como tumba en el sync', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-del', updatedAt: '2026-11-10T10:00:00.000Z'));
    final deleted = await callJson('DELETE', '/api/v1/pictos/custom-del');
    expect(deleted['status'], 200);
    expect(deleted['body']['deletedAt'], isNotNull);

    // El listado normal ya no lo muestra.
    final listed = await callJson('GET', '/api/v1/pictos');
    final ids = (listed['body']['pictos'] as List).map((p) => (p as Map)['id']);
    expect(ids, isNot(contains('custom-del')));

    // El detalle tampoco (parece borrado para los lectores).
    expect((await callJson('GET', '/api/v1/pictos/custom-del'))['status'], 404);

    // Pero el sync incremental la trae para que los dispositivos purguen.
    final since = await callJson('GET', '/api/v1/pictos?since=2026-11-09T00:00:00.000Z');
    final sinceIds = (since['body']['pictos'] as List).map((p) => (p as Map)['id']);
    expect(sinceIds, contains('custom-del'));
    final tombstone = (since['body']['pictos'] as List).whereType<Map>().firstWhere((p) => p['id'] == 'custom-del');
    expect(tombstone['deletedAt'], isNotNull);
  });

  test('RF-5.14: DELETE es idempotente y rechaza seed/inexistente', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-del2'));
    expect((await callJson('DELETE', '/api/v1/pictos/custom-del2'))['status'], 200);
    expect((await callJson('DELETE', '/api/v1/pictos/custom-del2'))['status'], 200);
    expect((await callJson('DELETE', '/api/v1/pictos/remote-lugares-casa'))['status'], 403);
    expect((await callJson('DELETE', '/api/v1/pictos/custom-nada'))['status'], 404);
  });

  test('RF-5.15: categorías — alta, edición y borrado lógico con tumbas', () async {
    final created = await callJson('POST', '/api/v1/categories', body: {
      'id': 'custom-estudio',
      'name': 'Estudio',
      'color': '#4CAF50',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    expect(created['status'], 201);
    expect(created['body']['custom'], false);

    final renamed = await callJson('PUT', '/api/v1/categories/custom-estudio', body: {
      'name': 'Estudio Casa',
      'updatedAt': '2026-11-11T10:00:00.000Z',
    });
    expect(renamed['status'], 200);
    expect(renamed['body']['name'], 'Estudio Casa');

    // Conflicto: la edición más vieja no pisa (RNF-5.10).
    final stale = await callJson('PUT', '/api/v1/categories/custom-estudio', body: {
      'name': 'viejo',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    expect(stale['body']['name'], 'Estudio Casa');

    final deleted = await callJson('DELETE', '/api/v1/categories/custom-estudio');
    expect(deleted['status'], 200);
    expect(deleted['body']['deletedAt'], isNotNull);

    // Tumba visible en el GET para purgar cache de dispositivos.
    final categories = await callJson('GET', '/api/v1/categories');
    final tombstone = (categories['body']['categories'] as List)
        .whereType<Map>()
        .firstWhere((c) => c['id'] == 'custom-estudio', orElse: () => <String, dynamic>{});
    expect(tombstone['deletedAt'], isNotNull);
  });

  test('RNF-5.8/CA-5.19: los uploads sobreviven un reinicio y el seed queda intacto', () async {
    await callJson('POST', '/api/v1/pictos', body: uploadBody(id: 'custom-persist', updatedAt: '2026-11-10T10:00:00.000Z'));
    await callJson('POST', '/api/v1/categories', body: {
      'id': 'custom-cat',
      'name': 'Nueva',
      'color': '#7C5CBF',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    await callJson('DELETE', '/api/v1/pictos/custom-persist');

    // "Reinicio": nuevo store desde los mismos archivos.
    final reloaded = CatalogStore.loadFrom('data${Platform.pathSeparator}seed.json', uploadsPath: uploadsPath);
    expect(reloaded.pictoById('custom-persist')!.isDeleted, isTrue);
    expect(reloaded.categoryById('custom-cat'), isNotNull);
    // El seed curado no cambió.
    expect(reloaded.pictoById('remote-lugares-casa'), isNotNull);
    expect(reloaded.pictos, hasLength(10), reason: 'el borrado lógico no saca items del seed');

    // El uploads.json escrito tiene formato de seed + deletedAt.
    final uploads = jsonDecode(File(uploadsPath).readAsStringSync()) as Map<String, dynamic>;
    expect(uploads['pictos'], hasLength(1));
    expect(uploads['categories'], hasLength(1));
  });
}
