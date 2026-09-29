import 'dart:ui' show Color;

/// Grupo de pictos al que el niño navega (Comida, Lugares, Emociones).
///
/// Entidad de dominio pura: no sabe nada de assets, desqflite ni de HTTP. La
/// serialización vive en `data/models/category_model.dart`.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.assetFolder,
    required this.color,
    this.sortOrder = 0,
  });

  /// Identificador estable. Es la clave foránea de [Picto.categoryId].
  final String id;

  /// Nombre visible, ya en el idioma del niño.
  final String name;

  /// Carpeta dentro de `assets/images/` donde viven los pictos empaquetados.
  final String assetFolder;

  /// Color de acento de la categoría.
  final Color color;

  /// Posición en el grid. Menor = primero.
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.name == name &&
          other.assetFolder == assetFolder &&
          other.color == color &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, name, assetFolder, color, sortOrder);

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
