import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cuenta del backend (REQ-ACC-01): email único, nombre y contraseña hasheada.
///
/// La contraseña NUNCA se guarda en claro ni se envía de vuelta: solo viaja el
/// hash PBKDF2-HMAC-SHA256 con salt aleatoria (ver [hashPassword]).
/// `createdAt`/`updatedAt` en ISO-8601 UTC (RNF-5.6).
final class StoredAccount {
  const StoredAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.saltBase64,
    required this.hashBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String saltBase64;
  final String hashBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'saltBase64': saltBase64,
    'hashBase64': hashBase64,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static StoredAccount fromJson(Map<String, dynamic> json) {
    return StoredAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      saltBase64: json['saltBase64'] as String,
      hashBase64: json['hashBase64'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Sesión activa de una cuenta: token opaco con expiración (REQ-ACC-01).
///
/// Se persiste junto a las cuentas en `data/accounts.json` para que un
/// reinicio del server NO invalide las sesiones de los dispositivos.
final class StoredSession {
  const StoredSession({
    required this.token,
    required this.accountId,
    required this.expiresAt,
  });

  final String token;
  final String accountId;
  final DateTime expiresAt;

  bool isValid(DateTime now) => expiresAt.isAfter(now);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'accountId': accountId,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };

  static StoredSession fromJson(Map<String, dynamic> json) {
    return StoredSession(
      token: json['token'] as String,
      accountId: json['accountId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Resultados de las operaciones de cuenta: error legible o éxito.
sealed class AccountResult {
  const AccountResult();
}

final class AccountCreated extends AccountResult {
  const AccountCreated(this.account);

  final StoredAccount account;
}

final class AccountLoggedIn extends AccountResult {
  const AccountLoggedIn(this.account);

  final StoredAccount account;
}

/// El email ya tiene cuenta (register → 409).
final class AccountEmailInUse extends AccountResult {
  const AccountEmailInUse();
}

/// Email o contraseña incorrectos (login → 401). Deliberadamente NO distingue
/// entre "email inexistente" y "contraseña incorrecta" para no revelar qué
/// cuentas existen (enumeración de usuarios, RNF-6.6).
final class AccountInvalidCredentials extends AccountResult {
  const AccountInvalidCredentials();
}

/// Cuerpo inválido (register/login → 400): falta campo o no pasa validación.
final class AccountInvalidInput extends AccountResult {
  const AccountInvalidInput(this.message);

  final String message;
}

/// Parámetros del hash de contraseñas (RNF-6.3).
///
/// PBKDF2-HMAC-SHA256 con salt de 16 bytes aleatoria por cuenta. Las
/// iteraciones son conservadoras para que el server puro Dart no tarde más
/// de ~50ms por login (en producción convendría >100k con bcrypt/argon2:
/// limitación documentada en el REQ-ACC-01).
const int pbkdf2Iterations = 10000;
const int saltBytes = 16;
const int hashBytes = 32;

/// PBKDF2-HMAC-SHA256 (RFC 2898). `crypto` 3.0.x no trae `pbkdf2`, así que se
/// implementa con [Hmac]: cada bloque encadena `dk^(i)` como XOR de los
/// HMAC-SHA256 sucesivos (U1 = PRF(salt || INT(i)), Ui = PRF(U(i-1))).
String hashPassword(String password, String saltBase64) {
  final salt = base64Decode(saltBase64);
  final hmac = Hmac(sha256, utf8.encode(password));
  final blocks = (hashBytes / 32).ceil();
  final derived = <int>[];
  for (var block = 1; block <= blocks; block++) {
    final blockSalt = [...salt, 0, (block >> 24) & 0xFF, (block >> 16) & 0xFF, (block >> 8) & 0xFF, block & 0xFF];
    var u = hmac.convert(blockSalt).bytes;
    final accumulator = List<int>.of(u);
    for (var round = 1; round < pbkdf2Iterations; round++) {
      u = hmac.convert(u).bytes;
      for (var i = 0; i < u.length; i++) {
        accumulator[i] ^= u[i];
      }
    }
    derived.addAll(accumulator);
  }
  return base64Encode(derived.take(hashBytes).toList());
}

/// Cuentas + sesiones del backend: persistidas en `data/accounts.json`
/// (sobrevive reinicios, igual que `uploads.json` para el catálogo, RNF-6.4).
final class AccountStore {
  AccountStore({
    required this.accountsPath,
    this.sessionLifetime = const Duration(days: 30),
    this.randomProvider,
  });

  /// Path de `data/accounts.json` para persistir cuentas y sesiones.
  final String accountsPath;

  /// Duración de vida del token de sesión (REQ-ACC-01: 30 días, luego el
  /// dispositivo re-loguea).
  final Duration sessionLifetime;

  /// Inyección del generador de aleatoriedad (tests usan un seed fijo).
  final Random? randomProvider;

  final Map<String, StoredAccount> _accountsByEmail = {};
  final Map<String, StoredAccount> _accountsById = {};
  final Map<String, StoredSession> _sessionsByToken = {};

  /// Carga `data/accounts.json`. Archivo inexistente/inválido = sin cuentas
  /// (misma tolerancia que el seed del catálogo, UC-01.2 alt 1).
  void load() {
    final file = File(accountsPath);
    if (!file.existsSync()) {
      return;
    }
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final item in json['accounts'] as List<dynamic>? ?? const <dynamic>[]) {
        final account = StoredAccount.fromJson(item as Map<String, dynamic>);
        _accountsByEmail[account.email] = account;
        _accountsById[account.id] = account;
      }
      for (final item in json['sessions'] as List<dynamic>? ?? const <dynamic>[]) {
        final session = StoredSession.fromJson(item as Map<String, dynamic>);
        _sessionsByToken[session.token] = session;
      }
      _purgeExpiredSessions();
    } on Object catch (error) {
      // ignore: avoid_print
      print('pictocomm_backend: accounts.json inválido "$accountsPath": $error — se ignora y arranca vacío');
      _accountsByEmail.clear();
      _accountsById.clear();
      _sessionsByToken.clear();
    }
  }

  void _purgeExpiredSessions() {
    final now = DateTime.now().toUtc();
    _sessionsByToken.removeWhere((_, session) => !session.isValid(now));
  }

  /// Valida el cuerpo de registro (RF-6.1): nombre, email con formato y
  /// contraseña con mínimo de 8. Devuelve el mensaje de error o null.
  String? validateRegisterBody(String name, String email, String password) {
    if (name.trim().isEmpty) {
      return 'name es requerido';
    }
    if (!_emailRegExp.hasMatch(email)) {
      return 'email es requerido y debe tener formato válido';
    }
    if (password.length < 8) {
      return 'password debe tener al menos 8 caracteres';
    }
    return null;
  }

  /// Crea la cuenta (RF-6.1). Email case-insensitive (se normaliza a
  /// minúsculas): `Ana@mail.com` y `ana@mail.com` son la misma cuenta.
  AccountResult register({required String name, required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    final invalid = validateRegisterBody(name, normalizedEmail, password);
    if (invalid != null) {
      return AccountInvalidInput(invalid);
    }
    if (_accountsByEmail.containsKey(normalizedEmail)) {
      return const AccountEmailInUse();
    }
    final now = DateTime.now().toUtc();
    final salt = base64Encode(_randomBytes(saltBytes));
    final account = StoredAccount(
      id: 'account-${_newId()}',
      name: name.trim(),
      email: normalizedEmail,
      saltBase64: salt,
      hashBase64: hashPassword(password, salt),
      createdAt: now,
      updatedAt: now,
    );
    _accountsByEmail[account.email] = account;
    _accountsById[account.id] = account;
    _persist();
    return AccountCreated(account);
  }

  /// Verifica credenciales (RF-6.2): mismo mensaje para email inexistente y
  /// contraseña incorrecta (ver [AccountInvalidCredentials]).
  AccountResult login({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accountsByEmail[normalizedEmail];
    if (account == null) {
      return const AccountInvalidCredentials();
    }
    final candidate = hashPassword(password, account.saltBase64);
    if (!_fixedLengthEquals(candidate, account.hashBase64)) {
      return const AccountInvalidCredentials();
    }
    return AccountLoggedIn(account);
  }

  /// Crea una sesión nueva para la cuenta (RF-6.2): token opaco de 32 bytes
  /// con expiración. Persiste inmediatamente (el reinicio no la pierde).
  StoredSession createSession(StoredAccount account) {
    final session = StoredSession(
      token: _newToken(),
      accountId: account.id,
      expiresAt: DateTime.now().toUtc().add(sessionLifetime),
    );
    _sessionsByToken[session.token] = session;
    _persist();
    return session;
  }

  /// Devuelve el par (sesión, cuenta) si el token es válido y no venció.
  (StoredSession, StoredAccount)? sessionByToken(String token) {
    final session = _sessionsByToken[token];
    if (session == null || !session.isValid(DateTime.now().toUtc())) {
      return null;
    }
    final account = _accountsById[session.accountId];
    if (account == null) {
      return null;
    }
    return (session, account);
  }

  /// Cierra la sesión del token (RF-6.5). Idempotente: token inexistente no
  /// falla.
  void logout(String token) {
    if (_sessionsByToken.remove(token) != null) {
      _persist();
    }
  }

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Random get _random => randomProvider ?? Random.secure();

  List<int> _randomBytes(int length) => [for (var i = 0; i < length; i++) _random.nextInt(256)];

  String _newToken() => base64UrlEncode(_randomBytes(32)).replaceAll('=', '');

  String _newId() {
    final hex = [for (final byte in _randomBytes(8)) byte.toRadixString(16).padLeft(2, '0')].join();
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36) + hex;
  }

  /// Comparación a tiempo constante-ish: siempre compara toda la longitud
  /// aunque difiera en el primer byte (evita el oracle trivial por cortocircuito).
  static bool _fixedLengthEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// RNF-6.4: reescribe `accounts.json` (sin exponer hashes en la API).
  /// Best-effort: si el disco falla, el estado en memoria queda igual.
  void _persist() {
    try {
      final file = File(accountsPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'accounts': [for (final account in _accountsByEmail.values) account.toJson()],
        'sessions': [for (final session in _sessionsByToken.values) session.toJson()],
      }));
    } on FileSystemException catch (error) {
      // ignore: avoid_print
      print('pictocomm_backend: no se pudo persistir accounts "$accountsPath": ${error.message}');
    }
  }
}
