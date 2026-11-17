import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_account.dart';

/// Contrato HTTP del backend para cuentas (REQ-ACC-01, RF-6.1 a RF-6.5).
///
/// Espeja `POST /api/v1/auth/register|login|logout` y `GET /api/v1/auth/me`.
/// Los errores del backend se traducen a [AuthException] con el código
/// correspondiente; nunca se filtran detalles crudos a la presentación.
abstract interface class RemoteAuthDataSource {
  /// `POST /api/v1/auth/register`: 201 → sesión; 409 → emailInUse.
  Future<AuthSession> register({required String name, required String email, required String password});

  /// `POST /api/v1/auth/login`: 200 → sesión; 401 → invalidCredentials.
  Future<AuthSession> login({required String email, required String password});

  /// `GET /api/v1/auth/me`: valida el token (RF-6.3) y devuelve la cuenta
  /// actualizada. 401 → invalidCredentials (token vencido/revocado).
  Future<UserAccount> me(String token);

  /// `POST /api/v1/auth/logout`: revoca el token server-side (RF-6.5).
  Future<void> logout(String token);
}
