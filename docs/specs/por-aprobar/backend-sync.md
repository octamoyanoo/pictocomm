# Backend y sync del catálogo (descarga)

> ⚠️ **Pendiente de aprobar:** funcionalidad recién implementada. Falta revisarla contra el código (v1 del backend + sync de descarga). El requerimiento normativo es [`REQ-BCK-01-backend-sync.md`](../../requerimientos/implementados/REQ-BCK-01-backend-sync.md).

Funcionalidad que **descarga un catálogo ampliado desde un backend propio y lo mergea con lo que ya tiene la app, sin tocar pantallas ni providers** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- Hay un **backend Dart (shelf)** en `src/backend/` que sirve el catálogo remoto: categorías + pictos + imágenes, desde un **seed JSON** versionado en el repo (sin base de datos en v1).
- La app **sincroniza al arrancar** (fire-and-forget): pide solo lo nuevo desde el último sync (`updatedAt` > `since`), cachea la respuesta en SharedPreferences y avanza la fecha.
- El catálogo remoto se **mergea en lectura** junto a bundled + custom: mismas pantallas, mismas grillas. Los pictos remotos renderizan su imagen con `Image.network` (`PictoSource.remote` ya estaba contemplado).
- **Local-first intacto**: si el backend no está (sin conexión, server caído, timeout), el sync falla en silencio y la app funciona exactamente igual que antes. Las lecturas nunca tocan la red.
- Los elementos remotos **no se pueden borrar** desde la app (v1 no sube nada, así que borrar sería volver a descargarlo en la próxima sync).

## Experiencia de usuario

Es una funcionalidad **invisible por diseño**: no agrega pantallas, botones ni estados visibles.

1. El adulto instala la app y la abre: ve el catálogo local de siempre (la app no espera la red para el primer frame).
2. En segundo plano, la app sincroniza con el backend; si estaba disponible, al volver a abrir (o al recargar el catálogo) aparecen las categorías y pictos nuevos — v1 del seed: **Lugares** y **Rutina**, más pictos extra en **Alimentos** y **Emociones**.
3. Si el server no estaba, no pasa nada raro: sin errores, sin avisos, todo como siempre.

## Cómo lo hace (implementación)

### Backend (`src/backend/`, paquete Dart puro — sin Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Server | `bin/server.dart` | `shelf_io.serve` en `localhost:8080` (env `PORT`); carga el seed y monta la API con CORS abierto |
| Store | `lib/src/catalog_store.dart` | Parsea `data/seed.json` a memoria (`SeedCategory`/`SeedPicto`); seed inválido → catálogo vacío, no crash |
| API | `lib/src/api_handler.dart` | Router con los endpoints de abajo; serializa pictos con `source: "remote"` y `imageUrl` **absoluta** (construida del request) |
| Seed | `data/seed.json` | 2 categorías (lugares, rutina) + 9 pictos (4 lugares, 3 rutina, agua en alimentos, cansado en emociones); fechas ISO-8601 UTC |
| Imágenes | `data/images/*.png` | PNG 256×256 servidos como estáticos con mime real y cache de 1 día |
| Tests | `test/api_test.dart` | 13 tests: seed, filtros, 400/404, formatos, imágenes |

### API

