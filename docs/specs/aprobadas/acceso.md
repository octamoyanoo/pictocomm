# Acceso (login, registro y sesión)

> **Aprobado (2026-11-17):** spec revisado contra el código tras implementar REQ-ACC-01 (backend `auth_test.dart`, frontend `auth_test.dart` + `auth_flow_test.dart`).

Funcionalidad que **permite entrar a la app con una cuenta real**: registro y login contra el backend, sesión recordada entre arranques y logout desde Perfil. Los perfiles de chico quedan atados a la cuenta. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- Es la **pantalla inicial** de la app: al abrir, un `AuthGate` decide — según el estado de autenticación — entre un splash breve (mientras se restaura la sesión), el **login**, o el **selector de chico** si hay sesión recordada vigente.
- El **login** valida formato localmente (email con regex, contraseña requerida) y verifica credenciales reales contra `POST /api/v1/auth/login`. Credenciales incorrectas o sin conexión muestran el mensaje bajo el formulario y no navegan.
- El **registro** (`/signup`) pide nombre, email, contraseña (mínimo 8) y confirmación; valida igual que el login y crea la cuenta con `POST /api/v1/auth/register`. Email ya registrado → mensaje "Ya existe una cuenta con ese correo".
- La **sesión se recuerda**: token opaco + cuenta en SharedPreferences (`pictocomm.auth_session`). Al abrir con sesión vigente, la app entra directo al selector (incluso sin conexión, mientras el token no haya vencido). Token vencido localmente o revocado en el server (`GET /api/v1/auth/me` → 401) vuelve al login.
- El **logout** está en la pantalla Perfil (sección Cuenta, con confirmación): revoca el token (best-effort) y limpia la sesión local y el chico activo.
- Los **perfiles de chico se tagean con `accountId`**: el selector y la gestión muestran solo los perfiles de la cuenta logueada + los legacy sin cuenta (compatibilidad).

## Experiencia de usuario

1. La app abre: si hay sesión recordada vigente, directo al selector de chico (sin login). Si no, el login con logo "PictoComm", formulario y link a registro.
2. El usuario completa email y contraseña (autofill hints, toggle de visibilidad) y envía; el botón muestra un spinner mientras consulta el backend.
3. Si algún campo falla la validación de formato, ve el error debajo del campo (`emailRequired`, `emailInvalid`, `passwordRequired`).
4. Si el backend rechaza (credenciales incorrectas, email en uso, sin conexión), ve el mensaje l10n bajo el botón y queda en el formulario.
5. Si valida, entra directo al selector de chico (el login queda fuera del stack: la raíz es el `AuthGate`).
6. En Perfil (modo adulto), la sección **Cuenta** muestra nombre y email del adulto logueado con el botón "Cerrar sesión" (confirmación previa).

## Cómo lo hace (implementación)

### Backend (`src/backend/`, REQ-ACC-01)

| Parte | Archivo | Rol |
|---|---|---|
| Store de cuentas | `lib/src/account_store.dart` | `AccountStore` con cuentas + sesiones en `data/accounts.json`; PBKDF2-HMAC-SHA256 (10k iteraciones, salt 16 bytes); email case-insensitive; tokens opacos de 32 bytes con expiración de 30 días; resultados tipados (`AccountCreated`, `AccountLoggedIn`, `AccountEmailInUse`, `AccountInvalidCredentials`, `AccountInvalidInput`) |
| Rutas API | `lib/src/api_handler.dart` | `POST /api/v1/auth/register` (201/409/400), `POST /api/v1/auth/login` (200/401/400), `GET /api/v1/auth/me` (Bearer, 200/401), `POST /api/v1/auth/logout` (200/401); sin `AccountStore` → 503 |
| Server | `bin/server.dart` | Carga `data/accounts.json` (tolerante a archivo inválido) y lo pasa al router |

