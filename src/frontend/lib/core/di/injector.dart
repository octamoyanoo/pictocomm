import '../../features/catalog/data/datasources/local_catalog_data_source.dart';
import '../../features/catalog/data/datasources/remote_catalog_data_source.dart';
import '../../features/catalog/data/repositories/local_picto_repository.dart';
import '../../features/catalog/domain/repositories/category_repository.dart';
import '../../features/catalog/domain/repositories/picto_repository.dart';

final class AppDependencies {
  const AppDependencies({
    required this.categoryRepository,
    required this.pictoRepository,
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;

  static AppDependencies bootstrap() {
    final localPictoRepository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      remoteDataSource: const UnimplementedRemoteCatalogDataSource(),
    );
    return AppDependencies(
      categoryRepository: localPictoRepository,
      pictoRepository: localPictoRepository,
    );
  }
}
