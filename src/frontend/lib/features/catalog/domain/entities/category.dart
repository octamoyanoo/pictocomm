import 'dart:ui' show Color;

final class Category {
  const Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  final String id;
  final String name;
  final Color? color;
  final String? icon;
}
