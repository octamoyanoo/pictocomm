sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class UnimplementedFeatureException extends AppException {
  const UnimplementedFeatureException(super.message);
}

final class DataSourceException extends AppException {
  const DataSourceException(super.message);
}

final class DuplicateCatalogException extends AppException {
  const DuplicateCatalogException(super.message);
}

/// La generación de voz falló (engine no disponible, voz sin configurar, etc.).
final class VoiceException extends AppException {
  const VoiceException(super.message);
}

/// Códigos de error de autenticación (REQ-ACC-01): la presentación los mapea
/// a mensajes l10n sin parsear strings.
enum AuthErrorCode {
  /// Login con credenciales incorrectas o token vencido/revocado.
  invalidCredentials,

  /// Registro con un email que ya tiene cuenta (409 del backend).
  emailInUse,

  /// El backend no respondió (sin conexión, timeout).
  connection,

  /// Cualquier otro caso (cuerpo inválido, server sin cuentas, etc.).
  unexpected,
}

/// Falla de autenticación (login/registro/sesión): con [code] para que la
/// presentación elija el mensaje l10n correcto.
final class AuthException extends AppException {
  const AuthException(super.message, {required this.code});

  final AuthErrorCode code;
}
