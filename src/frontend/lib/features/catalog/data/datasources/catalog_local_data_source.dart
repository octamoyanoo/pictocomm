import '../../domain/category.dart';
import '../../domain/picto.dart';

/// Fuente de datos local del catálogo.
///
/// Implementaciones:
///
/// - `AssetCatalogLocalDataSource`: lee categorías y pictos empaquetados desde
///   `assets/`.
/// - `PersistentCatalogLocalDataSource`: lee/escribe pictos propios de la
///   familia en disco.
///
/// La interfaz cubre las dos para que el repositorio no sepa cuál está activa.
abstract interface class CatalogLocalDataSource {
  /// Categorías disponibles, ya ordenadas.
  Future<List<Category>> getCategories();

  /// Pictos de una categoría, empaquetados y propios mezclados.
  Future<List<Picto>> getPictosByCategory(String categoryId);

  /// Inserta o actualiza un picto propio. Lanza `ValidationException` si
  /// [picto] viene empaquetado.
  Future<Picto> saveCustomPicto(Picto picto);

  /// Elimina un picto propio. Lanza `NotFoundException` si no existe.
  Future<void> deleteCustomPicto(String id);

  /// Invierte el favorito de cualquier picto (empaquetado o no) y devuelve el
  /// estado resultante.
  Future<bool> toggleFavorite(String id);
}
