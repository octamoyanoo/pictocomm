import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories();

  /// Crea la categoría y devuelve la versión persistida (con id resuelto).
  Future<Category> createCategory(Category category);
}
