import '../../features/catalog/data/datasources/asset_catalog_local_data_source.dart';
import '../../features/catalog/data/datasources/catalog_local_data_source.dart';
import '../../features/catalog/data/datasources/remote_catalog_data_source.dart';
import '../../features/catalog/data/repositories/local_catalog_repository.dart';
import '../../features/catalog/data/repositories/local_picto_repository.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/catalog/domain/picto_repository.dart';
import '../../features/profiles/data/repositories/in_memory_profile_repository.dart';
import '../../features/profiles/domain/profile_repository.dart';

/// Grafo de dependencias: el único lugar donde se decide qué implementación
/// concreta corresponde a cada interfaz.
///
/// La app pide siempre interfaces, así que cambiar de local-first a híbrido
/// con backend es editar las dos líneas de [production], no tocar pantallas.
class AppDependencies {
  const AppDependencies({
    required this.catalogRepository,
    required this.pictoRepository,
    required this.profileRepository,
  });

  /// Dependencias reales.
  ///
  /// El datasource remoto se inyecta pero no se usa: la estrategia es
  /// local-first, y la sincronización se agrega después sin cambiar la UI.
  factory AppDependencies.production() {
    final CatalogLocalDataSource local = AssetCatalogLocalDataSource();
    const RemoteCatalogDataSource remote = RemoteCatalogDataSource();

    return AppDependencies(
      catalogRepository: LocalCatalogRepository(local),
      pictoRepository: LocalPictoRepository(local, remote),
      profileRepository: InMemoryProfileRepository(),
    );
  }

  final CatalogRepository catalogRepository;
  final PictoRepository pictoRepository;
  final ProfileRepository profileRepository;
}
