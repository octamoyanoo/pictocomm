import 'dart:ui' show Color;

import '../../domain/entities/category.dart';

final class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final int color;
  final String icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: _parseColor(json['color'] as String),
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'color': formatColor(color), 'icon': icon};
  }

  Category toEntity() {
    return Category(id: id, name: name, color: Color(color), icon: icon);
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
