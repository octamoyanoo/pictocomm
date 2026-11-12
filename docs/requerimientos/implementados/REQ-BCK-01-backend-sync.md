# REQ-BCK-01 — Backend y sync del catálogo (descarga)

**Mockup:** sin mockup propio (funcionalidad de infraestructura; no agrega pantallas)
**Specs vigentes:** [`backend-sync.md`](../../specs/por-aprobar/backend-sync.md)
**Archivos implicados:** `src/backend/` (nuevo paquete Dart), `lib/features/catalog/data/datasources/remote_catalog_data_source.dart`, `.../remote_catalog_cache_data_source.dart` (nuevo), `lib/features/catalog/data/repositories/local_picto_repository.dart`, `lib/core/di/injector.dart`

---

## 1. Objetivo

La app es **local-first**: funciona sin conexión y lee siempre de local. Pero el catálogo que viaja con la app es chico y fijo, y las familias no pueden agregar contenido desde otro lado. Este requerimiento define el **backend mínimo** que sirve un catálogo ampliado y el **sync de solo descarga** con el que la app lo incorpora, sin tocar pantallas ni providers.

Decisiones del usuario: stack del backend = **Dart (shelf)**, un solo lenguaje en todo el repo; persistencia = **seed JSON en memoria**; alcance v1 = **solo descarga** (la app no sube nada todavía).

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-12):

- Backend en `src/backend/` (paquete Dart + shelf): `GET /health`, `GET /api/v1/categories`, `GET /api/v1/pictos` (con filtros) y `GET /api/v1/pictos/{id}`, más imágenes estáticas servidas por el propio server.
- La app descarga el catálogo remoto al arrancar (fire-and-forget), lo cachea en SharedPreferences y lo mergea en lectura; sin conexión, la app sigue funcionando con lo local.
- Los datos remotos se sincronizan incrementalmente por `updatedAt` (`since`): re-sync trae solo lo nuevo/modificado.

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| API del backend | REST JSON: health, categories, pictos (lista/detalle) | **Implementado** |
| Persistencia del backend | Seed JSON versionado en el repo, cargado en memoria al arrancar | **Implementado** |
| Sync incremental | La app pregunta por pictos con `updatedAt > lastSyncAt` | **Implementado** |
| Cache local del remoto | SharedPreferences (claves propias, separadas de las custom) | **Implementado** |
| Merge en lectura | Categorías y pictos remotos aparecen junto a los locales, sin tocar providers | **Implementado** |
| Local-first intacto | Las lecturas nunca tocan la red; offline = catálogo local | **Implementado** |
| Subida de pictos custom | Bidireccional (POST/PUT + conflictos) | Fuera de alcance (v2) |
| Perfiles en el backend | Sync de `ChildProfile` | Fuera de alcance (v2) |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-5.1 | El backend expone una API REST JSON con: `GET /health`, `GET /api/v1/categories`, `GET /api/v1/pictos` y `GET /api/v1/pictos/{id}`. |
| RF-5.2 | `GET /api/v1/pictos` acepta filtros opcionales: `categoryId` (pictos de esa categoría), `since` (solo con `updatedAt` posterior, ISO-8601 UTC) y `limit` (default 100, máx 500). |
| RF-5.3 | El backend sirve su catálogo desde un **seed JSON** versionado en el repo, cargado en memoria al arrancar; no hay base de datos en v1. |
| RF-5.4 | El backend sirve las **imágenes del catálogo remoto** como archivos estáticos (`/images/...`), y el seed referencia esas URLs. |
| RF-5.5 | La app descarga el catálogo remoto **al arrancar** (fire-and-forget, sin bloquear el primer frame ni pantallas). |
| RF-5.6 | El catálogo descargado se guarda en **cache local** (SharedPreferences, claves propias separadas de las custom) y las lecturas posteriores lo sirven **desde local**. |
| RF-5.7 | El sync es **incremental**: la app registra la fecha del último sync y pregunta solo por pictos con `updatedAt` posterior. Re-sync sin cambios no descarga nada nuevo. |
| RF-5.8 | Los pictos y categorías remotas se **mergean en lectura** junto a los locales (bundled + custom + remote), sin duplicar ids. |
| RF-5.9 | Los elementos remotos **no se pueden borrar** desde la app (v1 no sube, así que no tiene sentido borrar en el dispositivo lo que el backend volvería a mandar). |
| RF-5.10 | Si el backend no está disponible (sin conexión, server caído, timeout), el sync **falla en silencio**: la app sigue funcionando con su catálogo local y no muestra errores al usuario. |
| RF-5.11 | La app **nunca toca la red en lecturas** (`getCategories`/`getPictos`/`getPicto`): la única llamada saliente es el sync. Un test lo garantiza con un datasource remoto que explota si se lo toca en lectura. |

## 5. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-5.1 | El backend es un **paquete Dart independiente** (`src/backend/`), sin dependencia del paquete Flutter; comparte el formato JSON de los models del frontend (`PictoModel`/`CategoryModel`). |
| RNF-5.2 | El backend corre con `dart run` desde `src/backend/`, escucha en `localhost:8080` (configurable por variable de entorno `PORT`). |
| RNF-5.3 | La URL del backend en la app es `String.fromEnvironment('PICTOCOMM_BACKEND_URL', defaultValue: 'http://localhost:8080')` (en Android emulador se pasa `http://10.0.2.2:8080`). |
| RNF-5.4 | Toda respuesta HTTP del backend tiene `content-type: application/json` (las imágenes, su mime real). Errores devuelven JSON `{"error": "..."}` con el código HTTP correcto (404 inexistente, 400 filtro inválido). |
| RNF-5.5 | El cliente HTTP de la app tiene **timeout de 10 s** por request; un timeout cuenta como backend no disponible (RF-5.10). |
| RNF-5.6 | Las fechas viajan en ISO-8601 **UTC** en todo el sistema (seed, API, cache), igual que los models del frontend. |
| RNF-5.7 | Los ids del catálogo remoto usan el prefijo `remote-` para no colisionar con bundled/custom. |

