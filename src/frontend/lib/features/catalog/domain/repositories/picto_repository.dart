import '../entities/picto.dart';

abstract interface class PictoRepository {
  /// [childProfileId] (RF3.6): filtra a catálogo incluido + pictos de ese
  /// chico. `null` devuelve además los custom sin dueño (RF3.7).
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId});

  Future<Picto?> getPicto(String id);

  /// Crea el pictograma y devuelve la versión persistida (con id resuelto).
  /// Lanza [DataSourceException] si falta nombre o imagen.
  Future<Picto> createPicto(Picto picto);

  /// Borra un picto (RF3.8): solo personalizados. Con [childProfileId] de la
  /// sesión activa, lanza [DataSourceException] si el picto pertenece a otro
  /// chico. Sin sesión (gestión adulto), borra cualquier custom.
  Future<void> deletePicto(String id, {String? childProfileId});

  /// Cascada del borrado de perfil (RF2.7): elimina TODOS los pictos
  /// personalizados de ese chico, en cualquier categoría.
  Future<void> deletePictosForChild(String childProfileId);
}
