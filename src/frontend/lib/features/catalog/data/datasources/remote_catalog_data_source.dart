import '../../../../core/error/app_exception.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';

/// Contrato del backend (REQ-BCK-01 + REQ-BCK-02).
///
/// Las lecturas son de solo descarga (el sync es el único camino); las
/// escrituras las usa el outbox de subida (RF-5.16/RF-5.17).
abstract interface class RemoteCatalogDataSource {
  // ---- Descarga (REQ-BCK-01) ----

  /// Categorías vigentes + tumbas (con `deletedAt`) para purgar cache.
  Future<List<CategoryModel>> getCategories();
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit});
  Future<PictoModel> getPicto(String id);

  // ---- Subida (REQ-BCK-02) ----

  /// Alta de picto con imagen base64. La respuesta SIEMPRE trae la versión
  /// ganadora: 201 la recién creada; 409 la que ya estaba en el server
  /// (el repositorio decide si adopta, RNF-5.10).
  Future<PictoModel> postPicto(PictoModel picto, {required String imageBase64, required String imageMime});

  /// Edición. Igual que POST: la respuesta trae la versión ganadora.
  Future<PictoModel> putPicto(PictoModel picto, {String? imageBase64, String? imageMime});

  /// Borrado lógico: devuelve la tumba (con `deletedAt`).
  Future<PictoModel> deletePicto(String id);

  /// Alta de categoría. Igual semántica de conflicto que POST picto.
  Future<CategoryModel> postCategory(CategoryModel category);

  /// Edición de categoría (nombre/color).
  Future<CategoryModel> putCategory(CategoryModel category);

  /// Borrado lógico de categoría: devuelve la tumba.
  Future<CategoryModel> deleteCategory(String id);
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

  @override
  Future<PictoModel> postPicto(PictoModel picto, {required String imageBase64, required String imageMime}) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.postPicto: backend pendiente');
  }

  @override
  Future<PictoModel> putPicto(PictoModel picto, {String? imageBase64, String? imageMime}) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.putPicto: backend pendiente');
  }

  @override
  Future<PictoModel> deletePicto(String id) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.deletePicto: backend pendiente');
  }

  @override
  Future<CategoryModel> postCategory(CategoryModel category) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.postCategory: backend pendiente');
  }

  @override
  Future<CategoryModel> putCategory(CategoryModel category) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.putCategory: backend pendiente');
  }

  @override
  Future<CategoryModel> deleteCategory(String id) async {
    throw const UnimplementedFeatureException('RemoteCatalogDataSource.deleteCategory: backend pendiente');
  }
}
