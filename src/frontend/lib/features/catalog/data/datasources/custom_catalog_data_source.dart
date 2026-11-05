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

  /// RF3.9: borra la categoría y, en cascada, sus pictos. Con
  /// [childProfileId] de la sesión activa, la cascada solo elimina los pictos
  /// DE ESE chico (los de otros chicos y los custom sin dueño permanecen).
  Future<void> deleteCategory(String categoryId, {String? childProfileId}) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = _decodeCategories(prefs.getString(_categoriesKey));
    final remainingCategories = categories.where((category) => category.id != categoryId).toList();
    final pictos = _decodePictos(prefs.getString(_pictosKey));
    // Sobrevive un picto si no está en la categoría borrada, o si está pero
    // NO es del chico activo: con dueño ajeno (RF3.6) o sin dueño (RF3.7).
    // Sin childProfileId (gestión sin sesión), la cascada es de toda la
    // categoría.
    final remainingPictos = pictos.where((picto) {
      if (picto.categoryId != categoryId) {
        return true;
      }
      final belongsToActiveChild = childProfileId == null || picto.childProfileId == childProfileId;
      return !belongsToActiveChild;
    }).toList();
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
    await prefs.setString(_pictosKey, jsonEncode([
      for (final picto in remaining) PictoModel.fromEntity(picto).toJson(),
    ]));
  }

  /// RF3.8: borra un picto por id. Idempotente.
  Future<void> deletePicto(String pictoId) async {
    final prefs = await SharedPreferences.getInstance();
    final pictos = _decodePictos(prefs.getString(_pictosKey));
    final remaining = pictos.where((picto) => picto.id != pictoId).toList();
    await prefs.setString(_pictosKey, jsonEncode([
      for (final picto in remaining) PictoModel.fromEntity(picto).toJson(),
    ]));
  }

  Future<Category> saveCategory(Category category) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decodeCategories(prefs.getString(_categoriesKey));
    final persisted = Category(
      id: category.id,
      name: category.name,
      color: category.color,
      icon: category.icon,
    );
    final models = [
      for (final existing in stored) CategoryModel.fromEntity(existing),
      CategoryModel.fromEntity(persisted),
    ];
    final encoded = jsonEncode([for (final model in models) model.toJson()]);
    await prefs.setString(_categoriesKey, encoded);
    return persisted;
  }

  Future<Picto> savePicto(Picto picto) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decodePictos(prefs.getString(_pictosKey));
    final persisted = Picto(
      id: picto.id,
      label: picto.label,
      categoryId: picto.categoryId,
      source: picto.source,
      imageUrl: picto.imageUrl,
      childProfileId: picto.childProfileId,
      createdAt: picto.createdAt,
      updatedAt: picto.updatedAt,
    );
    final models = [
      for (final existing in stored) PictoModel.fromEntity(existing),
      PictoModel.fromEntity(persisted),
    ];
    final encoded = jsonEncode([for (final model in models) model.toJson()]);
    await prefs.setString(_pictosKey, encoded);
    return persisted;
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
