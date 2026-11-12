# REQ-IDI-01 — Idioma de la app (i18n)

**Mockup:** `docs/prototipos/wireframes.pen` → frame **`Perfil`** (sección de idioma)
**Specs vigentes:** [`idioma.md`](../../specs/aprobadas/idioma.md)
**Archivos implicados:** `lib/core/i18n/locale_controller.dart`, `lib/features/profiles/presentation/screens/profile_screen.dart` (`_LanguageSection`), `lib/app.dart`, `lib/main.dart`, `lib/l10n/app_es.arb`, `app_en.arb`, `app_pt.arb`, `src/frontend/l10n.yaml`, `src/frontend/pubspec.yaml`

---

## 1. Objetivo

La app se ofrece en varios idiomas: su interfaz (textos de pantallas, botones, diálogos, mensajes y errores visibles) se presenta en el idioma elegido por el adulto responsable. Es una decisión **global del dispositivo**: el adulto arma la sesión y define el idioma; los chicos de esa casa comparten ese idioma de interfaz.

**Fuera de alcance (frontera con los otros REQ):**

- La **voz** del pictograma (TTS) no es parte de este requerimiento: su idioma quedó como pregunta abierta de REQ-COM-01 y se resuelve allí. Que la UI esté en un idioma no condiciona el idioma de la voz.
- Los **nombres de pictos, categorías y perfiles** son contenido (del catálogo incluido o ingresado por el adulto), no interfaz: no se traducen.

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-12):

- Tres idiomas (es/en/pt) con cobertura completa; español como default.
- Selector en la pantalla Perfil, con nombres en idioma nativo y radio del activo.
- Cambio instantáneo en todas las pantallas (reconstrucción del `MaterialApp` via watch).
- Persistencia en SharedPreferences (`pictocomm.ui_locale`) resuelta **antes del primer frame**; fallback al idioma del sistema y luego al español.
- Cobertura por tests (`test/idioma_test.dart`, `test/locale_controller_test.dart`): la primera línea que rompe cuando alguien agrega texto suelto en un widget.

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Idiomas soportados | Español (default), inglés, portugués; uno activo por vez | **Implementado** |
| Selector | Pantalla Perfil, lista corta, activo destacado | **Implementado** |
| Aplicación del cambio | Inmediata en todas las pantallas, sin reiniciar | **Implementado** |
| Persistencia | SharedPreferences; arranque siempre en el idioma almacenado | **Implementado** |
| Primer arranque | Idioma del sistema si soportado; si no, español | **Implementado** |
| Cobertura | 100% de textos desde tablas; prohibido texto hardcodeado | **Implementado** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-4.1 | La app soporta tres idiomas: **español** (default), **inglés** y **portugués**. La app funciona con un solo idioma activo por vez (no es contenido bilingüe simultáneo). |
| RF-4.2 | El selector de idioma vive en la **pantalla Perfil** (espacio del adulto): una lista corta con los tres idiomas; el activo queda destacado. |
| RF-4.3 | El cambio de idioma aplica **inmediatamente** en todas las pantallas visibles, **sin reiniciar la app**. |
| RF-4.4 | Local-first: el idioma se guarda en el dispositivo (SharedPreferences) y la app **siempre arranca en el idioma almacenado**, sin conexión ni cuenta. |
| RF-4.5 | Primer arranque (nunca configurado): la app usa el **idioma del sistema** si está soportado (es/en/pt); si no, cae al **español**. |
| RF-4.6 | El **100% de los textos de interfaz** sale de la centralización de strings: pantallas, botones, diálogos, tooltips, SnackBar y mensajes de error visibles. Queda prohibido el texto hardcodeado en widgets. |
| RF-4.7 | Agregar un idioma nuevo **no obliga a tocar pantallas ni providers**: se agrega la tabla de traducciones correspondiente y nada más. |
| RF-4.8 | Los tres idiomas tienen **cobertura completa**: ninguna pantalla casa cabezas (texto mezclado) en ningún idioma soportado. |

## 5. Requerimientos visuales / no funcionales

