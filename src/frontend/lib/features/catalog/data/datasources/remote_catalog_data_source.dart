import '../../../../core/error/app_exception.dart';
import '../../domain/category.dart';
import '../../domain/picto.dart';

/// Fuente de datos remota: el contrato que hablará con el backend.
///
/// Está como stub a propósito. La app es local-first y no debe romper sin
/// conexión. Cuando exista el backend, se implementan estos métodos con el
/// cliente HTTP y `CatalogRepositoryImpl` los usa para sincronizar.
///
/// Regla de diseño: los errores de red se traducen a `NetworkException` acá, no
/// en la capa de presentación.
class RemoteCatalogDataSource {
  const RemoteCatalogDataSource();

  Future<List<Category>> getCategories() {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.getCategories: falta implementar el backend.',
    );
  }

  Future<List<Picto>> getPictosByCategory(String categoryId) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.getPictosByCategory: falta implementar el backend.',
    );
  }

  Future<Picto> createPicto(Picto picto) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.createPicto: falta implementar el backend.',
    );
  }

  Future<Picto> updatePicto(Picto picto) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.updatePicto: falta implementar el backend.',
    );
  }

  Future<void> deletePicto(String id) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.deletePicto: falta implementar el backend.',
    );
  }

  Future<bool> toggleFavorite(String id) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.toggleFavorite: falta implementar el backend.',
    );
  }

  /// Sube al backend los pictos locales que todavía no se enviaron.
  Future<void> pushPending(List<Picto> pending) {
    throw const UnimplementedFeatureException(
      'RemoteCatalogDataSource.pushPending: falta implementar el backend.',
    );
  }
}
