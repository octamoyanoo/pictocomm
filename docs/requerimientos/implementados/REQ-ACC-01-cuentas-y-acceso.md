# REQ-ACC-01 — Acceso y cuentas (login, registro y sesión)

**Specs vigentes:** [`acceso.md`](../../specs/aprobadas/acceso.md)
**Archivos implicados:** `src/backend/lib/src/account_store.dart`, `src/backend/lib/src/api_handler.dart`, `src/backend/bin/server.dart`, `lib/features/auth/domain/` (entidades + `AuthRepository`), `lib/features/auth/data/` (`HttpAuthDataSource`, `LocalSessionDataSource`, `LocalAuthRepository`), `lib/features/auth/presentation/providers/auth_provider.dart`, `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/auth/presentation/screens/sign_up_screen.dart`, `lib/app.dart` (`AuthGate`), `lib/features/profiles/` (`accountId` en `ChildProfile`), `lib/core/di/injector.dart`

---

## 1. Objetivo

La app es usada por un adulto responsable; hasta ahora el acceso era una portada fake ("cualquier email válido entraba"). Este REQ define el **modelo de cuentas real**: registro y login contra el backend, sesión recordada en el dispositivo, logout desde Perfil y perfiles de chico tageados por cuenta.

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-17):

- Backend con endpoints `/api/v1/auth/*` (register/login/me/logout), contraseñas hasheadas y sesiones con token persistidas en `data/accounts.json`.
- La app valida credenciales contra el backend; con sesión recordada abre directo en el selector de chico, sin login (y sin conexión, mientras el token no haya vencido).
- Logout desde la pantalla Perfil, con confirmación.
- Los `ChildProfile` llevan `accountId`; el selector muestra solo los perfiles de la cuenta logueada (más los legacy sin cuenta).

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Crear cuenta | Registro con nombre, email y contraseña (mínimo 8) contra el backend; email único case-insensitive | **Implementado** |
| Login | Verificación real de credenciales; token opaco con expiración (30 días) | **Implementado** |
| Sesión recordada | Token + cuenta en SharedPreferences (`pictocomm.auth_session`); arranque directo al selector | **Implementado** |
| Logout | Botón en Perfil con confirmación; revoca el token (best-effort) y borra la sesión local | **Implementado** |
| Validación de token | `GET /auth/me` al restaurar: revocado/vencido → re-login; sin conexión → se confía en el cache | **Implementado** |
| Perfiles por cuenta | `accountId` en `ChildProfile`; filtro en lectura y tageo en creación | **Implementado** |
| Errores de acceso | Mensajes l10n bajo el formulario (credenciales inválidas, email en uso, sin conexión) | **Implementado** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-6.1 | El **registro** pide nombre, email y contraseña; el backend crea la cuenta (`POST /api/v1/auth/register`, 201) con email único case-insensitive y deja la sesión iniciada. Email duplicado → error visible (409). Contraseña con mínimo de 8 caracteres (validada en el formulario y en el server). |
| RF-6.2 | El **login** verifica credenciales reales (`POST /api/v1/auth/login`): credenciales correctas → token de sesión + entrada al selector de chico; incorrectas → mensaje de error, sin navegar. El server responde el MISMO error para email inexistente y contraseña incorrecta (no se revela qué cuentas existen). |
| RF-6.3 | El token se puede validar server-side (`GET /api/v1/auth/me` con `Authorization: Bearer`). El login no sirve nada de datos: solo identidad. |
| RF-6.4 | La app **recuerda la sesión** (RF2.1 de esta feature): al abrir, si hay sesión vigente, arranca directo en el selector de chico. Solo el primer login/registro (o tras logout) pide conexión. Token vencido o revocado → vuelve al login. Sin conexión → la sesión cacheada vale mientras no haya vencido (local-first). |
| RF-6.5 | **Cerrar sesión** desde la pantalla Perfil, con confirmación. Revoca el token en el server (best-effort: sin conexión igual cierra local) y limpia la sesión del chico activo. La app vuelve al login. |
| RF-6.6 | Los **perfiles de chico quedan atados a la cuenta**: al crear un perfil se tagea con `accountId`; el selector (y la gestión en Perfil) muestran solo los perfiles de la cuenta logueada, más los legacy sin cuenta (creados antes de las cuentas, siguen visibles para compatibilidad). |
| RF-6.7 | La sesión vive **30 días**; vencido el token, el dispositivo pide login de nuevo (no hay refresh token en v1). |
| RF-6.8 | Los errores de acceso se muestran **l10n y sin detalles crudos**: credenciales incorrectas, email en uso, sin conexión y error genérico, bajo el formulario (los errores de formato de campo quedan en cada campo). |

## 5. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-6.1 | Arquitectura: la feature `auth/` sigue el patrón por feature (`domain` con entidades + interfaz, `data` con datasources y repositorio, `presentation` con provider + pantallas). La presentación solo ve interfaces de `domain/`. |
| RNF-6.2 | La sesión se guarda en SharedPreferences con clave propia (`pictocomm.auth_session`), separada de las claves del catálogo y de los perfiles. La contraseña **nunca** se persiste en el dispositivo. |
| RNF-6.3 | Las contraseñas se hashean en el server con **PBKDF2-HMAC-SHA256** (10 000 iteraciones, salt de 16 bytes por cuenta, hash de 32 bytes). El hash/salt nunca salen por la API. Limitación aceptada: para producción conviene >100k iteraciones o bcrypt/argon2 y rate-limiting (fuera de alcance). |
| RNF-6.4 | Las cuentas y sesiones persisten en `data/accounts.json` y **sobreviven reinicios del server** (igual que `uploads.json` para el catálogo). Persistencia best-effort: si el disco falla, el estado en memoria queda consistente. |
| RNF-6.5 | Sin `AccountStore` configurado, el server responde 503 en register/login y 401 en me/logout, sin crashear (misma tolerancia que el seed del catálogo). |
| RNF-6.6 | El login no permite enumerar cuentas: mismo mensaje y status para email inexistente y contraseña incorrecta (401). |
| RNF-6.7 | El token es opaco (32 bytes aleatorios base64url), único por sesión, con expiración persistida. La comparación del hash es a longitud constante. |
| RNF-6.8 | La sesión activa de chico (`SessionProvider`) se limpia al logout: el próximo login arranca de nuevo en el selector. |

