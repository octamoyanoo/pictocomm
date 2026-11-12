import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'catalog_store.dart';

/// Rutas de la API (RF-5.1):
///
/// - `GET /health`
/// - `GET /api/v1/categories`
/// - `GET /api/v1/pictos?categoryId=&since=&limit=`
/// - `GET /api/v1/pictos/{id}`
/// - `GET /images/<archivo>` (imágenes estáticas del catálogo remoto, RF-5.4)
///
/// Limites del filtro `limit`: default 100, rango válido 1..500 (RF-5.2).
const int defaultPictosLimit = 100;
const int maxPictosLimit = 500;

Router buildApiRouter({required CatalogStore store, required String imagesDirectory}) {
  final router = Router();

  router.get('/health', (Request request) async {
    return _json(200, <String, dynamic>{'status': 'ok'});
  });

  router.get('/api/v1/categories', (Request request) async {
    return _json(200, <String, dynamic>{
      'categories': [
        for (final category in store.categories) <String, dynamic>{
          'id': category.id,
          'name': category.name,
          'color': category.color,
          'icon': category.icon,
          'custom': false,
        },
      ],
    });
  });

  router.get('/api/v1/pictos', (Request request) async {
    final query = request.url.queryParameters;
    final DateTime? since = switch (query['since']) {
      null => null,
      final value => DateTime.tryParse(value),
    };
    if (query['since'] != null && since == null) {
      // CA-5.3: `since` no-ISO → 400.
      return _json(400, <String, dynamic>{'error': 'since no es una fecha ISO-8601 válida'});
    }
    final int? limit = switch (query['limit']) {
      null => null,
      final value => int.tryParse(value),
    };
    if (query['limit'] != null && (limit == null || limit < 1 || limit > maxPictosLimit)) {
      // CA-5.3: `limit` fuera de rango → 400.
      return _json(400, <String, dynamic>{'error': 'limit debe ser un entero entre 1 y $maxPictosLimit'});
    }
    final effectiveLimit = limit ?? defaultPictosLimit;
    return _json(200, <String, dynamic>{
      'pictos': [
        for (final picto in store.queryPictos(
          categoryId: query['categoryId'],
          since: since,
          limit: effectiveLimit,
        ))
          _pictoJson(picto, request),
      ],
    });
  });

  router.get('/api/v1/pictos/<id>', (Request request, String id) async {
    final picto = store.pictoById(id);
    if (picto == null) {
      // CA-5.4: inexistente → 404 con JSON de error (RNF-5.4).
      return _json(404, <String, dynamic>{'error': 'picto "$id" no encontrado'});
    }
    return _json(200, _pictoJson(picto, request));
  });

  router.get('/images/<file|[^/]*>', (Request request, String file) async {
    final image = File('$imagesDirectory${Platform.pathSeparator}$file');
    if (!image.existsSync()) {
      return _json(404, <String, dynamic>{'error': 'imagen "$file" no encontrada'});
    }
    final bytes = await image.readAsBytes();
    return Response.ok(
      bytes,
      headers: <String, String>{'content-type': _mimeTypeFor(file), 'cache-control': 'public, max-age=86400'},
    );
  });

  return router;
}

/// Serializa un picto en el formato de `PictoModel` del frontend: el `source`
/// siempre es `remote` y `imageUrl` es absoluta (construida del request), así
/// `Image.network` la resuelve igual desde localhost que desde un emulador.
Map<String, dynamic> _pictoJson(SeedPicto picto, Request request) {
  final base = '${request.requestedUri.scheme}://${request.requestedUri.authority}';
  return <String, dynamic>{
    'id': picto.id,
    'label': picto.label,
    'categoryId': picto.categoryId,
    'imageUrl': '$base/images/${picto.image}',
    'source': 'remote',
    'createdAt': picto.createdAt.toUtc().toIso8601String(),
    'updatedAt': picto.updatedAt.toUtc().toIso8601String(),
    'childProfileId': picto.childProfileId,
  };
}

Response _json(int statusCode, Map<String, dynamic> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
  );
}

String _mimeTypeFor(String file) {
  final extension = file.split('.').last.toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'svg' => 'image/svg+xml',
    _ => 'application/octet-stream',
  };
}
