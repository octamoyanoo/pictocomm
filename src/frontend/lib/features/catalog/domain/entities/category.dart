import 'dart:ui' show Color;

final class Category {
  const Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.custom = false,
    this.names = const {},
  });

  final String id;

  /// Nombre base (español): fallback y clave de los íconos por nombre.
  final String name;

  /// REQ-IDI-01 (RF-4.9): traducciones del nombre por idioma. Opcional:
  /// las categorías custom vienen vacías y caen al nombre base.
  final Map<String, String> names;
  final Color? color;
  final String? icon;

  /// `true` si la categoría fue creada por el adulto (RF3.9): solo las
  /// categorías personalizadas se pueden borrar.
  final bool custom;

  /// REQ-IDI-01 (RF-4.9/RF-4.10): nombre para el idioma activo con la
  /// base en español como fallback.
  String nameFor(String languageCode) => names[languageCode] ?? name;

  /// Búsqueda de categorías: encuentra por el nombre base o por cualquier
  /// traducción (RF-4.9: buscar "Food" en la home en español también matchea).
  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return name.toLowerCase().contains(normalized) ||
        names.values.any((name) => name.toLowerCase().contains(normalized));
  }
}
