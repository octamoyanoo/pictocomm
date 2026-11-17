import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';

final class CustomCatalogDataSource {
  static const String _categoriesKey = 'pictocomm.custom_categories';
  static const String _pictosKey = 'pictocomm.custom_pictos';

  Future<List<Category>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeCategories(prefs.getString(_categoriesKey));
  }

  Future<List<Picto>> loadPictos() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodePictos(prefs.getString(_pictosKey));
  }

  /// RF3.9 con multi-pertenencia (REQ-CAT-02, RF-3.20): borra la categoría y
  /// trata sus pictos en dos grupos:
  ///
  /// - pierden esa membresía (los que también viven en otras categorías) y
  ///   **sobreviven** aunque sea del chico activo;
  /// - los que quedan **sin ninguna categoría** se eliminan en cascada solo
  ///   si son del chico activo (o sin dueño); los de otros chicos
  ///   sobreviven huérfanos (lista vacía).
  ///
  /// Ningún picto sobreviviente conserva el id de la categoría borrada.
  Future<void> deleteCategory(String categoryId, {String? childProfileId}) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = _decodeCategories(prefs.getString(_categoriesKey));
    final remainingCategories = categories.where((category) => category.id != categoryId).toList();
    final remainingPictos = <Picto>[];
    for (final picto in _decodePictos(prefs.getString(_pictosKey))) {
      if (!picto.categoryIds.contains(categoryId)) {
        remainingPictos.add(picto);
        continue;
      }
      final reduced = [
        for (final id in picto.categoryIds)
          if (id != categoryId) id,
      ];
      final belongsToActiveChild = childProfileId == null || picto.childProfileId == childProfileId;
      if (reduced.isEmpty && belongsToActiveChild) {
        continue; // Cascada: se elimina (RF-3.20).
      }
      remainingPictos.add(Picto(
        id: picto.id,
        label: picto.label,
        categoryIds: reduced,
        source: picto.source,
        imageUrl: picto.imageUrl,
        childProfileId: picto.childProfileId,
        createdAt: picto.createdAt,
        updatedAt: picto.updatedAt,
      ));
    }
    await prefs.setString(_categoriesKey, jsonEncode([
      for (final category in remainingCategories) CategoryModel.fromEntity(category).toJson(),
    ]));
    await prefs.setString(_pictosKey, jsonEncode([
      for (final picto in remainingPictos) PictoModel.fromEntity(picto).toJson(),
    ]));
  }

  /// RF2.7 (cascada del borrado de perfil): elimina todos los pictos
  /// personalizados de ese chico, sin importar la categoría.
  Future<void> deletePictosForChild(String childProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final pictos = _decodePictos(prefs.getString(_pictosKey));
    final remaining = pictos.where((picto) => picto.childProfileId != childProfileId).toList();
    await prefs.setString(_pictosKey, jsonEncode([for (final picto in remaining) PictoModel.fromEntity(picto).toJson()]));
  }

  /// RF3.8: borra un picto por id. Idempotente.
  Future<void> deletePicto(String pictoId) async {
    final prefs = await SharedPreferences.getInstance();
    final pictos = _decodePictos(prefs.getString(_pictosKey));
    final remaining = pictos.where((picto) => picto.id != pictoId).toList();
    await prefs.setString(_pictosKey, jsonEncode([for (final picto in remaining) PictoModel.fromEntity(picto).toJson()]));
  }

  /// Guarda la categoría con **upsert por id** (REQ-CAT-02): si ya existe se
  /// reemplaza (edición RF-3.17), si no se agrega.
  Future<Category> saveCategory(Category category) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decodeCategories(prefs.getString(_categoriesKey));
    final persisted = Category(
      id: category.id,
      name: category.name,
      color: category.color,
      icon: category.icon,
      custom: category.custom,
    );
    final models = _upsertById<CategoryModel>(
      [for (final existing in stored) CategoryModel.fromEntity(existing)],
      CategoryModel.fromEntity(persisted),
    );
    await prefs.setString(_categoriesKey, jsonEncode([for (final model in models) model.toJson()]));
    return persisted;
  }

  /// Guarda el picto con **upsert por id** (REQ-CAT-02): si ya existe se
  /// reemplaza (edición RF-3.16), si no se agrega.
  Future<Picto> savePicto(Picto picto) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decodePictos(prefs.getString(_pictosKey));
    final persisted = Picto(
      id: picto.id,
      label: picto.label,
      categoryIds: [...picto.categoryIds],
      source: picto.source,
      imageUrl: picto.imageUrl,
      childProfileId: picto.childProfileId,
      createdAt: picto.createdAt,
      updatedAt: picto.updatedAt,
    );
    final models = _upsertById<PictoModel>(
      [for (final existing in stored) PictoModel.fromEntity(existing)],
      PictoModel.fromEntity(persisted),
    );
    await prefs.setString(_pictosKey, jsonEncode([for (final model in models) model.toJson()]));
    return persisted;
  }

  static List<T> _upsertById<T extends Object>(List<T> stored, T incoming) {
    String idOf(T item) => switch (item) {
      CategoryModel(:final id) => id,
      PictoModel(:final id) => id,
      _ => throw ArgumentError('tipo sin id: ${item.runtimeType}'),
    };
    final byId = <String, T>{for (final item in stored) idOf(item): item};
    byId[idOf(incoming)] = incoming;
    return byId.values.toList();
  }

  List<Category> _decodeCategories(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <Category>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list) (CategoryModel.fromJson(item as Map<String, dynamic>)).toEntity(),
      ];
    } on FormatException {
      return const <Category>[];
    }
  }

  List<Picto> _decodePictos(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <Picto>[];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list) (PictoModel.fromJson(item as Map<String, dynamic>)).toEntity(),
      ];
    } on FormatException {
      return const <Picto>[];
    }
  }
}
