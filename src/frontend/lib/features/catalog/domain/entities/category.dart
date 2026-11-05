import 'dart:ui' show Color;

final class Category {
  const Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.custom = false,
  });

  final String id;
  final String name;
  final Color? color;
  final String? icon;

  /// `true` si la categoría fue creada por el adulto (RF3.9): solo las
  /// categorías personalizadas se pueden borrar.
  final bool custom;
}
