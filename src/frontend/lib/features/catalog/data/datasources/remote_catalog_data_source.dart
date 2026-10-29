import '../../../../core/error/app_exception.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';

abstract interface class RemoteCatalogDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit});
  Future<PictoModel> getPicto(String id);
}

final class UnimplementedRemoteCatalogDataSource implements RemoteCatalogDataSource {
  const UnimplementedRemoteCatalogDataSource();

  @override
  Future<List<CategoryModel>> getCategories() async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.getCategories: backend pendiente');
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.getPictos: backend pendiente');
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.getPicto: backend pendiente');
  }
}
