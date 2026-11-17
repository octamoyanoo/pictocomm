import '../entities/auth_session.dart';

/// Fuente de verdad de la autenticación (REQ-ACC-01).
///
/// La implementación real (`LocalAuthRepository`) llama al backend para
/// verificar credenciales y persiste la sesión localmente. La app sigue
/// local-first: solo register/login/logout/me necesitan conexión; con sesión
/// recordada la app abre normal sin red (RF-6.4).
abstract interface class AuthRepository {
  /// Crea la cuenta (RF-6.1) y deja la sesión iniciada. Lanza
  /// [AuthException] con `emailInUse` si el email ya está registrado.
  Future<AuthSession> register({required String name, required String email, required String password});

  /// Verifica credenciales (RF-6.2) y devuelve la sesión con token. Lanza
  /// [AuthException] con `invalidCredentials` si no coinciden.
  Future<AuthSession> login({required String email, required String password});

  /// Devuelve la sesión recordada (RF-6.4) si sigue vigente, o `null` si no
  /// hay sesión, venció o fue revocada en el server. Sin conexión, devuelve
  /// la sesión cacheada mientras no haya vencido (local-first).
  Future<AuthSession?> restoreSession();

  /// Cierra la sesión (RF-6.5): revoca el token en el server (best-effort:
  /// sin conexión igual se cierra localmente) y borra la sesión guardada.
  Future<void> logout();
}
