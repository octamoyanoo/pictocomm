# Backend bidireccional: subida del catálogo custom (REQ-BCK-02)

> ⚠️ **Pendiente de aprobar:** funcionalidad recién implementada. El requerimiento normativo es [`REQ-BCK-02-backend-bidireccional.md`](../../requerimientos/implementados/REQ-BCK-02-backend-bidireccional.md).

Funcionalidad que **hace que lo creado en la app (pictos y categorías custom) suba a un backend propio, con reintentos y estado visible para el adulto**, en **PictoComm**. Se apoya en el backend de solo descarga ([`backend-sync.md`](../aprobadas/backend-sync.md)) y es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- La app **sube automáticamente** cada cambio de catálogo custom (crear/editar/borrar picto; crear/editar/borrar categoría) en background, sin bloquear la UI.
- Si el backend no está, el cambio queda en una **cola de salida persistente (outbox)** y sube al arrancar la app, tras cada operación nueva, o con el botón **"Sincronizar ahora"**.
- El backend guarda lo subido en `data/uploads.json` + `data/images/uploads/` (decodifica el base64 de la imagen y la guarda como archivo); **el seed curado nunca se toca**.
- Los conflictos se resuelven **last-write-wins por `updatedAt`**: el server siempre responde con la versión ganadora y la app la adopta (los datos, no la imagen local).
- El **borrado es lógico** (`deletedAt`): los otros dispositivos purgan el item de su cache al recibir la "tumba" en el sync.
- El adulto ve el **estado de sync** (sincronizado / pendiente N / sin conexión) y puede forzar la sincronización desde la pantalla Perfil. El modo chico no ve nada nuevo.
- **Local-first intacto**: si el backend no está, todo funciona igual que siempre y en silencio; las lecturas nunca tocan la red.

## Experiencia de usuario

1. El adulto crea un picto: la app lo guarda local y en el mismo instante lo sube en background. Nada se siente lento.
2. Con dos dispositivos (casa y abuela): lo creado en uno aparece en el otro en el próximo arranque (o con "Sincronizar ahora" en Perfil).
3. Sin WiFi, se crean pictos igual: el indicador del Perfil muestra "Sincronizado, N cambios pendientes de subirse"; cuando vuelve la conexión, suben solos.
4. Borrar un picto o categoría lo saca de **todos** los dispositivos (borrado lógico propagado).
5. Si dos dispositivos editaron lo mismo, gana el que editó más tarde y el otro lo ve actualizado.

## Cómo lo hace (implementación)

### Backend (`src/backend/`)

| Parte | Archivo | Rol |
|---|---|---|
| Store extendido | `lib/src/catalog_store.dart` | Seed (solo lectura) + **uploads** (mutables, persistidos en `data/uploads.json`, mismo formato JSON que el seed con `deletedAt`/`updatedAt` opcionales). Lecturas = merge seed+uploads sin borrados; `isSeedPicto`/`isSeedCategory` protegen el seed |
| API de escritura | `lib/src/api_handler.dart` | `POST`/`PUT`/`DELETE` en `/api/v1/pictos` y `/api/v1/categories` (ver tabla abajo); imágenes subidas → `data/images/uploads/<id>.<ext>`, servidas por `/images/uploads/<archivo>` |
| Imágenes | `data/images/uploads/` | PNG/JPG/WebP decodificados del base64; errores de base64/mime → 400 |
| Tests | `test/upload_test.dart` | 10 tests: alta/edición/borrado, conflictos, tumbas, 400/403/404, persistencia tras "reinicio" |

### API (además de la v1 de solo lectura)

| Endpoint | Respuesta | Notas |
|---|---|---|
| `POST /api/v1/pictos` | 201 con el picto; **409** con la versión guardada si el id ya existe | Body: `id` (`custom-*`, opcional — el server genera si falta), `label`, `categoryIds`, `imageData` (base64), `imageMime`, `updatedAt`, `childProfileId?` |
| `PUT /api/v1/pictos/{id}` | 200 con la versión **ganadora** | Solo pictos subidos (seed → 403, inexistente → 404, tumba → 409); conflictos: si el `updatedAt` entrante no supera al guardado, responde el guardado |
| `DELETE /api/v1/pictos/{id}` | 200 con la **tumba** (`deletedAt`) | Siempre lógico (RNF-5.14); seed → 403; inexistente → 404; idempotente |
| `POST`/`PUT`/`DELETE /api/v1/categories` | Igual semántica | `color` hex `#RRGGBB`; el id es el slug del cliente |
| `GET /api/v1/pictos?since=` | Incluye **tumbas recientes** (`deletedAt` > since) | Para que cada dispositivo purgue su cache (RF-5.14) |
| `GET /api/v1/categories` | Incluye tumbas siempre | Categorías son pocas; viajan para purgar (RF-5.15) |
| `GET /images/uploads/<archivo>` | PNG/JPG/WebP | Mime real, cache 1 día |

