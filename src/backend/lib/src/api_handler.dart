import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'catalog_store.dart';

/// Rutas de la API (RF-5.1 + REQ-BCK-02 RF-5.12 a RF-5.15):
///
/// - `GET  /health`
/// - `GET  /api/v1/categories`            (incluye tumbas con `deletedAt`)
/// - `POST /api/v1/categories`
/// - `PUT  /api/v1/categories/{id}`
/// - `DELETE /api/v1/categories/{id}`
/// - `GET  /api/v1/pictos?categoryId=&since=&limit=`
/// - `POST /api/v1/pictos`                (alta con imagen base64)
/// - `PUT  /api/v1/pictos/{id}`
/// - `DELETE /api/v1/pictos/{id}`         (borrado lógico)
/// - `GET  /api/v1/pictos/{id}`
/// - `GET /images/<archivo>` y `/images/uploads/<archivo>` (estáticos, RF-5.4)
///
/// Limites del filtro `limit`: default 100, rango válido 1..500 (RF-5.2).
const int defaultPictosLimit = 100;
const int maxPictosLimit = 500;

/// Mimes de imagen aceptados para las subidas (RNF-5.9).
const Set<String> _allowedImageMimes = {'image/png', 'image/jpeg', 'image/webp'};

Router buildApiRouter({required CatalogStore store, required String imagesDirectory}) {
  final router = Router();
  final uploadsDirectory = '$imagesDirectory${Platform.pathSeparator}uploads';

  router.get('/health', (Request request) async {
    return _json(200, <String, dynamic>{'status': 'ok'});
  });

  // ---- Categorías ----

  router.get('/api/v1/categories', (Request request) async {
    // REQ-BCK-02 (RF-5.15): se incluyen las tumbas con `deletedAt` para que
    // los dispositivos purguen su cache (son pocas, siempre viajan).
    final all = [...store.categories, ...store.deletedCategories];
    return _json(200, <String, dynamic>{
      'categories': [for (final category in all) _categoryJson(category)],
    });
  });

  router.post('/api/v1/categories', (Request request) async {
    final body = await _readJsonBody(request);
    if (body == null) {
      return _json(400, <String, dynamic>{'error': 'el cuerpo debe ser JSON'});
    }
    final validation = _validateCategoryBody(body);
    if (validation != null) {
      return _json(400, <String, dynamic>{'error': validation});
    }
    final updatedAt = _parseRequiredDate(body['updatedAt']);
    if (updatedAt == null) {
      return _json(400, <String, dynamic>{'error': 'updatedAt es requerido (ISO-8601)'});
    }
    final id = (body['id'] as String?)?.trim();
    final name = (body['name'] as String).trim();
    final resolvedId = (id == null || id.isEmpty) ? _slugify(name) : id;
    final existing = store.categoryById(resolvedId);
    if (existing != null) {
      // CA-5.x: id ya existe → 409 con la versión guardada.
      return _json(409, _categoryJson(existing));
    }
    final category = SeedCategory(
      id: resolvedId,
      name: name,
      color: body['color'] as String,
      icon: (body['icon'] as String?) ?? 'category',
      updatedAt: updatedAt,
    );
    if (!store.upsertCategory(category)) {
      return _json(403, <String, dynamic>{'error': 'la categoría "$resolvedId" pertenece al seed y no se puede editar'});
    }
    return _json(201, _categoryJson(category));
  });

  router.put('/api/v1/categories/<id>', (Request request, String id) async {
    final existing = store.categoryById(id);
    if (existing == null) {
      return _json(404, <String, dynamic>{'error': 'categoría "$id" no encontrada'});
    }
    if (store.isSeedCategory(id)) {
      return _json(403, <String, dynamic>{'error': 'la categoría "$id" pertenece al seed y no se puede editar'});
    }
    if (existing.deletedAt != null) {
      // RF-5.14: tumba → la app adopta el borrado.
      return _json(409, _categoryJson(existing));
    }
    final body = await _readJsonBody(request);
    if (body == null) {
      return _json(400, <String, dynamic>{'error': 'el cuerpo debe ser JSON'});
    }
    final updatedAt = _parseRequiredDate(body['updatedAt']);
    if (updatedAt == null) {
      return _json(400, <String, dynamic>{'error': 'updatedAt es requerido (ISO-8601)'});
    }
    if (existing.updatedAt != null && !updatedAt.isAfter(existing.updatedAt!)) {
      // RNF-5.10: last-write-wins — la versión guardada es más nueva.
      return _json(200, _categoryJson(existing));
    }
    final name = (body['name'] as String?)?.trim();
    if (name != null && name.isEmpty) {
      return _json(400, <String, dynamic>{'error': 'el nombre no puede quedar vacío'});
    }
    final updated = SeedCategory(
      id: id,
      name: name ?? existing.name,
      color: (body['color'] as String?) ?? existing.color,
      icon: (body['icon'] as String?) ?? existing.icon,
      updatedAt: updatedAt,
    );
    store.upsertCategory(updated);
    return _json(200, _categoryJson(updated));
  });

  router.delete('/api/v1/categories/<id>', (Request request, String id) async {
    final existing = store.categoryById(id);
    if (existing == null) {
      return _json(404, <String, dynamic>{'error': 'categoría "$id" no encontrada'});
    }
    if (store.isSeedCategory(id)) {
      return _json(403, <String, dynamic>{'error': 'la categoría "$id" pertenece al seed y no se puede borrar'});
    }
    // RNF-5.14: borrado SIEMPRE lógico.
    final tombstone = existing.withDeletedAt(
      _tombstoneDate(existing.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), existing.deletedAt),
    );
    store.upsertCategory(tombstone);
    return _json(200, _categoryJson(tombstone));
  });

  // ---- Pictos ----

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

  router.post('/api/v1/pictos', (Request request) async {
    final body = await _readJsonBody(request);
    if (body == null) {
      return _json(400, <String, dynamic>{'error': 'el cuerpo debe ser JSON'});
    }
    final validation = _validatePictoBody(body);
    if (validation != null) {
      return _json(400, <String, dynamic>{'error': validation});
    }
    final updatedAt = _parseRequiredDate(body['updatedAt']);
    if (updatedAt == null) {
      return _json(400, <String, dynamic>{'error': 'updatedAt es requerido (ISO-8601)'});
    }
    final id = (body['id'] as String?)?.trim();
    final resolvedId = (id == null || id.isEmpty) ? 'custom-${DateTime.now().microsecondsSinceEpoch}' : id;
    final existing = store.pictoById(resolvedId);
    if (existing != null) {
      // RF-5.12: id ya existe → 409 con la versión guardada (el cliente
      // decide: adopta o vuelve a mandar por PUT con updatedAt mayor).
      return _json(409, _pictoJson(existing, request));
    }
    final image = await _storeUploadedImage(
      directory: uploadsDirectory,
      id: resolvedId,
      imageData: body['imageData'] as String,
      mime: body['imageMime'] as String?,
    );
    if (image == null) {
      return _json(400, <String, dynamic>{'error': 'imageData no es base64 válido'});
    }
    final picto = SeedPicto(
      id: resolvedId,
      label: (body['label'] as String).trim(),
      categoryIds: [for (final categoryId in body['categoryIds'] as List<dynamic>) categoryId as String],
      image: image,
      childProfileId: body['childProfileId'] as String?,
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
    store.upsertPicto(picto);
    return _json(201, _pictoJson(picto, request));
  });

  router.put('/api/v1/pictos/<id>', (Request request, String id) async {
    final existing = store.pictoById(id);
    if (existing == null) {
      return _json(404, <String, dynamic>{'error': 'picto "$id" no encontrado'});
    }
    if (store.isSeedPicto(id)) {
      return _json(403, <String, dynamic>{'error': 'el picto "$id" pertenece al seed y no se puede editar'});
    }
    if (existing.isDeleted) {
      // RF-5.14: tumba → la app adopta el borrado.
      return _json(409, _pictoJson(existing, request));
    }
    final body = await _readJsonBody(request);
    if (body == null) {
      return _json(400, <String, dynamic>{'error': 'el cuerpo debe ser JSON'});
    }
    final updatedAt = _parseRequiredDate(body['updatedAt']);
    if (updatedAt == null) {
      return _json(400, <String, dynamic>{'error': 'updatedAt es requerido (ISO-8601)'});
    }
    if (!updatedAt.isAfter(existing.updatedAt)) {
      // RNF-5.10: last-write-wins — la versión guardada es más nueva y el
      // cliente la adopta (la respuesta SIEMPRE trae la ganadora).
      return _json(200, _pictoJson(existing, request));
    }
    final label = (body['label'] as String?)?.trim();
    if (label != null && label.isEmpty) {
      return _json(400, <String, dynamic>{'error': 'el nombre no puede quedar vacío'});
    }
    final categoryIds = body['categoryIds'] as List<dynamic>?;
    if (categoryIds != null && categoryIds.isEmpty) {
      return _json(400, <String, dynamic>{'error': 'categoryIds no puede quedar vacío'});
    }
    var image = existing.image;
    final imageData = body['imageData'] as String?;
    if (imageData != null) {
      final stored = await _storeUploadedImage(
        directory: uploadsDirectory,
        id: id,
        imageData: imageData,
        mime: body['imageMime'] as String?,
      );
      if (stored == null) {
        return _json(400, <String, dynamic>{'error': 'imageData no es base64 válido'});
      }
      image = stored;
    }
    final updated = existing.copyWith(
      label: label,
      categoryIds: categoryIds == null ? null : [for (final categoryId in categoryIds) categoryId as String],
      image: image,
      updatedAt: updatedAt,
    );
    store.upsertPicto(updated);
    return _json(200, _pictoJson(updated, request));
  });

  router.delete('/api/v1/pictos/<id>', (Request request, String id) async {
    final existing = store.pictoById(id);
    if (existing == null) {
      return _json(404, <String, dynamic>{'error': 'picto "$id" no encontrado'});
    }
    if (store.isSeedPicto(id)) {
      return _json(403, <String, dynamic>{'error': 'el picto "$id" pertenece al seed y no se puede borrar'});
    }
    // RNF-5.14: borrado SIEMPRE lógico (el archivo de imagen puede quedarse).
    final tombstone = existing.copyWith(
      deletedAt: _tombstoneDate(existing.updatedAt, existing.deletedAt),
    );
    store.upsertPicto(tombstone);
    return _json(200, _pictoJson(tombstone, request));
  });

  router.get('/api/v1/pictos/<id>', (Request request, String id) async {
    final picto = store.pictoById(id);
    if (picto == null || picto.isDeleted) {
      // CA-5.4: inexistente → 404 con JSON de error (RNF-5.4).
      return _json(404, <String, dynamic>{'error': 'picto "$id" no encontrado'});
    }
    return _json(200, _pictoJson(picto, request));
  });

  // ---- Imágenes estáticas (RF-5.4 + uploads RNF-5.9) ----

  router.get('/images/uploads/<file|[^/]*>', (Request request, String file) {
    return _imageResponse('$uploadsDirectory${Platform.pathSeparator}$file', file);
  });

  router.get('/images/<file|[^/]*>', (Request request, String file) {
    return _imageResponse('$imagesDirectory${Platform.pathSeparator}$file', file);
  });

  return router;
}

