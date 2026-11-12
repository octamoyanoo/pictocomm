# Acceso (login y registro)

> ⚠️ **Pendiente de aprobar:** este spec describe el comportamiento actual de la pantalla de acceso, pero **no existe todavía un requerimiento normativo** (`docs/requerimientos/`) que la cubra. Antes de aprobar, hay que decidir el modelo de cuenta (ver limitaciones).

Funcionalidad que **permite entrar a la app con un formulario de email y contraseña y llegar al selector de chico** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- Es la **ruta inicial** de la app (`/`): logo "PictoComm" con tagline, formulario de acceso y link a registro.
- Valida formato localmente: email requerido y con formato válido; contraseña requerida. Contraseña con toggle de visibilidad.
- Si el formulario valida, navega al **selector de chico** (`/child-selector`).
- El **registro** (`/signup`) pide nombre, email, contraseña (mínimo 8 caracteres) y confirmación; si valida, también llega al selector de chico.

## Experiencia de usuario

1. La app abre en `/`: el usuario completa email y contraseña (autofill hints de email/password, `TextInputAction.next`) y envía.
2. Si algún campo falla la validación, ve el error debajo del campo (`emailRequired`, `emailInvalid`, `passwordRequired`).
3. Si valida, entra directo al selector de chico (la app no muestra cargando ni error de credenciales: cualquier combinación válida "loguea").
4. El link inferior lleva a `/signup`; el registro análogamente valida y entra (link de vuelta al login con `pushReplacementNamed`).

## Cómo lo hace (implementación)

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Login | `lib/features/auth/presentation/screens/login_screen.dart` | `Form` con `Global<FormState>`; validadores de email (regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`) y password; `_submit` → `pushReplacementNamed(AppRoutes.childSelector)` |
| Registro | `lib/features/auth/presentation/screens/sign_up_screen.dart` | 4 campos; password mínimo 8 (`passwordTooShort`); confirmación con `passwordsMismatch`; `_submit` → `pushNamedAndRemoveUntil(childSelector)` |
| Rutas | `lib/app.dart` + `lib/core/constants/app_routes.dart` | `login = '/'` (initialRoute), `signup = '/signup'`; ambas rutas sin providers |
| Logo | `login_screen.dart` (`_LogoSection`) | Sección estática con nombre y tagline |

### Flujo paso a paso

1. `MaterialApp` arranca en `AppRoutes.login` (`'/'`).
2. Validación de campos con errores de l10n; sin llamada de red ni storage: **el login es 100% fake/local**, no toca repositorios ni providers.
3. Al validar, reemplaza la ruta por el selector de chico (el stack del login no queda en el historial).
4. El registro valida y entra igual (limpia todo el stack con `pushNamedAndRemoveUntil`).

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Email vacío | `emailRequired` bajo el campo |
| Email con formato inválido | `emailInvalid` (regex local) |
| Contraseña vacía (login) | `passwordRequired` (sin regla de largo) |
| Contraseña < 8 (solo registro) | `passwordTooShort` |
| Confirmación distinta (registro) | `passwordsMismatch` |
| Credenciales válidas | Entra al selector de chico (sin verificar nada) |
| Volver del registro al login | `pushReplacementNamed` (no acumula stacks) |

## Limitaciones conocidas

- **No hay autenticación real**: ni backend, ni persistencia de usuario, ni sesión recordada. Cualquier email válido + contraseña entra. La feature `auth/` tiene solo presentación (sin `data/` ni `domain/`).
- No existe cerrar sesión: la única forma de "salir" es volver al selector de chico con el botón del Home.
- Preguntas abiertas heredadas de REQ-PER-01: ¿el login guarda sesión (recuerda usuario y saltea el login)? ¿el selector recuerda el último chico? Ambas pendientes.
- Antes de aprobar este spec hace falta decidir si la app lleva cuentas reales (backend) o si el acceso pasa a ser solo una portada de bienvenida con elección de chico.

---

Volver a [`0000-index.md`](../0000-index.md).
