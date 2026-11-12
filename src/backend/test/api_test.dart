import 'dart:convert';
import 'dart:io';

import 'package:pictocomm_backend/pictocomm_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const String _base = 'http://localhost:8080';

Future<Response> get(String path) {
  final handler = buildApiRouter(store: _store(), imagesDirectory: 'data/images');
  return handler(Request('GET', Uri.parse('$_base$path')));
}

Future<Map<String, dynamic>> getJson(String path) async {
  final response = await get(path);
  return <String, dynamic>{
    'status': response.statusCode,
    'body': jsonDecode(await response.readAsString()) as Map<String, dynamic>,
  };
}

/// Seed del repo (RF-5.3): 2 categorías propias (lugares, rutina) + pictos en
/// categorías bundled (alimentos, emociones).
CatalogStore _store() => CatalogStore.loadFrom('data/seed.json');

void main() {
  test('el seed del repo carga 2 categorías y 9 pictos', () {
    final store = _store();
    expect(store.categories.map((c) => c.id), ['lugares', 'rutina']);
    expect(store.pictos, hasLength(9));
  });

  test('un seed inválido arranca con catálogo vacío, sin crashear (UC-01.2 alt 1)', () {
    final directory = Directory.systemTemp.createTempSync('pictocomm_seed');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}bad.json';
    File(path).writeAsStringSync('{ no es json');

    final store = CatalogStore.loadFrom(path);
    expect(store.categories, isEmpty);
    expect(store.pictos, isEmpty);
  });

  test('GET /health responde 200 ok', () async {
    final response = await get('/health');
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {'status': 'ok'});
  });

  test('GET /api/v1/categories responde en el formato de CategoryModel (CA-5.1)', () async {
    final response = await getJson('/api/v1/categories');
    expect(response['status'], 200);
    final categories = response['body']['categories'] as List<dynamic>;
    expect(categories, hasLength(2));
    final lugares = categories.first as Map<String, dynamic>;
    expect(lugares['id'], 'lugares');
    expect(lugares['name'], 'Lugares');
    expect(lugares['color'], '#2E86AB');
    expect(lugares['icon'], 'place');
    expect(lugares['custom'], false);
  });

  test('GET /api/v1/pictos sin filtros devuelve todo el seed en formato PictoModel (CA-5.2)', () async {
    final response = await getJson('/api/v1/pictos');
    expect(response['status'], 200);
    final pictos = response['body']['pictos'] as List<dynamic>;
    expect(pictos, hasLength(9));
    final casa = pictos.first as Map<String, dynamic>;
    expect(casa['id'], 'remote-lugares-casa');
    expect(casa['label'], 'casa');
    expect(casa['categoryId'], 'lugares');
    // imageUrl absoluta (Image.network del frontend la resuelve directo).
    expect(casa['imageUrl'], '$_base/images/casa.png');
    expect(casa['source'], 'remote');
    expect(casa['createdAt'], '2026-11-01T12:00:00.000Z');
    expect(casa['childProfileId'], null);
  });

  test('GET /api/v1/pictos?categoryId filtra por categoría (CA-5.3)', () async {
    final response = await getJson('/api/v1/pictos?categoryId=rutina');
    final pictos = response['body']['pictos'] as List<dynamic>;
    expect(pictos.map((p) => (p as Map<String, dynamic>)['id']), [
      'remote-rutina-dormir',
      'remote-rutina-banarse',
      'remote-rutina-dientes',
    ]);
  });

  test('GET /api/v1/pictos?since es incremental y estricto (CA-5.3, RF-5.7)', () async {
    // Antes de todo el seed → devuelve todo.
    final all = await getJson('/api/v1/pictos?since=2026-10-01T00:00:00.000Z');
    expect(all['body']['pictos'], hasLength(9));

    // Exactamente igual al updatedAt de pileta → excluido (estricto).
    final strict = await getJson('/api/v1/pictos?since=2026-11-01T12:05:00.000Z');
    final strictIds = (strict['body']['pictos'] as List).map((p) => (p as Map)['id']);
    expect(strictIds, isNot(contains('remote-lugares-pileta')));
    expect(strictIds, contains('remote-lugares-abuela'));

    // Después de todo el seed → vacío (re-sync sin cambios, CA-5.7).
    final none = await getJson('/api/v1/pictos?since=2026-12-01T00:00:00.000Z');
    expect(none['body']['pictos'], isEmpty);
  });

  test('GET /api/v1/pictos?limit recorta el listado (CA-5.3)', () async {
    final response = await getJson('/api/v1/pictos?limit=3');
    expect((response['body']['pictos'] as List), hasLength(3));
  });

  test('limit fuera de rango responde 400 (CA-5.3)', () async {
    for (final limit in ['0', '501', 'abc']) {
      final response = await getJson('/api/v1/pictos?limit=$limit');
      expect(response['status'], 400, reason: 'limit=$limit');
      expect(response['body'], contains('error'));
    }
  });

  test('since no-ISO responde 400 (CA-5.3)', () async {
    final response = await getJson('/api/v1/pictos?since=ayer');
    expect(response['status'], 400);
    expect(response['body'], contains('error'));
  });

  test('GET /api/v1/pictos/{id} devuelve el detalle y 404 si no existe (CA-5.4)', () async {
    final found = await getJson('/api/v1/pictos/remote-rutina-dormir');
    expect(found['status'], 200);
    expect(found['body']['label'], 'dormir');

    final missing = await getJson('/api/v1/pictos/remote-no-existe');
    expect(missing['status'], 404);
    expect(missing['body'], contains('error'));
  });

  test('GET /images/{archivo} sirve los PNG del seed con su mime (RF-5.4)', () async {
    final response = await get('/images/casa.png');
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'image/png');
    expect((await response.read().toList()).expand((b) => b).length, greaterThan(0));
  });

  test('GET /images/{archivo} con archivo inexistente responde 404', () async {
    final response = await get('/images/no-existe.png');
    expect(response.statusCode, 404);
  });
}