La respuesta de register/login es `{account: {id, name, email}, token, expiresAt}` — el hash/salt **nunca** viajan. Las sesiones persisten junto a las cuentas: reiniciar el server no desloguea a nadie.

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Entidades | `features/auth/domain/entities/` | `UserAccount` (id, nombre, email) y `AuthSession` (cuenta + token + `expiresAt`) |
| Contrato | `features/auth/domain/repositories/auth_repository.dart` | `register / login / restoreSession / logout` |
| HTTP | `features/auth/data/datasources/http_auth_data_source.dart` | `HttpAuthDataSource`: los códigos del backend se traducen a `AuthException` con `AuthErrorCode` (`invalidCredentials`, `emailInUse`, `connection`, `unexpected`); misma URL por `--dart-define=PICTOCOMM_BACKEND_URL` |
| Sesión local | `features/auth/data/datasources/local_session_data_source.dart` | `LocalSessionDataSource`: read/save/clear en SharedPreferences (clave `pictocomm.auth_session`, separada de las claves del catálogo/perfiles) |
| Repositorio | `features/auth/data/repositories/local_auth_repository.dart` | `LocalAuthRepository`: verifica contra el backend y persiste la sesión. `restoreSession`: vencida local → null; `me` 401 → null; sin conexión → cache (local-first). `logout`: revoca best-effort y borra local SIEMPRE |
| Estado | `features/auth/presentation/providers/auth_provider.dart` | `AuthProvider` con `AuthUnknownState` / `AuthUnauthenticatedState` / `AuthAuthenticatedState`; expone `currentAccountId` para tagear perfiles. Los errores de formulario NO viven acá: los catchea la pantalla |
| Pantalla inicial | `app.dart` (`AuthGate`) | `home:` del `MaterialApp`: splash → login → selector según el estado. El éxito de login/registro no navega: cambia el estado y el gate se reconstruye |
| Login | `features/auth/presentation/screens/login_screen.dart` | Validadores de formato + llamada al provider; spinner en el botón; error l10n bajo el botón (`authErrorMessage`) |
| Registro | `features/auth/presentation/screens/sign_up_screen.dart` | 4 campos (password ≥ 8, confirmación con `passwordsMismatch`) + llamada al provider |
| Logout | `features/profiles/presentation/screens/profile_screen.dart` | `_AccountSection` (nombre, email, botón) + `_ConfirmLogoutDialog`; limpia `SessionProvider` y hace `popUntil` a la raíz |
| Perfiles por cuenta | `features/profiles/` | `ChildProfile.accountId`; `getChildren({accountId})` filtra por cuenta (+ legacy sin cuenta); `createChild(child, {accountId})` tagea; `ChildrenProvider` recibe la cuenta del `AuthProvider` en la ruta |

### Flujo paso a paso (arranque)

1. `PictoCommApp` crea `AuthProvider` (sobre `dependencies.authRepository`, construido en `AppDependencies.bootstrap()` con `HttpAuthDataSource` + `LocalSessionDataSource`).
2. `unawaited(auth.restore())`: mientras corre, el `AuthGate` muestra splash.
3. `restore()` lee la sesión guardada; si es vigente valida contra `/me` y entra al selector; si no, login.
4. Al loguear/registrar, el provider pasa a autenticado: el `AuthGate` muestra el selector en línea (con `ChildrenProvider` filtrado por `accountId`).

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Email vacío / inválido, contraseña vacía | Errores de campo locales, sin red |
| Contraseña < 8 (solo registro) | `passwordTooShort`; el server también la rechaza (400) |
| Credenciales incorrectas | `authInvalidCredentials` bajo el botón, queda en login |
| Email ya registrado | `authEmailInUse` (409 del server, case-insensitive) |
| Backend caído / timeout | `authConnectionError`; formulario usable |
| Token vencido localmente | Sesión borrada → login |
| Token revocado en server (401 en `/me`) | Sesión borrada → login |
| Sin conexión con sesión vigente | Cache vale (local-first): entra al selector |
| Logout sin conexión | Cierra local igual (el token expira solo en el server) |
| Perfiles legacy (sin `accountId`) | Visibles para cualquier cuenta del dispositivo |
| Server sin `AccountStore` | register/login → 503; me/logout → 401; sin crashear |

## Limitaciones conocidas

- Sin HTTPS ni rate-limiting (red local/confiable; ver RNF-6.3 y "Fuera de alcance" del REQ-ACC-01).
- Sin refresh token: 30 días de vida del token y re-login.
- Sin verificación de email ni recuperación de contraseña.
- El backend aún sirve el catálogo sin filtro por cuenta (los pictos siguen siendo globales; la cuenta scopea solo los perfiles de chico).
- Los perfiles legacy (creados antes de esta feature) siguen visibles para cualquier cuenta; no hay migración.

---

Volver a [`0000-index.md`](../0000-index.md).
