import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/picto_model.dart';

/// Cache local del catálogo remoto (REQ-BCK-01, RF-5.6).
///
/// Usa claves propias de SharedPreferences, separadas de las custom: el
/// catálogo remoto no se borra desde la app (RF-5.9) y no comparte storage
/// con lo que crea el adulto. Local-first: las lecturas del repositorio
/// salen de acá, nunca de la red.
final class RemoteCatalogCacheDataSource {
  const RemoteCatalogCacheDataSource();

  static const String _categoriesKey = 'pictocomm.remote_categories';
  static const String _pictosKey = 'pictocomm.remote_pictos';
  static const String _lastSyncKey = 'pictocomm.remote_last_sync';

  Future<List<CategoryModel>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_categoriesKey), CategoryModel.fromJson);
  }

  Future<List<PictoModel>> loadPictos() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_pictosKey), PictoModel.fromJson);
  }

  /// Última fecha sincronizada (RF-5.7): `null` si nunca se sincronizó.
  Future<DateTime?> lastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  /// Guarda el estado sincronizado con upsert por id: si un item ya estaba
  /// cacheado se reemplaza, si no se agrega. [syncedAt] queda en `null`
  /// solo si nunca hubo sync previo ni items en esta corrida.
  Future<void> save({
    required List<CategoryModel> categories,
    required List<PictoModel> pictos,
    DateTime? syncedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (categories.isNotEmpty) {
      final merged = _upsert(await loadCategories(), categories);
      await prefs.setString(_categoriesKey, jsonEncode([for (final c in merged) c.toJson()]));
    }
    if (pictos.isNotEmpty) {
      final merged = _upsert(await loadPictos(), pictos);
      await prefs.setString(_pictosKey, jsonEncode([for (final p in merged) p.toJson()]));
    }
    final previous = await lastSyncAt();
    final effective = syncedAt ?? previous;
    if (effective != null) {
      await prefs.setString(_lastSyncKey, effective.toUtc().toIso8601String());
    }
  }

  static List<T> _upsert<T extends Object>(List<T> stored, List<T> incoming) {
    final byId = <String, T>{
      // `id` es la clave de dedup en ambos models (RF-5.8).
      for (final item in stored) _idOf(item): item,
    };
    for (final item in incoming) {
      byId[_idOf(item)] = item;
    }
    return byId.values.toList();
  }

  static String _idOf(Object item) => switch (item) {
    CategoryModel(:final id) => id,
    PictoModel(:final id) => id,
    _ => throw ArgumentError('tipo sin id: ${item.runtimeType}'),
  };

  static List<T> _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final item in list) fromJson(item as Map<String, dynamic>)];
    } on FormatException {
      // Cache corrupta: se pierde el cache remoto pero la app sigue con lo local.
      return <T>[];
    }
  }
}