| ID | Requerimiento |
|---|---|
| RNF-4.1 | Los nombres de los idiomas en el selector siempre están en su idioma nativo (`Español` / `English` / `Português`), independiente del idioma activo. |
| RNF-4.2 | El idioma es un aspecto **transversal**: el `LocaleController` vive en `core/` (junto al theme), sin entidad de dominio nueva. |
| RNF-4.3 | El locale del `MaterialApp` no depende de la sesión de chico activo: cambiar de niño **no** cambia el idioma, y borrar un perfil **no** lo toca. |
| RNF-4.4 | SharedPreferences se resuelve **antes del primer frame** (`main`), para que el idioma esté decidido antes de que exista UI. |
| RNF-4.5 | En tests se usa `LocaleController.ephemeral()` (sin persistencia, español fijo) para determinismo. |

## 6. Casos de uso

### UC-01.1 — Cambiar el idioma de la app

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Presentar la app en otro idioma |
| **Precondiciones** | Pantalla Perfil visible |
| **Disparador** | El adulto toca otro idioma en la sección de idioma |

**Flujo principal:**
1. La sección de idioma muestra los tres idiomas con el activo marcado por radio.
2. El adulto toca otro idioma.
3. El controller persiste el idioma y notifica.
4. El `MaterialApp` se reconstruye con el locale nuevo: todas las pantallas cambian al instante, sin reiniciar.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Idioma ya activo | No-op (sin notify innecesario) |
| 2 | Idioma no soportado | Ignorado |

**Postcondiciones:** La app entera opera en el idioma elegido y queda persistido para el próximo arranque.

### UC-01.2 — Primer arranque de la app

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Usar la app en el idioma adecuado sin configurar nada |
| **Precondiciones** | Ningún idioma almacenado en el dispositivo |
| **Disparador** | Apertura de la app por primera vez |

**Flujo principal:**
1. `main` resuelve SharedPreferences antes del primer frame.
2. Sin valor almacenado: se usa el idioma del sistema si es es/en/pt.
3. La app arranca en ese idioma.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Sistema en idioma no soportado | Cae al español |
| 2 | Valor almacenado corrupto/no soportado | Se ignora y se cae al sistema/español |

**Postcondiciones:** La app abre en un idioma legible para la casa; el adulto puede cambiarlo en Perfil.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-4.1 | **Given** la pantalla Perfil, **when** se abre la sección de idioma, **then** se ven los tres idiomas con nombres en idioma nativo y el activo destacado. |
| CA-4.2 | **Given** un idioma activo, **when** el adulto elige otro, **then** todas las pantallas visibles cambian de idioma al instante, sin reiniciar. |
| CA-4.3 | **Given** un idioma elegido, **when** la app se cierra y reabre, **then** arranca en el idioma almacenado. |
| CA-4.4 | **Given** el primer arranque con sistema es/en/pt, **when** la app abre, **then** lo hace en el idioma del sistema. |
| CA-4.5 | **Given** el primer arranque con sistema en otro idioma, **when** la app abre, **then** lo hace en español. |
| CA-4.6 | **Given** cualquier pantalla en cualquier idioma soportado, **when** se inspecciona el texto, **then** no hay texto hardcodeado ni idiomas mezclados (los tests de cobertura son la primera línea que rompe). |
| CA-4.7 | **Given** un cambio de chico o un borrado de perfil, **when** se navega, **then** el idioma almacenado no cambia. |

Cobertura de tests: `test/idioma_test.dart`, `test/locale_controller_test.dart`.

## 8. Fuera de alcance

- Traducir la **voz** del TTS (pregunta abierta de REQ-COM-01, se resuelve allí).
- Traducir nombres de pictos, categorías y perfiles (contenido, no interfaz).
- Etiquetas bilingües de pictos del catálogo incluido (pregunta abierta #1, v2).
- Localización de formatos de fecha/número (hoy no hay fechas visibles en UI; pendiente #2).

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Alcance del idioma | Confirmado (usuario): decisión global del dispositivo, compartida por los chicos de la casa. |
| 2 | Ubicación del selector | Confirmado (usuario): pantalla Perfil, espacio del adulto. |
| 3 | Mecanismo | Decisión (mi llamada): estándar de Flutter (`flutter_localizations` + ARB generados); cumple RF-4.6/4.7 por diseño. |
| 4 | Ubicación del controller | Decisión (mi llamada): `LocaleController` en `core/i18n`, transversal como el theme, sin entidad de dominio. |
| 5 | Reconstrucción al cambiar | Decisión (mi llamada): `Builder` con `watch` sobre el controller reconstruye el `MaterialApp` completo (sin esto, el `MaterialApp` quedaba con el locale viejo). |
| 6 | Idioma y sesión | Decisión (mi llamada): desacoplados — cambiar de niño no toca el idioma. |
