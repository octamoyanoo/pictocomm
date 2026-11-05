import '../entities/picto.dart';

abstract interface class PictoRepository {
  /// [childProfileId] (RF3.6): filtra a catálogo incluido + pictos de ese
  /// chico. `null` devuelve además los custom sin dueño (RF3.7).
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId});

  Future<Picto?> getPicto(String id);

  /// Crea el pictograma y devuelve la versión persistida (con id resuelto).
  /// Lanza [DataSourceException] si falta nombre o imagen.
  Future<Picto> createPicto(Picto picto);

  /// Borra un picto (RF3.8): solo personalizados. Lanza
  /// [DataSourceException] si el picto no es borrable.
  Future<void> deletePicto(String id);
}
