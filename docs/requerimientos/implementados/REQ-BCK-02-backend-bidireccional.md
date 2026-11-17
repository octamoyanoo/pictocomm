# REQ-BCK-02 — Backend bidireccional (subida del catálogo custom)

**Mockup:** sin mockup propio (infraestructura + un indicador discreto en modo adulto)
**Specs vigentes:** (por aprobar: [`backend-bidireccional.md`](../../specs/por-aprobar/backend-bidireccional.md))
**Archivos implicados:** `src/backend/bin/server.dart`, `src/backend/lib/src/`, `src/backend/data/` (uploads), `src/backend/test/`, `lib/features/catalog/data/datasources/remote_catalog_data_source.dart`, `.../remote_catalog_cache_data_source.dart` (+ outbox), `.../repositories/local_picto_repository.dart`, `.../presentation/providers/` (estado de sync), `lib/core/di/injector.dart`

---

## 1. Objetivo

REQ-BCK-01 dejó el pipeline de solo descarga: un dispositivo **recibe** el catálogo ampliado pero lo que la familia crea en la app (los pictos de la casa) **no sale del dispositivo**. Con dos o más dispositivos (casa, abuela, escuela), cada uno termina con un catálogo distinto. Este requerimiento define la **subida** de catálogo custom: alta, edición y borrado lógico de pictos y categorías custom al backend, con cola de reintentos para conexión intermitente e **indicador de estado de sync** para el adulto.

Decisiones del usuario:

- **CRUD completo**: alta, edición de nombres (y lo demás del picto) y borrado — coincide con lo que la UI de la app permite tras REQ-CAT-02.
- **Persistencia**: archivo de **uploads aparte** (`data/uploads.json` + `data/images/uploads/`); el seed curado no se toca.
- **Imágenes**: el server decodifica el base64 y **guarda archivo** propio.
- **Disparo**: Opción C — fire-and-forget + **reintentos al arrancar** + **UI de estado de sync**.
- **Alcance**: suben pictos **y categorías** custom (multi-categoría de REQ-CAT-02 incluida).

## 2. Estado actual

Implementado (REQ-BCK-01, estado al 2026-11-16):

- API de solo lectura (`GET /health`, `/api/v1/categories`, `/api/v1/pictos[/{id}]`, `/images/*`) sobre seed JSON en memoria.
- Sync de descarga al arrancar (incremental por `updatedAt`), cache en SharedPreferences, merge en lectura, fallo silencioso.
- El repositorio **rechaza** borrar remotos (RF-5.9); el sync solo corre al arrancar; no hay subida ni estado visible.
- Formato JSON compartido `PictoModel`/`CategoryModel` (v1: `categoryId` único; REQ-CAT-02 lo cambia a `categoryIds`).

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| API de escritura | `POST`/`PUT`/`DELETE` en `/api/v1/pictos` y `/api/v1/categories` | **A implementar** |
| Persistencia de subidas | `data/uploads.json` (mismo formato que el seed) + `data/images/uploads/` | **A implementar** |
| Imágenes subidas | Base64 → archivo en el server; `imageUrl` absoluta en respuestas | **A implementar** |
| Borrado lógico | `deletedAt`; `GET` lista excluye borrados; el sync entrega tumbas para purgar cache | **A implementar** |
| Conflictos | Last-write-wins por `updatedAt` (ISO-8601 UTC) | **A implementar** |
| Cola de salida (outbox) | Cambios pendientes en SharedPreferences; flush al arrancar y tras cada cambio | **A implementar** |
| UI de estado de sync | Indicador + "sincronizar ahora" en modo adulto; invisible para el chico | **A implementar** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-5.12 | `POST /api/v1/pictos`: alta de picto custom con `imageData` (base64 + mime) y `categoryIds` (REQ-CAT-02). El server guarda el archivo en `data/images/uploads/` y responde 201 con el picto (`source: "remote"`, `imageUrl` absoluta). Faltante/inválido → 400; id ya existente → 409 con la versión guardada. |
| RF-5.13 | `PUT /api/v1/pictos/{id}`: edición de nombre, categorías y/o imagen. Conflicto por `updatedAt`: el server conserva siempre la versión más nueva y responde con ella (la app adopta la respuesta). Id inexistente → 404. |
| RF-5.14 | `DELETE /api/v1/pictos/{id}`: **borrado lógico** (marca `deletedAt`, el archivo de imagen puede conservarse). El listado `GET` excluye los borrados; el sync incremental devuelve los recientemente borrados con `deletedAt` para que cada dispositivo purgue su cache. |
| RF-5.15 | Ídem para categorías: `POST`/`PUT`/`DELETE /api/v1/categories` (borrado lógico incluido). |
| RF-5.16 | La app **sube automáticamente** los cambios de catálogo custom (crear/editar picto o categoría) en background, sin bloquear la UI: fire-and-forget al momento + outbox. Los bundled y los remote del **seed** nunca se suben ni se borran desde la app (RF-5.9 sigue vigente para ellos). Los pictos legacy sin dueño (RF-3.7) no suben hasta que se les asigne chico. |
| RF-5.17 | **Outbox con reintentos**: si la subida falla (backend caído, sin conexión, timeout), el cambio queda en una cola persistente y se reintenta al arrancar la app y tras cada operación nueva (flush encadenado). Nada se pierde por conexión intermitente. |
| RF-5.18 | Al sincronizar hacia abajo, un item del cache remoto cuyo id ya existe como custom local **se descarta** (gana el local): el dispositivo dueño mantiene su copia offline; los otros dispositivos lo reciben como remote. |
| RF-5.19 | **UI de estado de sync** (solo modo adulto): indicador con los estados *sin sincronizar / sincronizando / todo sincronizado / pendiente (N) / sin conexión* y botón **"Sincronizar ahora"** que dispara descarga + flush de subida en el momento. No agrega nada visible en modo chico. |
| RF-5.20 | El botón "Sincronizar ahora" ejecuta la misma rutina que el arranque (descarga incremental + flush del outbox) y actualiza el indicador al terminar. |

