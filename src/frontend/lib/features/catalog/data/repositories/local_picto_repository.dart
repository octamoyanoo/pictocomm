import '../../../../core/error/app_exception.dart';
import '../../domain/picto.dart';
import '../../domain/picto_repository.dart';
import '../../domain/picto_source.dart';
import '../datasources/catalog_local_data_source.dart';
import '../datasources/remote_catalog_data_source.dart';

/// Repositorio de pictos con estrategia local-first.
///
/// - Lecturas: siempre locales, para que la app funcione sin conexión.
/// - Escrituras: van a local primero; el `_remote` queda inyectado para que la
///   sincronización se agregue después sin cambiar esta clase ni las pantallas.
class LocalPictoRepository implements PictoRepository {
  LocalPictoRepository(this._local, this._remote);

  final CatalogLocalDataSource _local;

  /// Aún no se usa: la sincronización se implementará en el paso de backend.
  // ignore: unused_field
  final RemoteCatalogDataSource _remote;

  @override
  Future<List<Picto>> getPictos({
    required String categoryId,
    PictoSource? source,
    bool favoritesOnly = false,
  }) async {
    final List<Picto> list = await _local.getPictosByCategory(categoryId);

    Iterable<Picto> filtered = list;
    if (source != null) {
      filtered = filtered.where((Picto p) => p.source == source);
    }
    if (favoritesOnly) {
      filtered = filtered.where((Picto p) => p.isFavorite);
    }
    return filtered.toList();
  }

  @override
  Future<Picto> savePicto(Picto picto) async {
    if (picto.source == PictoSource.bundled) {
      throw const ValidationException(
        'Los pictos empaquetados no se pueden guardar.',
      );
    }
    return _local.saveCustomPicto(picto);
  }

  @override
  Future<void> deletePicto(String id) => _local.deleteCustomPicto(id);

  @override
  Future<bool> toggleFavorite(String id) => _local.toggleFavorite(id);
}