Serialización: lo subido sale como `source: "remote"` con `imageUrl` absoluta y el **id `custom-*` intacto** (RNF-5.15) — así renderiza con `Image.network` en los otros dispositivos y el dispositivo dueño lo dedup contra su copia local.

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Cliente HTTP | `.../datasources/http_remote_catalog_data_source.dart` | 6 operaciones de subida nuevas; 200/201/409 devuelven la versión (ganadora) del server; 404 en deletes = "ya no existe" (tumba sintética); timeout 10 s |
| Outbox | `.../datasources/remote_outbox_data_source.dart` | Cola persistente (`pictocomm.outbox_ops`); dedup por (kind, id) — siempre viaja la última versión; `remove` matchea kind+id+**op** (evita carreras post→delete) |
| Repositorio | `.../repositories/local_picto_repository.dart` | `createPicto`/`updatePicto`/`deletePicto`/`createCategory`/`updateCategory`/`deleteCategory` encolan y disparan `flushOutbox()` (fire-and-forget); `flushOutbox()` procesa FIFO y corta en silencio si el backend falla; `syncNow()` = flush + descarga; purga de tumbas en el sync; adopción de conflictos (datos del server, imagen local se conserva); `lastSyncFailed` para el indicador |
| Estado de sync | `lib/features/sync/sync_service.dart` | `SyncService` (ChangeNotifier): `idle/syncing/synced/pending(N)/offline`; `bootstrap()` al arrancar; `markDirty()` vía callback del repositorio |
| UI | `lib/features/sync/presentation/sync_status_card.dart` en la pantalla Perfil | Indicador + botón "Sincronizar ahora"; **solo modo adulto** |
| Wiring | `lib/core/di/injector.dart`, `lib/app.dart` | `AppDependencies.catalogRepository` (concreto, nullable para fakes); el servicio se provee global y arranca el sync en background |
| Tests | `test/sync_upload_test.dart` | 9 tests: subida, legacy sin dueño, outbox + recuperación, conflicto adoptado, tumba propagada, reintento tras error, dedup RF-5.18, categorías, estados del servicio |

### Flujo paso a paso (subida)

1. El adulto crea/edita/borra un picto custom (con dueño): el repositorio persiste local y **encola** la op (`post`/`put`/`delete`) con el `PictoModel` completo.
2. Se dispara `flushOutbox()` sin await: si el backend está, sube en orden; cada op confirmada se saca de la cola.
3. Si el backend no está, la op queda y se reintenta al arrancar (bootstrap), tras la próxima operación, o con el botón del Perfil.
4. En un 409, la respuesta del server (versión ganadora) se **adopta en los datos** (label, categorías) conservando la imagen local data URL del dueño.
5. El sync de descarga del otro dispositivo recibe la tumba (o el picto nuevo) y purga/agrega en su cache.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Backend caído / sin conexión / timeout | Op queda en outbox; silencio total (RF-5.10) |
| Backend responde 400/403 | Op queda en el outbox (no se descarta, CA-5.18) |
| DELETE de algo que el server no tiene | 404 → tratado como éxito (ya no existe) |
| Dos dispositivos editan lo mismo | Last-write-wins por `updatedAt`; el perdedor adopta los datos |
| Picto legacy sin dueño | No sube ni al borrar (nunca existió en el server) |
| Seed curado | `PUT`/`DELETE` sobre ids del seed → 403; nunca sale de la app |
| Reinicio del server | `data/uploads.json` recarga lo subido; seed intacto (CA-5.19) |
| Caché con id `custom-*` que ya existe local | Descartada en lectura (gana la copia local, RF-5.18) |
| Cambio mientras el flush volaba (post → delete) | El `remove` del outbox matchea por op: la versión nueva no se pierde |

## Limitaciones conocidas

- **Sin auth** (pendiente `por-aprobar/acceso.md`): los endpoints de escritura están abiertos como los de lectura; v3 evaluará token.
- **Perfiles no se sincronizan** (v3): un picto con dueño viaja con su `childProfileId`; si el otro dispositivo no tiene ese id de perfil, el picto queda invisible ahí hasta el sync de perfiles.
- **`updatedAt` de categorías usa el reloj del flush**: las categorías custom no llevan timestamp propio; dos ediciones simultáneas de categoría eligen por orden de subida, no por orden de edición.
- **El PUT re-envía la imagen** (base64) aunque no cambiara: simple, pero gasta tráfico; optimizable con etag/hash.
- **Consistencia eventual**: no hay push/realtime; lo nuevo del otro dispositivo llega al arrancar o con "Sincronizar ahora".
- Sin límite de tamaño de imagen subida (hereda la pregunta abierta de REQ-CAT-01).

---

Volver a [`0000-index.md`](../0000-index.md).