// ---- Helpers ----

/// Serializa una categoría en el formato de `CategoryModel` del frontend.
/// `custom: false`: en otros dispositivos la categoría subida se comporta
/// como remota (no editable/borrable ahí; la autoridad es el dispositivo
/// dueño, RF-5.15).
Map<String, dynamic> _categoryJson(SeedCategory category) {
  return <String, dynamic>{
    'id': category.id,
    'name': category.name,
    'color': category.color,
    'icon': category.icon,
    'custom': false,
    'deletedAt': category.deletedAt?.toUtc().toIso8601String(),
  };
}

/// Serializa un picto en el formato de `PictoModel` del frontend: el `source`
/// siempre es `remote` y `imageUrl` es absoluta (construida del request), así
/// `Image.network` la resuelve igual desde localhost que desde un emulador.
/// REQ-CAT-02 (RNF-3.9): `categoryIds` como lista. REQ-BCK-02 (RF-5.12):
/// los subidos por dispositivos también salen como `remote` (id `custom-*`
/// intacto, RNF-5.15).
Map<String, dynamic> _pictoJson(SeedPicto picto, Request request) {
  final base = '${request.requestedUri.scheme}://${request.requestedUri.authority}';
  return <String, dynamic>{
    'id': picto.id,
    'label': picto.label,
    'categoryIds': picto.categoryIds,
    'imageUrl': '$base/images/${picto.image}',
    'source': 'remote',
    'createdAt': picto.createdAt.toUtc().toIso8601String(),
    'updatedAt': picto.updatedAt.toUtc().toIso8601String(),
    'childProfileId': picto.childProfileId,
    'deletedAt': picto.deletedAt?.toUtc().toIso8601String(),
  };
}

