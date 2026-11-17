import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/picto.dart' show PictoSource;
import '../models/category_model.dart';
import '../models/picto_model.dart';
import 'remote_catalog_data_source.dart';

/// Implementación real de [RemoteCatalogDataSource] contra el backend
/// de PictoComm (REQ-BCK-01 lectura, REQ-BCK-02 escritura).
///
/// La URL se configura en compile-time (RNF-5.3): en desktop/web apunta a
/// `localhost:8080`; en Android emulador se corre con
/// `--dart-define=PICTOCOMM_BACKEND_URL=http://10.0.2.2:8080`.
final class HttpRemoteCatalogDataSource implements RemoteCatalogDataSource {
  HttpRemoteCatalogDataSource({
    http.Client? client,
    this.baseUrl = defaultBackendUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static const String defaultBackendUrl = String.fromEnvironment(
    'PICTOCOMM_BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  // ---- Descarga (REQ-BCK-01) ----

  @override
  Future<List<CategoryModel>> getCategories() async {
    final body = await _getJson('/api/v1/categories');
    final list = body['categories'] as List<dynamic>? ?? const <dynamic>[];
    return [
      for (final item in list) CategoryModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    final query = <String, String>{'limit': '$limit'};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (since != null) {
      query['since'] = _isoUtc(since);
    }
    final body = await _getJson('/api/v1/pictos', query: query);
    final list = body['pictos'] as List<dynamic>? ?? const <dynamic>[];
    return [
      for (final item in list) PictoModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    final body = await _getJson('/api/v1/pictos/$id');
    return PictoModel.fromJson(body);
  }

  // ---- Subida (REQ-BCK-02, RF-5.12 a RF-5.15) ----

  @override
  Future<PictoModel> postPicto(PictoModel picto, {required String imageBase64, required String imageMime}) async {
    final result = await _write(
      'POST',
      '/api/v1/pictos',
      body: <String, dynamic>{
        'id': picto.id,
        'label': picto.label,
        'categoryIds': picto.categoryIds,
        if (picto.labels.isNotEmpty) 'labels': picto.labels,
        'imageData': imageBase64,
        'imageMime': imageMime,
        'updatedAt': _isoUtc(picto.updatedAt),
        'childProfileId': picto.childProfileId,
      },
    );
    if (result == null) {
      throw DataSourceException('El backend rechazó el alta del picto "${picto.id}" (404)');
    }
    return PictoModel.fromJson(result);
  }

  @override
  Future<PictoModel> putPicto(PictoModel picto, {String? imageBase64, String? imageMime}) async {
    final result = await _write(
      'PUT',
      '/api/v1/pictos/${picto.id}',
      body: <String, dynamic>{
        'label': picto.label,
        'categoryIds': picto.categoryIds,
        if (picto.labels.isNotEmpty) 'labels': picto.labels,
        ?(imageBase64 != null ? 'imageData' : null): imageBase64,
        ?(imageMime != null ? 'imageMime' : null): imageMime,
        'updatedAt': _isoUtc(picto.updatedAt),
        'childProfileId': picto.childProfileId,
      },
    );
    if (result == null) {
      throw DataSourceException('El backend no tiene el picto "${picto.id}" (404)');
    }
    return PictoModel.fromJson(result);
  }

  @override
  Future<PictoModel> deletePicto(String id) async {
    final result = await _write('DELETE', '/api/v1/pictos/$id');
    if (result == null) {
      // 404: en el server ya no existe (nunca subió o fue purgado) — para la
      // cache del dispositivo es lo mismo que una tumba.
      return _syntheticTombstone(id);
    }
    return PictoModel.fromJson(result);
  }

  @override
  Future<CategoryModel> postCategory(CategoryModel category) async {
    final result = await _write(
      'POST',
      '/api/v1/categories',
      body: <String, dynamic>{
        'id': category.id,
        'name': category.name,
        'color': CategoryModel.formatColor(category.color),
        'icon': category.icon,
        if (category.names.isNotEmpty) 'names': category.names,
        'updatedAt': _isoUtc(DateTime.now().toUtc()),
      },
    );
    if (result == null) {
      throw DataSourceException('El backend rechazó el alta de la categoría "${category.id}" (404)');
    }
    return CategoryModel.fromJson(result);
  }

  @override
  Future<CategoryModel> putCategory(CategoryModel category) async {
    final result = await _write(
      'PUT',
      '/api/v1/categories/${category.id}',
      body: <String, dynamic>{
        'name': category.name,
        'color': CategoryModel.formatColor(category.color),
        if (category.names.isNotEmpty) 'names': category.names,
        'updatedAt': _isoUtc(DateTime.now().toUtc()),
      },
    );
    if (result == null) {
      throw DataSourceException('El backend no tiene la categoría "${category.id}" (404)');
    }
    return CategoryModel.fromJson(result);
  }

  @override
  Future<CategoryModel> deleteCategory(String id) async {
    final result = await _write('DELETE', '/api/v1/categories/$id');
    if (result == null) {
      return CategoryModel(id: id, name: '', color: 0xFF7C5CBF, icon: 'category', deletedAt: DateTime.now().toUtc());
    }
    return CategoryModel.fromJson(result);
  }

  // ---- HTTP helpers ----

  Future<Map<String, dynamic>> _getJson(String path, {Map<String, String>? query}) async {
    final response = await _execute('GET', path, query: query);
    if (response.statusCode != 200) {
      throw DataSourceException('El backend respondió ${response.statusCode} ($path)');
    }
    try {
      return _decode(response.body);
    } on FormatException catch (error) {
      throw DataSourceException('El backend devolvió JSON inválido ($path): ${error.message}');
    } on TypeError catch (error) {
      throw DataSourceException('El backend devolvió un formato inesperado ($path): $error');
    }
  }

  /// Escritura (POST/PUT/DELETE). Devuelve el cuerpo JSON de la respuesta:
  ///
  /// - 200/201: la versión creada o ganadora.
  /// - 409: la versión guardada en el server (conflicto — el repositorio
  ///   la adopta si es más nueva, RNF-5.10).
  /// - 404: `null` (el item ya no existe server-side; para el borrado
  ///   equivale a éxito).
  ///
  /// 400/403 y errores de conexión lanzan [DataSourceException] (la op
  /// queda en el outbox para reintentar).
  Future<Map<String, dynamic>?> _write(String method, String path, {Map<String, dynamic>? body}) async {
    final response = await _execute(method, path, body: body == null ? null : jsonEncode(body));
    switch (response.statusCode) {
      case 200:
      case 201:
      case 409:
        return _decode(response.body);
      case 404:
        return null;
      default:
        throw DataSourceException('El backend respondió ${response.statusCode} ($path)');
    }
  }

  Future<http.Response> _execute(String method, String path, {Map<String, String>? query, String? body}) async {
    final http.Response response;
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final request = http.Request(method, uri);
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = body;
      }
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout));
    } on TimeoutException {
      // RF-5.10: un timeout cuenta como backend no disponible.
      throw DataSourceException('El backend no respondió en ${timeout.inSeconds}s ($path)');
    } on Object catch (error) {
      throw DataSourceException('No se pudo conectar con el backend ($path): $error');
    }
    return response;
  }

  PictoModel _syntheticTombstone(String id) {
    final now = DateTime.now().toUtc();
    return PictoModel(
      id: id,
      label: '',
      categoryIds: const [],
      imageUrl: '',
      source: PictoSource.remote,
      createdAt: now,
      updatedAt: now,
      deletedAt: now,
    );
  }

  static Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('la respuesta no es un objeto JSON');
  }

  static String _isoUtc(DateTime date) => date.toUtc().toIso8601String();
}
