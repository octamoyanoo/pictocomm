import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_account.dart';
import 'remote_auth_data_source.dart';

/// Implementación real de [RemoteAuthDataSource] contra el backend
/// (REQ-ACC-01). Misma configuración de URL que el catálogo:
/// `--dart-define=PICTOCOMM_BACKEND_URL` (RNF-5.3).
final class HttpAuthDataSource implements RemoteAuthDataSource {
  HttpAuthDataSource({
    http.Client? client,
    this.baseUrl = defaultAuthBackendUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static const String defaultAuthBackendUrl = String.fromEnvironment(
    'PICTOCOMM_BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  @override
  Future<AuthSession> register({required String name, required String email, required String password}) async {
    final response = await _post('/api/v1/auth/register', body: <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.statusCode == 409) {
      throw const AuthException('ya existe una cuenta con ese email', code: AuthErrorCode.emailInUse);
    }
    final session = _parseSession(response, path: '/api/v1/auth/register');
    if (session == null) {
      throw const AuthException('el registro falló', code: AuthErrorCode.unexpected);
    }
    return session;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final response = await _post('/api/v1/auth/login', body: <String, dynamic>{
      'email': email,
      'password': password,
    });
    if (response.statusCode == 401) {
      throw const AuthException('email o contraseña incorrectos', code: AuthErrorCode.invalidCredentials);
    }
    final session = _parseSession(response, path: '/api/v1/auth/login');
    if (session == null) {
      throw const AuthException('el login falló', code: AuthErrorCode.unexpected);
    }
    return session;
  }

  @override
  Future<UserAccount> me(String token) async {
    final response = await _execute('GET', '/api/v1/auth/me', token: token);
    if (response.statusCode == 401) {
      throw const AuthException('el token no es válido o venció', code: AuthErrorCode.invalidCredentials);
    }
    if (response.statusCode != 200) {
      throw AuthException('el backend respondió ${response.statusCode} (/api/v1/auth/me)', code: AuthErrorCode.unexpected);
    }
    final body = _decode(response.body, path: '/api/v1/auth/me');
    final id = body['id'] as String?;
    final name = body['name'] as String?;
    final email = body['email'] as String?;
    if (id == null || name == null || email == null) {
      throw const AuthException('la respuesta de /me tiene formato inesperado', code: AuthErrorCode.unexpected);
    }
    return UserAccount(id: id, name: name, email: email);
  }

  @override
  Future<void> logout(String token) async {
    final response = await _execute('POST', '/api/v1/auth/logout', token: token);
    // 200 revoca; 401 el token ya no era válido (mismo resultado para el
    // dispositivo). Otros códigos: igual se cierra localmente, pero avisamos.
    if (response.statusCode != 200 && response.statusCode != 401) {
      throw AuthException('el backend respondió ${response.statusCode} (/api/v1/auth/logout)', code: AuthErrorCode.unexpected);
    }
  }

  // ---- HTTP helpers ----

  /// Parsea la respuesta 200/201 de register/login (RF-6.1/RF-6.2):
  /// `{account: {id, name, email}, token, expiresAt}`. Cualquier otro
  /// status → [AuthException] mapeada (400 → unexpected; 503 → connection).
  AuthSession? _parseSession(http.Response response, {required String path}) {
    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = _decode(response.body, path: path);
      final account = body['account'] as Map<String, dynamic>?;
      final token = body['token'] as String?;
      final expiresAt = body['expiresAt'] as String?;
      final id = account?['id'] as String?;
      final name = account?['name'] as String?;
      final email = account?['email'] as String?;
      final expiry = expiresAt == null ? null : DateTime.tryParse(expiresAt);
      if (account == null || token == null || token.isEmpty || id == null || name == null || email == null || expiry == null) {
        throw AuthException('la respuesta de $path tiene formato inesperado', code: AuthErrorCode.unexpected);
      }
      return AuthSession(account: UserAccount(id: id, name: name, email: email), token: token, expiresAt: expiry);
    }
    if (response.statusCode == 400) {
      // Datos que el frontend no pudo anticipar (ej: server sin cuentas).
      throw AuthException('el backend rechazó $path', code: AuthErrorCode.unexpected);
    }
    if (response.statusCode == 503) {
      throw AuthException('el backend no tiene cuentas habilitadas', code: AuthErrorCode.connection);
    }
    throw AuthException('el backend respondió ${response.statusCode} ($path)', code: AuthErrorCode.unexpected);
  }

  Future<http.Response> _post(String path, {required Map<String, dynamic> body}) {
    return _execute('POST', path, body: jsonEncode(body));
  }

  Future<http.Response> _execute(String method, String path, {String? body, String? token}) async {
    final http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = body;
      }
      if (token != null) {
        request.headers['authorization'] = 'Bearer $token';
      }
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout));
    } on TimeoutException {
      throw AuthException('el backend no respondió en ${timeout.inSeconds}s ($path)', code: AuthErrorCode.connection);
    } on Object catch (error) {
      throw AuthException('no se pudo conectar con el backend ($path): $error', code: AuthErrorCode.connection);
    }
    return response;
  }

  static Map<String, dynamic> _decode(String body, {required String path}) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw AuthException('la respuesta de $path no es un objeto JSON', code: AuthErrorCode.unexpected);
  }
}