Response _json(int statusCode, Map<String, dynamic> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
  );
}

Future<Map<String, dynamic>?> _readJsonBody(Request request) async {
  try {
    final body = await request.readAsString();
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  } on FormatException {
    return null;
  }
}

/// Valida el cuerpo de alta de picto (RF-5.12): label, categoryIds y
/// imageData (base64 + mime permitido). Devuelve el mensaje de error o null.
String? _validatePictoBody(Map<String, dynamic> body) {
  final label = body['label'];
  if (label is! String || label.trim().isEmpty) {
    return 'label es requerido';
  }
  final categoryIds = body['categoryIds'];
  if (categoryIds is! List<dynamic> || categoryIds.isEmpty || categoryIds.any((item) => item is! String)) {
    return 'categoryIds debe ser una lista no vacía de ids';
  }
  final imageData = body['imageData'];
  if (imageData is! String || imageData.isEmpty) {
    return 'imageData es requerido (base64 de la imagen)';
  }
  final mime = body['imageMime'] as String?;
  if (mime != null && !_allowedImageMimes.contains(mime.split(';').first.trim())) {
    return 'imageMime debe ser image/png, image/jpeg o image/webp';
  }
  return null;
}

/// Valida el cuerpo de alta de categoría (RF-5.15): name y color hex.
String? _validateCategoryBody(Map<String, dynamic> body) {
  final name = body['name'];
  if (name is! String || name.trim().isEmpty) {
    return 'name es requerido';
  }
  final color = body['color'];
  if (color is! String || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
    return 'color debe ser hex #RRGGBB';
  }
  return null;
}

