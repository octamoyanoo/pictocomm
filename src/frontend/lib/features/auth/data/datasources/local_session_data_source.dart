import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_account.dart';

/// Almacén local de la sesión (REQ-ACC-01, RF-6.4): SharedPreferences con
/// clave propia (`pictocomm.auth_session`), separada de las claves del
/// catálogo (`pictocomm.remote_*`) y de los perfiles (`pictocomm.children_*`).
///
/// Guarda lo mínimo: id/nombre/email de la cuenta + token + expiración. La
/// contraseña NUNCA se persiste (solo viaja por HTTPS al backend).
final class LocalSessionDataSource {
  const LocalSessionDataSource();

  static const String _sessionKey = 'pictocomm.auth_session';

  /// Sesión guardada, o `null` si no hay (o el JSON está corrupto).
  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final account = json['account'] as Map<String, dynamic>;
      final token = json['token'] as String;
      final expiresAt = DateTime.parse(json['expiresAt'] as String);
      return AuthSession(
        account: UserAccount(
          id: account['id'] as String,
          name: account['name'] as String,
          email: account['email'] as String,
        ),
        token: token,
        expiresAt: expiresAt,
      );
    } on Object {
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(<String, dynamic>{
      'account': <String, dynamic>{
        'id': session.account.id,
        'name': session.account.name,
        'email': session.account.email,
      },
      'token': session.token,
      'expiresAt': session.expiresAt.toUtc().toIso8601String(),
    });
    await prefs.setString(_sessionKey, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