## 6. Casos de uso

### UC-6.1 — Crear cuenta

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Crear una cuenta y entrar a la app |
| **Precondiciones** | La app abre en el login; el backend está accesible |
| **Disparador** | Tap en "Regístrate aquí" |

**Flujo principal:**
1. El formulario pide nombre, email, contraseña y confirmación (mínimo 8).
2. Al enviar, la app llama `POST /api/v1/auth/register`.
3. El server valida, hashea la contraseña con salt nueva y crea la sesión.
4. La app guarda la sesión local y muestra el selector de chico.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Formato de email inválido / contraseña corta / contraseñas distintas | Error bajo el campo correspondiente; no hay llamada de red |
| 2 | Email ya registrado (409) | Mensaje "Ya existe una cuenta con ese correo" bajo el formulario |
| 3 | Sin conexión | Mensaje de conexión; el formulario queda usable |

### UC-6.2 — Login

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Entrar con una cuenta existente |
| **Precondiciones** | La app abre en el login (sin sesión recordada) |
| **Disparador** | Tap en "Iniciar Sesión" |

**Flujo principal:**
1. Email + contraseña; validación local de formato.
2. `POST /api/v1/auth/login` → 200 con token y expiración.
3. La app guarda la sesión y muestra el selector de chico (los perfiles son los de esa cuenta).

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Credenciales incorrectas (401) | Mensaje "Correo o contraseña incorrectos"; queda en el login |
| 2 | Sin conexión | Mensaje de conexión; queda en el login |

### UC-6.3 — Arrancar con sesión recordada

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Abrir la app sin volver a loguear |
| **Precondiciones** | Hay sesión guardada vigente en el dispositivo |
| **Disparador** | Abrir la app |

**Flujo principal:**
1. Al arrancar, `AuthProvider.restore()` lee la sesión guardada.
2. `GET /api/v1/auth/me` valida el token (si hay conexión).
3. La app entra directo al selector de chico.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Token vencido localmente | Se borra la sesión y se muestra el login |
| 2 | Token revocado/vencido en el server (401 en `/me`) | Se borra la sesión y se muestra el login |
| 3 | Sin conexión y token vigente | Se confía en el cache (local-first): entra al selector |

### UC-6.4 — Cerrar sesión

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Salir de la cuenta en este dispositivo |
| **Precondiciones** | Sesión activa; app en Perfil (modo adulto) |
| **Disparador** | Tap en "Cerrar sesión" de la sección Cuenta |

**Flujo principal:**
1. Confirmación en diálogo.
2. Se revoca el token (`POST /api/v1/auth/logout`) y se borra la sesión local.
3. Se limpia el chico activo y la app vuelve al login.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Sin conexión | El logout local se aplica igual (el token expira solo en el server) |

## 7. Criterios de aceptación

| ID | Dado | Cuando | Entonces |
|---|---|---|---|
| CA-6.1 | Server corriendo | registro con datos válidos | 201 con cuenta + token + expiración, sin hash ni salt en la respuesta |
| CA-6.2 | Cuenta `Ana@mail.com` | registro de `ana@mail.com` | 409 (email case-insensitive) |
| CA-6.3 | Formulario de registro | nombre vacío / email inválido / contraseña < 8 / contraseñas distintas | error bajo el campo; sin llamada de red; en el server estos cuerpos responden 400 |
| CA-6.4 | Cuenta existente | login con contraseña correcta | 200 con token; con email inexistente o contraseña incorrecta → 401 con el mismo mensaje |
| CA-6.5 | Token válido | `GET /auth/me` con Bearer | 200 con la cuenta; sin header o token inválido → 401 |
| CA-6.6 | Sesión iniciada | logout y reintento del token | 200 el logout; el token queda inválido (401) y es idempotente |
| CA-6.7 | Server reiniciado | login previo y `me` con el token guardado | 200 (sesiones y cuentas sobreviven en `accounts.json`) |
| CA-6.8 | App con sesión recordada | abrir la app | entra directo al selector, sin pantalla de login |
| CA-6.9 | Logout desde Perfil | confirmación | vuelve al login; el próximo arranque pide credenciales |
| CA-6.10 | Dos cuentas en el mismo dispositivo | selector y Perfil | cada cuenta ve solo sus perfiles (+ los legacy sin cuenta) |

## 8. Fuera de alcance (v1)

- Rate limiting, verificación de email, recuperación de contraseña, MFA.
- HTTPS (se asume red local/confiable; el hash PBKDF2 con 10k iteraciones es proporcional a ese modelo de amenaza).
- Refresh tokens y revocación por dispositivo (una sesión por login; 30 días y re-login).
- Migración de perfiles legacy a una cuenta específica (siguen visibles para todas las cuentas del dispositivo).
- El backend sirve pictos/perfiles por cuenta (los pictos siguen siendo globales; `childProfileId` queda como está en REQ-BCK-02).
