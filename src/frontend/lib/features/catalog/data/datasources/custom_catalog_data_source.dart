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
