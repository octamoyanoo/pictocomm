import '../entities/picto.dart';

abstract interface class PictoRepository {
  Future<List<Picto>> getPictos({String? categoryId});
  Future<Picto?> getPicto(String id);
}
