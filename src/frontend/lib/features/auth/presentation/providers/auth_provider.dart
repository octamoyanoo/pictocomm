import 'package:flutter/foundation.dart';

import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';

/// Estado de autenticación a nivel app (REQ-ACC-01).
sealed class AuthState {
  const AuthState();
}

/// Recién arrancado: todavía no se sabe si hay sesión recordada (RF-6.4).
final class AuthUnknownState extends AuthState {
  const AuthUnknownState();
}

/// Sin sesión: se muestra el login (con su link a registro).
final class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}

/// Sesión activa: entra directo al selector de chico (RF-6.4).
final class AuthAuthenticatedState extends AuthState {
  const AuthAuthenticatedState(this.account);

  final UserAccount account;
}

/// Estado de autenticación de la app: decide qué muestra la pantalla inicial
/// (login vs selector de chico) y expone la cuenta para tagear perfiles
/// (RF-6.6: el selector solo muestra los chicos de la cuenta logueada).
///
/// Los ERRORES de login/registro NO viven acá: los catchea la pantalla
/// (siguen en su formulario con el mensaje bajo el campo, RF-6.8).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository}) : _authRepository = authRepository; // ignore: prefer_initializing_formals

  final AuthRepository _authRepository;

  AuthState _state = const AuthUnknownState();

  AuthState get state => _state;

  /// `true` si hay sesión activa (para rutas que tagean por cuenta).
  bool get isAuthenticated => _state is AuthAuthenticatedState;

  /// Id de la cuenta logueada, o `null` si no hay sesión (los perfiles sin
  /// cuenta —legacy— siguen visibles, RF-6.6).
  String? get currentAccountId => switch (_state) {
    AuthAuthenticatedState(:final account) => account.id,
    _ => null,
  };

  /// Restaura la sesión recordada (RF-6.4). Se llama UNA vez al arrancar la
  /// app (desde `PictoCommApp`): decide login vs selector.
  Future<void> restore() async {
    final session = await _authRepository.restoreSession();
    _state = session == null ? const AuthUnauthenticatedState() : AuthAuthenticatedState(session.account);
    notifyListeners();
  }

  /// Verifica credenciales contra el backend (RF-6.2). Lanza [AuthException]
  /// si falla (la presentación la catchea y muestra el mensaje).
  Future<UserAccount> login({required String email, required String password}) async {
    final session = await _authRepository.login(email: email, password: password);
    _state = AuthAuthenticatedState(session.account);
    notifyListeners();
    return session.account;
  }

  /// Crea la cuenta y deja la sesión iniciada (RF-6.1). Lanza
  /// [AuthException] con `emailInUse` si el email ya existe.
  Future<UserAccount> register({required String name, required String email, required String password}) async {
    final session = await _authRepository.register(name: name, email: email, password: password);
    _state = AuthAuthenticatedState(session.account);
    notifyListeners();
    return session.account;
  }

  /// Cierra la sesión (RF-6.5): revoca el token y vuelve al login.
  Future<void> logout() async {
    await _authRepository.logout();
    _state = const AuthUnauthenticatedState();
    notifyListeners();
  }
}
