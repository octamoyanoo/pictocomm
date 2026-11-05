import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories();

  /// Crea la categoría y devuelve la versión persistida (con id resuelto).
  /// Lanza [DuplicateCatalogException] si el nombre ya existe y
  /// [DataSourceException] si el nombre queda vacío.
  Future<Category> createCategory(Category category);

  /// Borra una categoría (RF3.9): solo personalizadas, y elimina en cascada
  /// **solo los pictos de ese chico** en ella ([childProfileId], con sesión
  /// activa). Sin sesión, la cascada elimina los pictos de la categoría.
  /// Lanza [DataSourceException] si la categoría no es borrable (incluida) o
  /// no existe.
  Future<void> deleteCategory(String id, {String? childProfileId});
}
