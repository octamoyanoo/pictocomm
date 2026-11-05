import 'dart:ui' show Color;

import '../../domain/entities/category.dart';

final class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.custom = false,
  });

  final String id;
  final String name;
  final int color;
  final String icon;

  /// RF3.9: las categorías persistidas (creadas por el adulto) son custom.
  final bool custom;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: _parseColor(json['color'] as String),
      icon: json['icon'] as String,
      custom: json['custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'color': formatColor(color), 'icon': icon, 'custom': custom};
  }

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      color: entity.color?.toARGB32() ?? 0xFF7C5CBF,
      icon: entity.icon ?? 'category',
      custom: entity.custom,
    );
  }

  Category toEntity() {
    return Category(id: id, name: name, color: Color(color), icon: icon, custom: custom);
  }

  static int _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
    return int.parse(withAlpha, radix: 16);
  }

  static String formatColor(int argb) {
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
