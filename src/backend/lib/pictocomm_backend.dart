/// Backend de PictoComm (REQ-BCK-01): API REST del catálogo remoto.
///
/// Exporta las piezas para tests y reuso; para correr el server:
/// `dart run bin/server.dart` desde `src/backend/`.
library;

export 'src/account_store.dart' show AccountStore, StoredAccount, StoredSession;
export 'src/api_handler.dart' show buildApiRouter, defaultPictosLimit, maxPictosLimit;
export 'src/catalog_store.dart' show CatalogStore, SeedCategory, SeedPicto;