## 6. Casos de uso

### UC-01.1 — La app incorpora el catálogo del backend

| | |
|---|---|
| **Actor** | Adulto responsable (indirecto: no ve nada del proceso) |
| **Objetivo** | Que el chico tenga más pictos que los que vienen con la app |
| **Precondiciones** | App instalada; backend corriendo y alcanzable |
| **Disparador** | Arranque de la app |

**Flujo principal:**
1. La app arranca y muestra su catálogo local de siempre (sin esperar la red).
2. En paralelo, la app pide categorías y pictos nuevos al backend (`since` = último sync).
3. La respuesta se cachea localmente y se registra la fecha del sync.
4. Las próximas lecturas muestran bundled + custom + remote.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Backend caído / sin conexión / timeout | Sync silencioso: la app queda con lo local, sin error visible |
| 2 | Primer sync (sin cache) | Descarga el catálogo completo |
| 3 | Re-sync sin cambios | La respuesta viene vacía; la cache no se toca |

**Postcondiciones:** Cache actualizada; catálogo remoto visible para cualquier chico del dispositivo.

### UC-01.2 — El adulto administra el catálogo remoto desde el seed

| | |
|---|---|
| **Actor** | Mantenedor del backend |
| **Objetivo** | Agregar/modificar pictos del catálogo ampliado |
| **Precondiciones** | Repo del backend |
| **Disparador** | Editar `data/seed.json` y reiniciar el server |

**Flujo principal:**
1. Se edita el seed (categorías, pictos, imágenes en `data/images/`).
2. El server se reinicia y carga el seed en memoria.
3. En el próximo sync de cada dispositivo, los pictos con `updatedAt` posterior se descargan.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Seed JSON inválido | El server arranca con catálogo vacío y loguea el error (no crashea) |

**Postcondiciones:** Los dispositivos con la app incorporan los cambios en su próximo arranque.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-5.1 | **Given** el backend corriendo, **when** se pide `GET /api/v1/categories`, **then** responde 200 con todas las categorías del seed en el formato de `CategoryModel`. |
| CA-5.2 | **Given** el backend corriendo, **when** se pide `GET /api/v1/pictos`, **then** responde 200 con todos los pictos del seed en el formato de `PictoModel`. |
| CA-5.3 | **Given** el backend corriendo, **when** se pide pictos con `categoryId`, `since` o `limit`, **then** responde solo los que cumplen los tres filtros; `limit` fuera de rango o `since` no-ISO responden 400. |
| CA-5.4 | **Given** un id inexistente, **when** se pide `GET /api/v1/pictos/{id}`, **then** responde 404 con JSON de error. |
| CA-5.5 | **Given** la app con backend alcanzable, **when** arranca, **then** sincroniza el catálogo y las lecturas muestran bundled + custom + remote sin duplicados. |
| CA-5.6 | **Given** la app con backend no disponible, **when** arranca, **then** el sync falla en silencio y el catálogo local sigue funcionando igual. |
| CA-5.7 | **Given** un sync previo exitoso, **when** se re-sincroniza sin cambios en el backend, **then** no se descarga ningún picto nuevo. |
| CA-5.8 | **Given** un picto remoto cacheado, **when** se intenta borrar, **then** el repositorio lo rechaza (como los bundled). |
| CA-5.9 | **Given** cualquier lectura del repositorio, **when** se ejecuta, **then** nunca toca el datasource remoto (garantizado por test con datasource que explota). |

Cobertura de tests: backend `src/backend/test/` (API y filtros), frontend `test/sync_catalog_test.dart` (sync, cache, merge, borrado rechazado, local-first).

## 8. Fuera de alcance

- **Subida de pictos custom al backend** (bidireccional, POST/PUT, resolución de conflictos por `updatedAt`): v2.
- **Sync de perfiles de niño** (`ChildProfile`): v2.
- **Autenticación / cuentas** (relacionado con `por-aprobar/acceso.md`): sin definir; el backend v1 no tiene auth.
- **Base de datos** (SQLite/MySQL): v1 usa seed en memoria; la migración no debe cambiar el contrato de la API.
- **Búsqueda integrada de imágenes** (Google): v2, heredado de REQ-CAT-01.

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Stack | Confirmado (usuario): Dart + shelf — un solo lenguaje, modelos tipados compartidos con el frontend. |
| 2 | Alcance v1 | Confirmado (usuario): solo descarga; coincide con el contrato de `RemoteCatalogDataSource` ya definido. |
| 3 | Persistencia | Confirmado (usuario): seed JSON en memoria; migrar a DB después no cambia la API. |
| 4 | Disparo del sync | Decisión (mi llamada): al arrancar, fire-and-forget; sin botón ni pantalla hasta que haya algo que mostrar. |
| 5 | Borrado de remotos | Decisión (mi llamada): rechazado en v1 — sin subida, borrar en el dispositivo sería volver a la próxima sync. |
| 6 | Fallo de sync | Decisión (mi llamada): silencioso (local-first); la visibilidad del estado de sync queda para v2. |
| 7 | Prefijo de ids | Decisión (mi llamada): `remote-`, espejo del `custom-` existente. |
