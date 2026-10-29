import 'package:pictocomm/core/di/injector.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';
import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/catalog/domain/repositories/category_repository.dart';
import 'package:pictocomm/features/catalog/domain/repositories/picto_repository.dart';

final class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({this.categories = const <Category>[]});

  final List<Category> categories;

  @override
  Future<List<Category>> getCategories() async => categories;
}

final class FakePictoRepository implements PictoRepository {
  FakePictoRepository({this.pictos = const <Picto>[]});

  final List<Picto> pictos;

  @override
  Future<List<Picto>> getPictos({String? categoryId}) async {
    if (categoryId == null) {
      return pictos;
    }
    return pictos.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Picto?> getPicto(String id) async {
    for (final picto in pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }
}

final class ExplodingRemoteDataSource implements RemoteCatalogDataSource {
  const ExplodingRemoteDataSource();

  @override
  Future<List<CategoryModel>> getCategories() async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }
}

AppDependencies fakeDependencies({List<Category> categories = const <Category>[], List<Picto> pictos = const <Picto>[]}) {
  return AppDependencies(
    categoryRepository: FakeCategoryRepository(categories: categories),
    pictoRepository: FakePictoRepository(pictos: pictos),
  );
}
