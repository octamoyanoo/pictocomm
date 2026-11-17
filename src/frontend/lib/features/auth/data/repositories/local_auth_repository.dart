import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_session_data_source.dart';
import '../datasources/remote_auth_data_source.dart';

/// Implementación de [AuthRepository] (REQ-ACC-01): verifica contra el
/// backend y persiste la sesión localmente.
///
/// La app sigue local-first: el ÚNICO camino al remote es este repositorio
/// (nunca lecturas dispersas, igual que el catálogo con RF-5.11). Con sesión
/// recordada, `restoreSession` funciona sin conexión mientras el token no
/// haya vencido: la verificación server-side falla en silencio y se confía
/// en el cache (el token tiene 30 días de vida, RNF-6.7).
final class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required RemoteAuthDataSource remoteDataSource,
    required LocalSessionDataSource sessionDataSource,
  }) : _remoteDataSource = remoteDataSource, // ignore: prefer_initializing_formals
       _sessionDataSource = sessionDataSource; // ignore: prefer_initializing_formals

  final RemoteAuthDataSource _remoteDataSource;
  final LocalSessionDataSource _sessionDataSource;

  @override
  Future<AuthSession> register({required String name, required String email, required String password}) async {
    final session = await _remoteDataSource.register(name: name, email: email, password: password);
    await _sessionDataSource.save(session);
    return session;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final session = await _remoteDataSource.login(email: email, password: password);
    await _sessionDataSource.save(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _sessionDataSource.read();
    if (session == null) {
      return null;
    }
    if (!session.isValid(DateTime.now())) {
      // RF-6.4: vencida → borrar y pedir login.
      await _sessionDataSource.clear();
      return null;
    }
    try {
      // Verificación server-side (RF-6.3): revocada/vencida en el server →
      // se descarta. Si falla la conexión, el cache vale (local-first).
      await _remoteDataSource.me(session.token);
      return session;
    } on AuthException catch (error) {
      if (error.code == AuthErrorCode.invalidCredentials) {
        await _sessionDataSource.clear();
        return null;
      }
      return session;
    }
  }

  @override
  Future<void> logout() async {
    final session = await _sessionDataSource.read();
    if (session != null) {
      // Best-effort: sin conexión igual se cierra la sesión local (RF-6.5);
      // el token vencerá solo en el server a los 30 días.
      try {
        await _remoteDataSource.logout(session.token);
      } on Object {
        // La sesión local se borra igual: el usuario sale siempre.
      }
    }
    await _sessionDataSource.clear();
  }
}
