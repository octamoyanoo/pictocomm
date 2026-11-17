import '../entities/picto.dart';

abstract interface class PictoRepository {
  /// [childProfileId] (RF3.6): filtra a catálogo incluido + pictos de ese
  /// chico. `null` devuelve además los custom sin dueño (RF3.7). [categoryId]
  /// (REQ-CAT-02, RF-3.15): filtra por pertenencia — un picto multicategoría
  /// aparece en cada una de sus categorías.
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId});

  Future<Picto?> getPicto(String id);

  /// Crea el pictograma y devuelve la versión persistida (con id resuelto).
  /// Lanza [DataSourceException] si falta nombre, imagen o categorías.
  Future<Picto> createPicto(Picto picto);

  /// REQ-CAT-02 (RF-3.16): edita un picto custom (nombre, imagen,
  /// categorías y asignación de dueño opcional RF-3.19). Devuelve la
  /// versión persistida con `updatedAt` avanzado. Mismas validaciones que
  /// crear + reglas de borrado (RF-3.18): solo custom, y con sesión solo
  /// del chico activo.
  Future<Picto> updatePicto(Picto picto, {String? childProfileId});

  /// Borra un picto (RF3.8): solo personalizados. Con [childProfileId] de la
  /// sesión activa, lanza [DataSourceException] si el picto pertenece a otro
  /// chico. Sin sesión (gestión adulto), borra cualquier custom.
  Future<void> deletePicto(String id, {String? childProfileId});

  /// Cascada del borrado de perfil (RF2.7): elimina TODOS los pictos
  /// personalizados de ese chico, en cualquier categoría.
  Future<void> deletePictosForChild(String childProfileId);
}
