import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';
import 'remote_catalog_data_source.dart';

/// Implementación real de [RemoteCatalogDataSource] contra el backend
/// de PictoComm (REQ-BCK-01, RF-5.1).
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

  Future<Map<String, dynamic>> _getJson(String path, {Map<String, String>? query}) async {
    final http.Response response;
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      // RF-5.10: un timeout cuenta como backend no disponible.
      throw DataSourceException('El backend no respondió en ${timeout.inSeconds}s ($path)');
    } on Object catch (error) {
      throw DataSourceException('No se pudo conectar con el backend ($path): $error');
    }
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

  static Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('la respuesta no es un objeto JSON');
  }

  static String _isoUtc(DateTime date) => date.toUtc().toIso8601String();
}
