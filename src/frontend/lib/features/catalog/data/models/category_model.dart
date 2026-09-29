import 'dart:convert';

/// Modelo inmutable para serializar [Category] a JSON (y deserializar).
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.assetFolder,
    required this.color,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String assetFolder;
  final int color;
  final int sortOrder;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        assetFolder: json['assetFolder'] as String,
        color: json['color'] as int,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'assetFolder': assetFolder,
        'color': color,
        'sortOrder': sortOrder,
      };

  static List<CategoryModel> fromJsonList(String source) {
    final List<dynamic> list = json.decode(source) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }
}
