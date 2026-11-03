import '../entities/picto.dart';

abstract interface class PictoRepository {
  Future<List<Picto>> getPictos({String? categoryId});
  Future<Picto?> getPicto(String id);

  /// Crea el pictograma y devuelve la versión persistida (con id resuelto).
  Future<Picto> createPicto(Picto picto);
}
