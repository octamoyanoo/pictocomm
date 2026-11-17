import '../entities/child_profile.dart';

/// Fuente de verdad de los perfiles de niños del dispositivo (RF2.10).
///
/// Local-first: toda implementación vive en el dispositivo. El backend
/// de perfiles (cuando exista) implementa esta misma interfaz.
///
/// REQ-ACC-01 (RF-6.6): los perfiles se tagean con `accountId`. `null`
/// significa "sin filtro" (gestión que ve todo) para lecturas; los legacy
/// (creados antes de las cuentas, `accountId` null persistido) siguen
/// visibles para cualquier cuenta.
abstract interface class ChildProfileRepository {
  /// Con [accountId], devuelve solo los perfiles de esa cuenta + los legacy
  /// (sin cuenta). Sin filtro, devuelve todos (gestión).
  Future<List<ChildProfile>> getChildren({String? accountId});

  /// Crea el perfil y devuelve la versión persistida (con id resuelto).
  /// Con [accountId], tagea el perfil como dueño de esa cuenta (RF-6.6).
  /// Lanza [DataSourceException] si el nombre queda vacío.
  Future<ChildProfile> createChild(ChildProfile child, {String? accountId});

  /// Actualiza el perfil persistido (RF3.11: la foto). Devuelve la versión
  /// persistida. Lanza [DataSourceException] si el perfil no existe.
  Future<ChildProfile> updateChild(ChildProfile child);

  /// Borra el perfil (RF2.7: la confirmación doble es responsabilidad
  /// de la presentación, no del repositorio). Idempotente: borrar un id
  /// inexistente no falla.
  Future<void> deleteChild(String id);

  /// REQ-PER-01: id del último chico activo de [accountId] (null = legacy,
  /// mismo criterio de clave que getChildren), para preseleccionarlo en el
  /// selector. La app siempre arranca en el selector (RF2.1): esto solo
  /// MARCA la tarjeta, nunca activa la sesión.
  Future<String?> getLastChildId({String? accountId});

  /// REQ-PER-01: persiste (o limpia, con `null`) el último chico activo de
  /// [accountId]. La clave es por cuenta: dos cuentas del mismo dispositivo
  /// no se pisan la preselección.
  Future<void> setLastChildId(String? childId, {String? accountId});
}
