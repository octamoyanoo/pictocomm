import '../entities/child_profile.dart';

/// Fuente de verdad de los perfiles de niños del dispositivo (RF2.10).
///
/// Local-first: toda implementación vive en el dispositivo. El backend
/// de perfiles (cuando exista) implementa esta misma interfaz.
abstract interface class ChildProfileRepository {
  Future<List<ChildProfile>> getChildren();

  /// Crea y persiste un perfil nuevo. Asigna id y completa defaults.
  /// Lanza [DataSourceException] si el nombre queda vacío.
  Future<ChildProfile> createChild(ChildProfile child);

  /// Borra el perfil (RF2.7: la confirmación doble es responsabilidad
  /// de la presentación, no del repositorio). Idempotente: borrar un id
  /// inexistente no falla.
  Future<void> deleteChild(String id);
}
