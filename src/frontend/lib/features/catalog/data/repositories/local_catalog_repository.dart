import '../../domain/catalog_repository.dart';
import '../../domain/category.dart';
import '../datasources/catalog_local_data_source.dart';

/// Implementación local de [CatalogRepository].
///
/// Las categorías son datos maestros que vienen empaquetados en la app, así que
/// solo se leen. El backend podrá sobrescribirlas más adelante (catálogo
/// actualizado sin publicar una versión nueva), pero eso afecta a
/// [CatalogRepositoryImpl], no a esta clase.
class LocalCatalogRepository implements CatalogRepository {
  const LocalCatalogRepository(this._local);

  final CatalogLocalDataSource _local;

  @override
  Future<List<Category>> getCategories() => _local.getCategories();

  @override
  Future<Category?> getCategory(String id) async {
    final List<Category> list = await _local.getCategories();
    for (final Category c in list) {
      if (c.id == id) return c;
    }
    return null;
  }
}
