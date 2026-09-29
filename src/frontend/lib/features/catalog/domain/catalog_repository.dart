import '../domain/category.dart';

/// Contrato de acceso a las categorías.
///
/// La app es local-first: la implementación real (ver
/// `data/repositories/catalog_repository_impl.dart`) lee siempre del
/// almacenamiento local. Cuando exista el backend se agrega el datasource
/// remoto, no se cambia esta interfaz.
abstract interface class CatalogRepository {
  /// Categorías ordenadas por `Category.sortOrder`.
  ///
  /// Lanza `StorageException` si el almacenamiento local no responde.
  Future<List<Category>> getCategories();

  /// `null` si no existe una categoría con ese id.
  Future<Category?> getCategory(String id);
}
