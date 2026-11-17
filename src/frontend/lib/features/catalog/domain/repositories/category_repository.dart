import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories();

  /// Crea la categoría y devuelve la versión persistida (con id resuelto).
  /// Lanza [DuplicateCatalogException] si el nombre ya existe y
  /// [DataSourceException] si el nombre queda vacío.
  Future<Category> createCategory(Category category);

  /// REQ-CAT-02 (RF-3.17): renombra/recolorea una categoría custom sin
  /// cambiar su id (la pertenencia de los pictos es por id, RF-3.17).
  /// Lanza [DuplicateCatalogException] si el nombre nuevo colisiona con otra
  /// categoría y [DataSourceException] si no es editable (incluida) o el
  /// nombre queda vacío.
  Future<Category> updateCategory(Category category);

  /// Borra una categoría (RF3.9, cascada multicategoría RF-3.20): quita esa
  /// membresía de todos los pictos custom; los del chico activo
  /// ([childProfileId], con sesión) que quedan sin ninguna categoría se
  /// eliminan en cascada; los de otros chicos sobreviven huérfanos. Sin
  /// sesión, la cascada elimina todos los que queden sin categoría. Lanza
  /// [DataSourceException] si la categoría no es borrable (incluida) o no
  /// existe.
  Future<void> deleteCategory(String id, {String? childProfileId});
}