| Endpoint | Respuesta | Notas |
|---|---|---|
| `GET /health` | `{"status": "ok"}` | |
| `GET /api/v1/categories` | `{"categories": [...]}` | Formato de `CategoryModel`: `color` hex `#RRGGBB`, `custom: false` |
| `GET /api/v1/pictos` | `{"pictos": [...]}` | Filtros: `categoryId`, `since` (ISO, estricto `>`), `limit` (default 100, 1..500); inválidos → 400 |
| `GET /api/v1/pictos/{id}` | picto o `{"error": ...}` (404) | Formato de `PictoModel` |
| `GET /images/<archivo>` | PNG | Del propio server; `imageUrl` del seed apunta acá |

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Cliente HTTP | `lib/features/catalog/data/datasources/http_remote_catalog_data_source.dart` | Implementa `RemoteCatalogDataSource` con `package:http`; timeout 10 s; errores → `DataSourceException`. URL: `--dart-define=PICTOCOMM_BACKEND_URL` (default `http://localhost:8080`; en emulador Android, `http://10.0.2.2:8080`) |
| Cache | `.../remote_catalog_cache_data_source.dart` | SharedPreferences con claves propias (`pictocomm.remote_*`, separadas de las custom); upsert por id; guarda `lastSyncAt` |
| Sync + merge | `.../repositories/local_picto_repository.dart` | `syncFromRemote()`: categorías + pictos paginados (página 100) desde `since`; mergea en `getCategories`/`getPictos` con dedup por id; visibilidad igual que custom |
| Wiring | `lib/core/di/injector.dart` | `bootstrap()` reemplaza el stub por `HttpRemoteCatalogDataSource` y lanza `unawaited(syncFromRemote())` |
| Tests | `test/sync_catalog_test.dart` | 10 tests: merge, incremental, paginado, caída silenciosa, no-borrable, local-first, cache, HTTP client, visibilidad |

### Flujo paso a paso (sync)

1. `AppDependencies.bootstrap()` crea `LocalPictoRepository` con el remote real y llama `syncFromRemote()` **sin await**: la app arranca igual con o sin backend.
2. El repo pide `GET /api/v1/categories` (siempre completo, son pocas) y `GET /api/v1/pictos?since=<lastSyncAt>&limit=100`.
3. Si la página viene completa (100), vuelve a pedir con `since` = mayor `updatedAt` recibido (el backend no borra pictos en v1, así que el cursor es monótono).
4. Guarda en SharedPreferences con **upsert por id** y anota `lastSyncAt` = mayor `updatedAt` recibido (si no llegó nada, conserva la anterior).
5. Lecturas (`getCategories`/`getPictos`/`getPicto`) devuelven bundled + custom + **remote cacheado**; los ids remotos (`remote-*`) no colisionan y una categoría remota con id igual a una local se descarta (gana la local).
6. Si cualquier paso falla (`DataSourceException`, timeout, JSON inválido), el sync termina sin error ni log visible: el estado queda como estaba.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Primer sync (sin cache) | `since` = epoch → descarga el catálogo completo |
| Re-sync sin cambios | Respuesta vacía; cache y `lastSyncAt` no se tocan |
| Backend caído / sin conexión | Sync silencioso; catálogo local intacto (RF-5.10) |
| Timeout (>10 s) | Igual que backend caído |
| `since`/`limit` inválidos en la API | 400 con `{"error": ...}` |
| Picto remoto inexistente | 404 con `{"error": ...}` |
| Borrar picto/categoría remota | Rechazado por el repositorio (mismo camino que los bundled) |
| Categoría custom duplicada contra una remota | `DuplicateCatalogException` (el merge entra en la detección de duplicados) |
| Seed JSON inválido | El server arranca con catálogo vacío y loguea el error |
| Cache remota corrupta | Se descarta el cache; la app sigue con lo local |
| Picto remoto con dueño (futuro) | Misma regla de visibilidad que los custom (solo su chico) |

## Limitaciones conocidas

- **Solo descarga**: los pictos custom del dispositivo no suben al backend (v2, bidireccional con conflictos por `updatedAt`).
- **El backend no borra**: no hay endpoint de borrado; quitar un picto del seed no lo saca de los dispositivos ya sincronizados (v2 necesitará borrado lógico o `deletedAt`).
- **Sin auth**: la API es abierta; atado a la decisión pendiente del spec de `acceso.md`.
- **Cursor por `updatedAt`**: si el backend enviara más pictos de los que entran en una página *con el mismo timestamp cortado a la mitad*, se perderían; hoy el seed no lo provoca (timestamps únicos por lote).
- **El sync solo corre al arrancar**: no hay pull-to-refresh ni indicador de estado (v2, si hace falta).
- **Imágenes placeholder**: los PNG del seed son generados (texto sobre color); reemplazables sin tocar código.

---

Volver a [`0000-index.md`](../0000-index.md).
