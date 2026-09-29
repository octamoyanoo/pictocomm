import 'package:flutter/material.dart' show Color;

/// Perfil de un niño usuario de la app.
///
/// Varios niños pueden compartir el mismo dispositivo, cada uno con su propio
/// orden de categorías y sus pictos favoritos. El perfil activo se guarda en
/// local y se manda al backend para filtrar tableros.
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.color,
    this.avatarPath,
    this.categoryOrder = const <String>[],
  });

  final String id;
  final String name;
  final Color color;

  /// Ruta de asset o de archivo local. `null` = se muestra un ícono con
  /// inicial.
  final String? avatarPath;

  /// Ids de categorías en el orden en que las ve este niño. Vacío = el orden
  /// por defecto de `Category.sortOrder`.
  final List<String> categoryOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfile &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.avatarPath == avatarPath;

  @override
  int get hashCode => Object.hash(id, name, color, avatarPath);

  @override
  String toString() => 'ChildProfile(id: $id, name: $name)';
}
