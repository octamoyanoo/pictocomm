# AGENTS.md

## Project Status

App Flutter (local-first) para comunicación por imágenes en niños autistas no verbales de 2-5 años.

Frontend definido y verificado. **Backend v1 (REQ-BCK-01, solo descarga) aprobado**: `src/backend/` es un paquete Dart (shelf) que sirve el catálogo remoto desde un seed JSON; la app lo sincroniza al arrancar y lo mergea local (spec en `docs/specs/aprobadas/backend-sync.md`). **v2 aprobado (REQ-CAT-02 + REQ-BCK-02, specs en `aprobadas/`)**: pictos multicategoría (`categoryIds`) + edición de custom, y subida bidireccional (POST/PUT/DELETE, `data/uploads.json`, outbox con reintentos, borrado lógico con tumbas, indicador de sync en Perfil). **Auth (REQ-ACC-01, aprobado, spec en `aprobadas/`)**: cuentas reales con `/api/v1/auth/*` (`data/accounts.json`, PBKDF2 + token opaco de 30 días), sesión recordada (la app abre directo en el selector), logout en Perfil y perfiles de chico tageados con `accountId`.

**Cierre v2 (2026-11-17)**: decisiones abiertas resueltas — la voz (TTS) sigue el idioma de la UI (`setLanguage` en `VoiceProvider`, RF-1.11); las imágenes custom se comprimen al entrar (`CustomImageCompressor`, máx. 1024px, cierra REQ-CAT-01 #1); el selector preselecciona el último chico activo de la cuenta (sin entrar automático, cierra REQ-PER-01 #1/#2); el karaoke del Play es normativo (cierra REQ-COM-01 #1); los endpoints de escritura del backend quedan abiertos **por decisión** (aceptado para demo local, mejora futura v3). Catálogo con pictogramas reales (31 en frontend + 13 en el seed del backend) y README completo. **Etiquetas multilingües resueltas (v3, REQ-IDI-01 #1)**: `Picto.labels`/`Category.names` (mapa `idioma → texto`, base español como fallback), manifiesto `assets/catalog_labels.json` para el bundled, `labels`/`names` en el seed del backend (con `updatedAt` bump-eado) y en la API de subida; la búsqueda encuentra por cualquier idioma; los custom del adulto no se traducen. Queda pendiente (v3, documentado): reordenamiento de frase, token de escritura del backend, deploy del backend.

## Objetivo del Proyecto

Ver [overview.md](overview.md) para detalles del propósito y alcance del proyecto.

## Ubicación del código

- **frontend (app Flutter)**: `src/frontend/`
- **backend (API del catálogo remoto + cuentas)**: `src/backend/` — paquete **Dart puro** (sin Flutter): `bin/server.dart` (server shelf), `lib/src/` (store del seed + store de cuentas + router de la API), `data/seed.json` + `data/images/` (el catálogo) + `data/accounts.json` (cuentas y sesiones, se crea al primer registro), `test/`. Corre con `dart run bin/server.dart` desde esa carpeta.

## Arquitectura: Clean Architecture ligera por features

Clean Architecture *por feature*, no por capa global. Cada feature es vertical y autonomous; agregar una feature nueva no obliga a tocar las existentes.

```
lib/
├── main.dart                  # Bootstrap: bindings + orientación portrait
├── app.dart                   # PictoCommApp (recibe AppDependencies) + AppRouter
├── core/                      # Transversal, no pertenece a ninguna feature
│   ├── constants/app_routes.dart
│   ├── di/injector.dart       # AppDependencies: el composition root
│   ├── error/app_exception.dart
│   └── theme/app_theme.dart
└── features/
    ├── catalog/               # Categorías + pictos
    │   ├── domain/            # Entidades + interfaces de repositorio (puro)
    │   ├── data/              # models (JSON) + datasources + repos + mappers
    │   └── presentation/      # providers + screens + widgets
    └── profiles/              # Perfiles de niños (misma estructura)
```

### Reglas de dependencia (van en una sola dirección)

```
presentation  →  domain  ←  data
```

- `domain/` no importa nada de Flutter salvo `dart:ui` (`Color`). No sabe qué son assets, ni SharedPreferences, ni HTTP.
- `presentation/` depende de las **interfaces** de `domain/`, nunca de `data/`.
- `data/` implementa las interfaces de `domain/` y traduce excepciones.
- `core/` no importa features.

### Terminos de dominio

| Concepto | Clase | Nota |
|---|---|---|
| Imagen que toca el niño | `Picto` | Antes se llamaba `ImageItem`. **No usar `Symbol`**: colisiona con `dart:core.Symbol`. |
| De dónde sale la imagen | `PictoSource` | enum `bundled` / `custom` / `remote` |
| Grupo de pictos | `Category` | |
| Niño usuario | `ChildProfile` | Varios niños por dispositivo; `accountId` = cuenta dueña (null = legacy) |
| Adulto responsable | `UserAccount` | Cuenta del backend; el dispositivo solo guarda la `AuthSession` |

`PictoSource` existe para evitar el `if (isLocal) Image.file else Image.asset` disperso por los widgets: el `switch` queda en un solo lugar (`PictoCard`).

## Backend (v1: sync de solo descarga, REQ-BCK-01)

La app es **local-first**: lee SIEMPRE de local y funciona sin conexión. Sigue vigente ahora que el backend existe.

- `RemoteCatalogDataSource` define el contrato del backend. La implementación real es `HttpRemoteCatalogDataSource` (URL por `--dart-define=PICTOCOMM_BACKEND_URL`, default `http://localhost:8080`).
- El sync corre en `AppDependencies.bootstrap()` con `unawaited(syncFromRemote())`: incremental por `updatedAt`, cacheado en SharedPreferences (`pictocomm.remote_*`, claves separadas de las custom) y mergeado en lectura por `LocalPictoRepository`. **Nunca agregar lecturas que toquen el remote**: solo el sync.
- El sync falla en silencio (RF-5.10): backend caído = app normal.
- Los modelos de `data/models/` comparten formato JSON con el seed/API del backend; cambiar un campo exige actualizar `src/backend/data/seed.json` y `lib/src/` del backend.
- `test/helpers/fakes.dart` incluye `ExplodingRemoteDataSource`: falla ruidosamente si algún camino de **lectura** toca el remoto. Si un test lo dispara, hay un bug de local-first. `FakeRemoteCatalogDataSource` simula el backend para tests del sync.
- `Picto` ya tiene `createdAt`/`updatedAt`; la subida de pictos custom (bidireccional) es v2.

## Cuentas y acceso (REQ-ACC-01)

- Endpoints: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/auth/me` (Bearer), `POST /api/v1/auth/logout`. Persistidos en `data/accounts.json` (cuentas con hash PBKDF2-HMAC-SHA256 + sesiones con token opaco de 30 días; sobreviven reinicios).
- El frontend tiene feature `auth/` completa (`domain`/`data`/`presentation`): `AuthRepository` → `LocalAuthRepository` (único camino al remote de auth), sesión recordada en SharedPreferences (`pictocomm.auth_session`, sin contraseña). La pantalla inicial es el `AuthGate` en `app.dart` (home, no ruta): splash → login → selector según el estado del `AuthProvider`.
- **El login es la única cosa que necesita red en el primer uso**; con sesión recordada la app abre sin conexión (el cache vale mientras el token no venció). El éxito de login/registro NO navega: cambia el estado y el `AuthGate` se reconstruye.
- Los `ChildProfile` llevan `accountId` (RF-6.6): `getChildren({accountId})` filtra por cuenta + los legacy sin cuenta; `createChild(child, {accountId})` tagea. `ChildrenProvider` recibe la cuenta del `AuthProvider` (inyectada en `AppRouter`).
- La ruta `/` es el `AuthGate`: **no reemplazarla** (`pushReplacementNamed` desde el selector rompería el logout). Logout = `AuthProvider.logout()` + `SessionProvider.clear()` + `popUntil(isFirst)`.
- Tests de auth: `test/auth_test.dart` (frontend, con `FakeAuthRepository` que permite inyectar errores por email) y `test/auth_test.dart` del backend (`src/backend/test/auth_test.dart`).

## Documentación: flujo specs ↔ requerimientos

La documentación funcional tiene dos capas con roles distintos (convenio tomado del repo ControlStock):

| Capa | Carpeta | Qué define | Cuándo se toca |
|---|---|---|---|
| **Requerimiento** | `docs/requerimientos/implementados/REQ-<MOD>-NN-<slug>.md` | **Qué debe hacer** (normativa, referencia de verdad): RF/RNF, casos de uso, criterios de aceptación Given/When/Then | Antes de implementar; se corrige si la decisión cambia |
| **Spec de usuario** | `docs/specs/aprobadas/` y `docs/specs/por-aprobar/` | **Cómo lo hace hoy** (descripción real del código): comportamiento, archivos, validaciones, limitaciones | Después de implementar o al cambiar una funcionalidad |

- El índice de funcionalidades es [`docs/specs/0000-index.md`](docs/specs/0000-index.md): toda funcionalidad con spec está listada ahí, con link. Un spec nuevo arranca en `por-aprobar/` y pasa a `aprobadas/` cuando se revisó contra el código.
- Cada REQ referencia sus specs vigentes en el header, y cada spec referencia su REQ (o marca que no existe). `aprobadas/acceso.md` (REQ-ACC-01) pasó a aprobadas el 2026-11-17 tras la revisión contra el código.
- **Regla de actualización**: cambiar una funcionalidad = actualizar el REQ primero (si cambia la normativa) y luego su spec. Si el código y el spec difieren, es un bug o un spec desactualizado: nunca "documentar el bug" en silencio.
- Los RF se numeran `RF-<modulo>.<n>` por documento (RF-1.x comunicación, RF-2.x perfiles, RF-3.x catálogo, RF-4.x idioma, RF-5.x backend, RF-6.x acceso/cuentas); igual para RNF y CA.
- No crear documentos RF sueltos en la raíz de `requerimientos/`: un requerimiento nuevo es un `REQ-*` nuevo en `implementados/` (o una sección nueva en el existente si es la misma feature).

## Comandos

```bash
# desde src/frontend (SDK de Flutter en D:\flutter\bin)
flutter pub get        # instalar dependencias
flutter analyze        # lint (debe dar 0 issues)
flutter test           # tests
flutter run            # correr la app

# desde src/backend (dart está en D:\flutter\bin)
dart pub get           # instalar dependencias
dart analyze           # lint (debe dar 0 issues)
dart test              # tests
dart run bin/server.dart   # correr el backend (localhost:8080; PORT para otro puerto)
```

Para probar sync en emulador Android: `flutter run --dart-define=PICTOCOMM_BACKEND_URL=http://10.0.2.2:8080`.

## Gotchas

- El SDK de Flutter vive en `D:\flutter` (clonado de GitHub, rama stable) — `flutter` NO está en el PATH; usar `D:\flutter\bin\flutter.bat`.
- Git no está en el PATH por defecto; usar `& "C:\Program Files\Git\bin\git.exe"`.
- `Category` colisiona con la anotación `Category` de `flutter/foundation.dart` → importar con `hide Category`.
- `Symbol` colisiona con `dart:core.Symbol` → **usar `Picto`**.
- `Color.value` está deprecado → usar `toARGB32()`.
- `CupertinoPageTransitionsBuilder` no viene de `material.dart` → importarlo de `package:flutter/cupertino.dart`.
- `rootBundle` / `AssetManifest` vienen de `package:flutter/services.dart`, no de `material.dart`.
- Las carpetas `assets/images/*` están vacías; a medida que se agreguen imágenes reales se listan en `pubspec.yaml` bajo `flutter: assets:`. Con assets vacíos la home muestra el estado vacío, no un error.
- El build de **Windows desktop** requiere **Developer Mode** habilitado (symlinks de plugins) y **`nuget.exe`** (plugin `flutter_tts`). El nuget quedó en `D:\flutter\bin\` (descargado de `https://aka.ms/nugetclidl` con `curl.exe --ssl-no-revoke`, porque PowerShell/Invoke-WebRequest falla con SSL en esta red); al correr `flutter run -d windows` anteponer `D:\flutter\bin` al PATH.
- En tests, `expect(() => futureQueLanza, throwsA(...))` no funciona: usar `await expectLater(future, throwsA(...))`.
- `Set-Content` en PowerShell 5.1 no tiene `-NoNewline`; para reescribir archivos usar `[System.IO.File]::WriteAllText`.

## Testing

- `test/helpers/fakes.dart` centraliza los fakes. Todo pide interfaces, así que los widget tests inyectan `fakeDependencies()` y no tocan `AssetManifest`. `FakeAuthRepository` acepta `failures: {email: AuthErrorCode}` y `existingSession` (RF-6.4).
- Los tests de flujo arrancan en el login: después de `pumpWidget` hace falta **un `pump()` extra** (el primer frame es el splash del `AuthGate` mientras se restaura la sesión). No agrandes la superficie con `setSurfaceSize` en tests que abren diálogos: el diálogo se centra según la superficie "lógica" y los botones pueden quedar bajo el borde real (taps al vacío).
- Al agregar un método a una interfaz de `domain/`, actualizar los fakes: el compiler avisa, que es justamente el objetivo.
- Los fakes deben respetar el **mismo contrato** que la implementación real (mismas excepciones). Un fake más permisivo esconde bugs.
