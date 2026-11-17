import 'dart:ui' show Color;

import '../../domain/entities/category.dart';

final class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.custom = false,
    this.deletedAt,
    this.names = const {},
  });

  final String id;
  final String name;
  final int color;
  final String icon;

  /// REQ-IDI-01 (RF-4.9): traducciones del nombre por idioma. Opcional;
  /// `toJson` la omite si está vacía (el JSON de una categoría sin
  /// traducir queda igual al de siempre).
  final Map<String, String> names;

  /// RF3.9: las categorías persistidas (creadas por el adulto) son custom.
  final bool custom;

  /// REQ-BCK-02 (RF-5.15): tumba del borrado lógico remoto, para purgar el
  /// cache de dispositivos que ya la tenían.
  final DateTime? deletedAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: _parseColor(json['color'] as String),
      icon: json['icon'] as String,
      custom: json['custom'] as bool? ?? false,
      deletedAt: _parseDate(json['deletedAt']),
      names: _parseNames(json['names']),
    );
  }

  /// REQ-IDI-01 (RF-4.10): tolerante — vacío o ausente = sin traducciones.
  static Map<String, String> _parseNames(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return {
        for (final entry in value.entries)
          if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
      };
    }
    return const {};
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': formatColor(color),
      'icon': icon,
      'custom': custom,
      if (names.isNotEmpty) 'names': names,
      if (deletedAt != null) 'deletedAt': deletedAt!.toUtc().toIso8601String(),
    };
  }

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      color: entity.color?.toARGB32() ?? 0xFF7C5CBF,
      icon: entity.icon ?? 'category',
      custom: entity.custom,
      names: Map.of(entity.names),
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      color: Color(color),
      icon: icon,
      custom: custom,
      names: Map.of(names),
    );
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
