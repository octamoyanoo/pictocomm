import 'dart:io';

import 'package:pictocomm_backend/pictocomm_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Corre el backend de PictoComm: `dart run bin/server.dart` desde `src/backend/`.
///
/// - Puerto: variable de entorno `PORT`, default 8080 (RNF-5.2).
/// - Seed: `data/seed.json` relativo a la raíz del paquete (RF-5.3).
/// - Uploads: `data/uploads.json` + `data/images/uploads/` (REQ-BCK-02).
/// - Cuentas: `data/accounts.json` (REQ-ACC-01).
/// - Imágenes: `data/images/` servidas como estáticos (RF-5.4).
Future<void> main() async {
  final packageRoot = Directory(Platform.script.toFilePath()).parent.parent;
  final dataRoot = '${packageRoot.path}${Platform.pathSeparator}data';
  final seedPath = '$dataRoot${Platform.pathSeparator}seed.json';
  final uploadsPath = '$dataRoot${Platform.pathSeparator}uploads.json';
  final accountsPath = '$dataRoot${Platform.pathSeparator}accounts.json';
  final imagesDirectory = '$dataRoot${Platform.pathSeparator}images';

  final store = CatalogStore.loadFrom(seedPath, uploadsPath: uploadsPath);
  final accounts = AccountStore(accountsPath: accountsPath)..load();
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final handler = const Pipeline()
      .addMiddleware(createMiddleware(
        requestHandler: (Request request) {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: _corsHeaders);
          }
          return null;
        },
        responseHandler: (Response response) => response.change(headers: _corsHeaders),
      ))
      .addHandler(buildApiRouter(store: store, imagesDirectory: imagesDirectory, accounts: accounts).call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('pictocomm_backend escuchando en http://localhost:${server.port}');
  print('catálogo: ${store.categories.length} categorías, ${store.pictos.length} pictos');
}

const Map<String, String> _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type',
};