## 5. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-5.8 | Persistencia de subidas: `data/uploads.json` con el **mismo formato JSON que el seed** (`categories` + `pictos`, con `deletedAt` opcional); el server lo carga al arrancar y lo reescribe en cada escritura. `seed.json` queda intocable. |
| RNF-5.9 | Imágenes subidas: el server valida mime (`image/png|jpeg|webp`), decodifica el base64 y guarda `data/images/uploads/<id>.<ext>`; base64 corrupto → 400. Las respuestas siempre sirven la imagen por `/images/uploads/...`. |
| RNF-5.10 | Conflictos: last-write-wins por `updatedAt` UTC; sin relojes del server en el dato (el `updatedAt` lo porta el cliente). |
| RNF-5.11 | El outbox vive en SharedPreferences (claves `pictocomm.outbox_*`, separadas del cache de descarga); el flush corre en background (`unawaited`) y sus errores son silenciosos: la cola persiste para el próximo intento. |
| RNF-5.12 | El estado de sync es observable (provider) y alimenta la UI; todo texto nuevo va a i18n (es/en/pt). |
| RNF-5.13 | Sin auth (pendiente `por-aprobar/acceso.md`): los endpoints de escritura quedan abiertos como los de lectura; v3 evaluará token. |
| RNF-5.14 | El borrado es **siempre** lógico; ninguna operación destruye datos ya subidos (el archivo de imagen puede quedarse). |
| RNF-5.15 | Los ids de items subidos mantienen el prefijo `custom-` del cliente; el server no reasigna ids (evita duplicar el picto en el dispositivo dueño tras el primer sync). |

## 6. Casos de uso

### UC-02.1 — La familia comparte un picto entre dispositivos

| | |
|---|---|
| **Actor** | Adulto responsable (indirecto el chico) |
| **Objetivo** | Que lo creado en un dispositivo aparezca en los otros |
| **Precondiciones** | Dos dispositivos con la app; backend alcanzable en algún momento |
| **Disparador** | Crear/editar/borrar un picto o categoría custom |

**Flujo principal:**
1. El adulto crea (o edita) un picto custom: la app lo persiste local y encola la subida, sin bloquear la pantalla.
2. En background la app hace `POST`/`PUT` al backend; el server guarda imagen y dato en `uploads.json`.
3. El otro dispositivo sincroniza al arrancar (o con "Sincronizar ahora"): baja el picto como remote y lo muestra.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Backend caído al momento del cambio | El cambio queda en el outbox; se sube en el próximo arranque o flush (UC-02.2) |
| 2 | Borrado | `DELETE` lógico; los otros dispositivos purgan el item al recibir la tumba (RF-5.14) |
| 3 | Dos dispositivos editaron lo mismo | Gana el `updatedAt` más nuevo; ambos adoptan la versión ganadora (RF-5.13) |
| 4 | Seed curado vs subida | Conviven: el seed es de solo lectura para todos (RF-5.16) |

**Postcondiciones:** Catálogo custom eventualmente consistente en todos los dispositivos.

### UC-02.2 — Reintento después de estar sin conexión

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Que lo creado sin WiFi llegue al backend |
| **Precondiciones** | Outbox con cambios pendientes |
| **Disparador** | Arranque de la app, operación nueva, o tap en "Sincronizar ahora" |

**Flujo principal:**
1. Al arrancar (y tras cada operación), la app intenta vaciar el outbox contra el backend.
2. Si el backend responde, los cambios se suben en orden y el indicador pasa a "todo sincronizado".
3. Si sigue caído, silencio: la cola espera el próximo intento.

**Flujos alternativos:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Conflicto con una versión más nueva ya subida | El server responde con la versión ganadora y la app descarta la suya |

**Postcondiciones:** Outbox vacío y backend actualizado, o outbox intacto esperando.

