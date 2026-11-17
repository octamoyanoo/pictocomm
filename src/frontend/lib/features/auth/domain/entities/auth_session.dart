import 'package:flutter/foundation.dart' show immutable;

import 'user_account.dart';

/// Sesión activa de una cuenta (REQ-ACC-01): el token opaco del backend con
/// su expiración. Se persiste en SharedPreferences (RF-6.4: la app recuerda
/// la sesión y saltea el login) y viaja como `Authorization: Bearer <token>`
/// en las llamadas autenticadas.
@immutable
final class AuthSession {
  const AuthSession({
    required this.account,
    required this.token,
    required this.expiresAt,
  });

  final UserAccount account;
  final String token;
  final DateTime expiresAt;

  /// `true` si la sesión sigue vigente a [now] (el token venció → re-login).
  bool isValid(DateTime now) => expiresAt.isAfter(now);
}