/// Decodifica el base64 y guarda el archivo en `uploads/`. Devuelve el valor
/// del campo `image` (relativo a `/images/`) o null si el base64 es inválido
/// (RNF-5.9).
Future<String?> _storeUploadedImage({
  required String directory,
  required String id,
  required String imageData,
  String? mime,
}) async {
  try {
    final bytes = base64Decode(imageData);
    if (bytes.isEmpty) {
      return null;
    }
    final extension = switch ((mime ?? 'image/png').split(';').first.trim()) {
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      _ => 'png',
    };
    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final directory_ = Directory(directory);
    if (!directory_.existsSync()) {
      directory_.createSync(recursive: true);
    }
    final fileName = '$safeId.$extension';
    await File('$directory${Platform.pathSeparator}$fileName').writeAsBytes(bytes);
    return 'uploads/$fileName';
  } on FormatException {
    return null;
  }
}

/// Fecha de tumba: siempre mayor que el `updatedAt` guardado (garantiza que
/// el sync incremental la propague aunque el server y el cliente difieran).
DateTime _tombstoneDate(DateTime updatedAt, DateTime? existingTombstone) {
  final now = DateTime.now().toUtc();
  final candidate = updatedAt.isAfter(now) ? updatedAt.add(const Duration(milliseconds: 1)) : now;
  final previous = existingTombstone;
  if (previous != null && previous.isAfter(candidate)) {
    return previous;
  }
  return candidate;
}

DateTime? _parseRequiredDate(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
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

Response _imageResponse(String path, String file) {
  final image = File(path);
  if (!image.existsSync()) {
    return _json(404, <String, dynamic>{'error': 'imagen "$file" no encontrada'});
  }
  final bytes = image.readAsBytesSync();
  return Response.ok(
    bytes,
    headers: <String, String>{'content-type': _mimeTypeFor(file), 'cache-control': 'public, max-age=86400'},
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