### UC-02.3 — El adulto ve el estado de sync

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Saber si el catálogo está sincronizado (o forzarlo) |
| **Precondiciones** | Modo adulto |
| **Disparador** | Mirar el indicador; tap en "Sincronizar ahora" |

**Flujo principal:**
1. El indicador muestra el estado actual (pendiente N, sincronizando, sincronizado, sin conexión).
2. Con tap, corre descarga + flush y el indicador refleja el resultado.

**Postcondiciones:** El adulto tiene certeza del estado; el chico no ve nada nuevo.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-5.10 | **Given** el backend corriendo, **when** la app crea un picto custom con imagen, **then** el server responde 201, guarda el archivo en `data/images/uploads/` y el picto queda servible por `GET /api/v1/pictos` con `imageUrl` absoluta. |
| CA-5.11 | **Given** un picto ya subido, **when** la app lo edita (nombre/categorías/imagen), **then** `PUT` actualiza y el `updatedAt` refleja la edición más nueva. |
| CA-5.12 | **Given** dos ediciones del mismo picto con `updatedAt` distintos, **when** llega la más vieja después, **then** el server conserva la más nueva y responde con ella (la app la adopta). |
| CA-5.13 | **Given** un picto subido, **when** se borra desde la app, **then** el server lo marca `deletedAt`, `GET` ya no lo lista y los otros dispositivos lo purgan de su cache en el próximo sync. |
| CA-5.14 | **Given** la app sin backend disponible, **when** se crea/edita/borra, **then** el cambio queda en el outbox y se sube en el próximo arranque o flush sin intervención. |
| CA-5.15 | **Given** el outbox con pendientes, **when** se tipea "Sincronizar ahora" con backend disponible, **then** se vacía la cola y el indicador pasa a "todo sincronizado". |
| CA-5.16 | **Given** modo chico, **when** se navega por las pantallas, **then** no aparece ningún elemento de la UI de sync. |
| CA-5.17 | **Given** el cache remoto con un picto cuyo id ya existe como custom local, **when** se lee el catálogo, **then** no hay duplicado (gana el local, RF-5.18). |
| CA-5.18 | **Given** una subida con base64 corrupto o campos faltantes, **when** llega al server, **then** responde 400 con `{"error": ...}` y la app lo deja en el outbox (no lo descarta). |
| CA-5.19 | **Given** un reinicio del server, **when** arranca, **then** carga seed + uploads (lo subido sobrevive) sin tocar `seed.json`. |

Cobertura de tests (prevista): backend `src/backend/test/` (CRUD, conflictos, tumbas, persistencia de uploads, reinicio), frontend `test/` (outbox, flush, dedup RF-5.18, indicador, purge por `deletedAt`), con fakes al nuevo contrato.

## 8. Fuera de alcance

- **Autenticación**: los endpoints de escritura quedan abiertos hasta decidir `acceso.md` (v3).
- **Sync de perfiles** (`ChildProfile`): sigue en v3 — sin esto, los pictos subidos por chico se muestran según su `childProfileId` idéntico en ambos dispositivos (misma instalación exportada) o quedan visibles para todos si no hay match.
- **Buscador de imágenes (Google)**: v3.
- **Push/realtime**: la consistencia es eventual (arranque + botón manual); no hay notificaciones del server.
- **Compresión/redimensionado de imágenes** antes de subir: se sube el data URL tal cual la app lo guarda hoy.
- **Dashboard web** de administración del catálogo: el seed se sigue curando a mano en el repo.

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Alcance de escritura | Confirmado (usuario): CRUD completo de pictos (alta, edición, borrado) + categorías custom. |
| 2 | Persistencia | Confirmado (usuario): `uploads.json` aparte + `data/images/uploads/`; seed intocable. |
| 3 | Imágenes | Confirmado (usuario): el server guarda archivo (decodifica base64); la API nunca viaja con base64 de ida y vuelta. |
| 4 | Disparo | Confirmado (usuario): Opción C — fire-and-forget + reintentos al arrancar **y** UI de estado de sync con botón manual. |
| 5 | Alcance de subida | Confirmado (usuario): pictos **y** categorías custom; formato multicategoría de REQ-CAT-02. |
| 6 | Conflictos | Decisión (mi llamada): last-write-wins por `updatedAt`; el server siempre responde con la versión ganadora y la app la adopta. |
| 7 | Borrado | Decisión (mi llamada): siempre lógico (`deletedAt`), propagado por el sync; RF-5.9 sigue vigente para el seed. |
| 8 | Ids | Decisión (mi llamada): el server respeta el id `custom-*` del cliente; en lecturas lo sirve como `remote` para que renderice con `Image.network` en los otros dispositivos. |
| 9 | Legacy sin dueño | Decisión (mi llamada): no suben hasta que RF-3.19 les asigne chico (evita publicar pictos sin dueño a toda la familia). |
| 10 | UI de sync | Decisión (mi llamada): indicador + botón solo en modo adulto; el modo chico queda intacto (invisible por diseño). |
