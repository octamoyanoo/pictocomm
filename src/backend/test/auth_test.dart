import 'dart:convert';
import 'dart:io';

import 'package:pictocomm_backend/pictocomm_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const String _base = 'http://localhost:8080';

/// REQ-ACC-01: cuentas, sesiones y tokens (RF-6.1 a RF-6.5).
///
/// Cada test arranca un server real con cuentas en un archivo temporal
/// (`data/accounts.json`), igual que el catálogo con `uploads.json`.
void main() {
  late Directory tempDir;
  late CatalogStore store;
  late AccountStore accounts;
  late Router router;
  late String accountsPath;

  Future<Response> call(String method, String path, {Object? body, String? bearer}) {
    final uri = Uri.parse('$_base$path');
    final request = Request(
      method,
      uri,
      body: body == null ? null : jsonEncode(body),
      headers: bearer == null ? null : {'authorization': 'Bearer $bearer'},
    );
    return router.call(request);
  }

  Future<Map<String, dynamic>> callJson(String method, String path, {Object? body, String? bearer}) async {
    final response = await call(method, path, body: body, bearer: bearer);
    return <String, dynamic>{
      'status': response.statusCode,
      'body': jsonDecode(await response.readAsString()) as Map<String, dynamic>,
    };
  }

  Map<String, Object> registerBody({String name = 'Ana', String email = 'ana@mail.com', String password = 'secreta123'}) {
    return <String, Object>{'name': name, 'email': email, 'password': password};
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pictocomm_auth');
    accountsPath = '${tempDir.path}${Platform.pathSeparator}accounts.json';
    store = CatalogStore.loadFrom('data${Platform.pathSeparator}seed.json');
    accounts = AccountStore(accountsPath: accountsPath)..load();
    router = buildApiRouter(store: store, imagesDirectory: '${tempDir.path}${Platform.pathSeparator}images', accounts: accounts);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('RF-6.1/CA-6.1: register crea la cuenta, devuelve token y NO expone el hash', () async {
    final response = await callJson('POST', '/api/v1/auth/register', body: registerBody());
    expect(response['status'], 201);
    expect(response['body']['account']['name'], 'Ana');
    expect(response['body']['account']['email'], 'ana@mail.com');
    expect(response['body']['token'], isNotEmpty);
    expect(response['body']['expiresAt'], isNotEmpty);
    expect(jsonEncode(response['body']), isNot(contains('hash')));
    expect(jsonEncode(response['body']), isNot(contains('salt')));
    // El id es nuevo y estable.
    final accountId = response['body']['account']['id'] as String;
    expect(accountId, startsWith('account-'));
  });

  test('RF-6.1/CA-6.3: register con datos inválidos responde 400', () async {
    expect((await callJson('POST', '/api/v1/auth/register', body: registerBody(name: ' ')))['status'], 400);
    expect((await callJson('POST', '/api/v1/auth/register', body: registerBody(email: 'sin-arroba')))['status'], 400);
    expect((await callJson('POST', '/api/v1/auth/register', body: registerBody(password: 'corta')))['status'], 400);
    expect((await callJson('POST', '/api/v1/auth/register', body: {'email': 'ana@mail.com'}))['status'], 400);
    expect((await callJson('POST', '/api/v1/auth/register', body: 'no-json'))['status'], 400);
  });

  test('RF-6.1/CA-6.2: register con email duplicado responde 409 (case-insensitive)', () async {
    await callJson('POST', '/api/v1/auth/register', body: registerBody());
    final duplicate = await callJson('POST', '/api/v1/auth/register', body: registerBody(name: 'Otra'));
    expect(duplicate['status'], 409);
    // Ana@mail.com y ana@mail.com son la misma cuenta.
    final upper = await callJson('POST', '/api/v1/auth/register', body: registerBody(email: 'ANA@MAIL.COM'));
    expect(upper['status'], 409);
  });

  test('RF-6.2/CA-6.4: login con credenciales correctas devuelve token; incorrectas 401', () async {
    await callJson('POST', '/api/v1/auth/register', body: registerBody());

    final ok = await callJson('POST', '/api/v1/auth/login', body: registerBody());
    expect(ok['status'], 200);
    expect(ok['body']['account']['email'], 'ana@mail.com');
    expect(ok['body']['token'], isNotEmpty);

    expect((await callJson('POST', '/api/v1/auth/login', body: registerBody(password: 'otraclave99')))['status'], 401);
    expect(
      (await callJson('POST', '/api/v1/auth/login', body: registerBody(email: 'nadie@mail.com')))['status'],
      401,
    );
    // Mismo 401 (sin distinguir email inexistente de contraseña incorrecta).
    final missing = (await callJson('POST', '/api/v1/auth/login', body: registerBody(email: 'nadie@mail.com')))['body'];
    final wrongPassword = (await callJson('POST', '/api/v1/auth/login', body: registerBody(password: 'otraclave99')))['body'];
    expect(missing['error'], wrongPassword['error']);
  });

  test('RF-6.3: me valida el token Bearer; sin/vencido/inválido → 401', () async {
    final registered = await callJson('POST', '/api/v1/auth/register', body: registerBody());
    final token = registered['body']['token'] as String;

    final me = await callJson('GET', '/api/v1/auth/me', bearer: token);
    expect(me['status'], 200);
    expect(me['body']['email'], 'ana@mail.com');

    expect((await callJson('GET', '/api/v1/auth/me'))['status'], 401);
    expect((await callJson('GET', '/api/v1/auth/me', bearer: 'token-inventado'))['status'], 401);
  });

  test('RF-6.5: logout invalida el token; es idempotente', () async {
    final registered = await callJson('POST', '/api/v1/auth/register', body: registerBody());
    final token = registered['body']['token'] as String;

    expect((await callJson('POST', '/api/v1/auth/logout', bearer: token))['status'], 200);
    expect((await callJson('GET', '/api/v1/auth/me', bearer: token))['status'], 401);
    // Segundo logout del mismo token: sigue sin explotar.
    expect((await callJson('POST', '/api/v1/auth/logout', bearer: token))['status'], 401);
  });

  test('RNF-6.4: las cuentas y sesiones sobreviven un reinicio del server', () async {
    await callJson('POST', '/api/v1/auth/register', body: registerBody());
    final login = await callJson('POST', '/api/v1/auth/login', body: registerBody());
    final token = login['body']['token'] as String;

    // "Reinicio": store nuevo desde el mismo archivo.
    final restarted = AccountStore(accountsPath: accountsPath)..load();
    final router2 = buildApiRouter(
      store: store,
      imagesDirectory: '${tempDir.path}${Platform.pathSeparator}images',
      accounts: restarted,
    );
    final me = await router2.call(Request('GET', Uri.parse('$_base/api/v1/auth/me'), headers: {'authorization': 'Bearer $token'}));
    expect(me.statusCode, 200);
  });

  test('RNF-6.3: la misma contraseña con salt distinto produce hashes distintos', () async {
    await callJson('POST', '/api/v1/auth/register', body: registerBody(email: 'a@mail.com'));
    await callJson('POST', '/api/v1/auth/register', body: registerBody(email: 'b@mail.com'));
    final raw = jsonDecode(File(accountsPath).readAsStringSync()) as Map<String, dynamic>;
    final hashes = (raw['accounts'] as List).map((account) => (account as Map)['hashBase64']);
    expect(hashes.toSet().length, 2);
  });

  test('sin AccountStore (server sin cuentas): auth responde 503/401 sin crashear', () async {
    final routerNoAccounts = buildApiRouter(store: store, imagesDirectory: tempDir.path);
    final register = await routerNoAccounts.call(Request('POST', Uri.parse('$_base/api/v1/auth/register'), body: jsonEncode(registerBody())));
    expect(register.statusCode, 503);
    final me = await routerNoAccounts.call(Request('GET', Uri.parse('$_base/api/v1/auth/me')));
    expect(me.statusCode, 401);
  });
}
