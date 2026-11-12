# REQ-PER-01 — Perfiles de niño

**Mockup:** `docs/prototipos/wireframes.pen` → frames **`Selector de chico`**, **`Perfil`**
**Specs vigentes:** [`perfiles.md`](../../specs/aprobadas/perfiles.md)
**Archivos implicados:** `lib/features/profiles/presentation/screens/child_selector_screen.dart`, `lib/features/profiles/presentation/screens/profile_screen.dart`, `lib/features/profiles/presentation/providers/session_provider.dart`, `lib/features/profiles/presentation/providers/children_provider.dart`, `lib/features/profiles/domain/repositories/child_profile_repository.dart`, `lib/features/profiles/data/repositories/local_child_profile_repository.dart`, `lib/features/profiles/data/datasources/local_child_profile_data_source.dart`, `lib/features/profiles/data/models/child_profile_model.dart`, `lib/core/di/injector.dart`

---

## 1. Objetivo

La app es usada por un adulto responsable con uno o más niños a la vez: cada dispositivo puede tener varios perfiles y la sesión de comunicación se abre **para un chico específico**.

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-12):

- El selector de chico es la entrada de sesión (siempre arranca acá, sin recordar lo último).
- La sesión activa es estado a nivel app y sobrevive la navegación entre pestañas.
- La pantalla Perfil lista perfiles reales y persistidos; crear (nombre + color + foto opcional) y borrar con doble confirmación funcionan.
- Los perfiles se guardan en SharedPreferences (JSON) y el borrado purga los pictos del chico por composición.

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Selector de chico | Grilla de tarjetas grandes (avatar + nombre); estado vacío con acceso a crear el primer perfil | **Implementado** |
| Sesión activa | Estado a nivel app (`SessionProvider`), volátil | **Implementado** |
| Salida al selector | Botón simple visible en el Home (sin puertas parentales) | **Implementado** |
| Gestión (modo adulto) | Lista real y persistida; crear con nombre + color de paleta fija | **Implementado** |
| Foto del niño | Opcional al crear (rinde RF-2.12 vía REQ-CAT-01) | **Implementado** |
| Borrado de perfil | Doble confirmación + purga en cascada de pictos | **Implementado** |
| Persistencia | Local-first: SharedPreferences, JSON, backend-ready | **Implementado** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-2.1 | Tras iniciar sesión se muestra el **selector de chico**: una grilla de tarjetas grandes (avatar circular + nombre). El niño (o el adulto con el chico en brazos) toca su tarjeta y entra. |
| RF-2.2 | El chico elegido queda como **sesión activa**: es un estado a nivel app, no un argumento de ruta, para que sobreviva la navegación entre pestañas. |
| RF-2.3 | Volver al selector de chico es con **botón simple visible** desde las pantallas de sesión (en v1, desde home). Sin puertas parentales para salir (decisión del usuario). |
| RF-2.4 | Si no hay perfiles creados, el selector muestra estado vacío con acceso directo a crear el primer perfil. |
| RF-2.5 | La pantalla Perfil lista los perfiles **reales y persistidos** (el mock hardcodeado inicial fue eliminado). |
| RF-2.6 | Crear un perfil pide **nombre + color de avatar** elegible de una paleta fija. La foto del chico la cubre REQ-CAT-01 (RF-3.11). |
| RF-2.7 | Borrar un perfil exige **doble confirmación**: primer diálogo con consecuencias ("borra también sus pictos"), segundo diálogo de confirmación final. |
| RF-2.8 | Si se borra el chico de la sesión activa, la sesión queda sin chico activo. |
| RF-2.9 | Local-first: los perfiles se guardan en el dispositivo (SharedPreferences, JSON). Sin cuenta ni conexión. |
| RF-2.10 | Interfaz `ChildProfileRepository` en `domain/` con `getChildren / createChild / updateChild / deleteChild`. El nombre no puede quedar vacío. Edición de perfiles: v2 (fuera de alcance). |
| RF-2.11 | El modelo de `data/models/` lleva `toJson/fromJson`, backend-ready como el resto. |
| RF-2.12 | La foto del niño se proyecta como campo futuro (`photoUrl` nullable): se implementó junto con REQ-CAT-01. |

## 5. Requerimientos visuales / no funcionales

| ID | Requerimiento |
|---|---|
| RNF-2.1 | El selector no tiene barra inferior: no es una pestaña más, es un portón. |
| RNF-2.2 | Sin foto, el avatar cae al círculo de color con la inicial del nombre. |
| RNF-2.3 | Los ids se generan con contador además del timestamp: dos creaciones en el mismo microsegundo no colisionan. |
| RNF-2.4 | La cascada de borrado (perfil → pictos) se inyecta por composición en `core/di` (`purgePictosForChild`), sin dependencia cruzada entre features. |
| RNF-2.5 | El color del avatar viaja como ARGB int en el JSON (sin arrastrar `dart:ui`). |

## 6. Casos de uso

### UC-01.1 — Entrar a la sesión de un chico

| | |
|---|---|
| **Actor** | Niño (o adulto con el chico en brazos) |
| **Objetivo** | Abrir la sesión de comunicación para un chico |
| **Precondiciones** | La app está en el selector de chico |
| **Disparador** | El niño toca su tarjeta |

**Flujo principal:**
1. El selector carga los perfiles persistidos.
2. El niño toca su tarjeta (avatar + nombre).
3. El chico queda como sesión activa y la app navega al Home.
4. El catálogo y los pictos visibles se recargan para ese chico.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | No hay perfiles creados | Estado vacío con botón directo a crear el primer perfil |
| 2 | Error de carga | La pantalla muestra el mensaje del error |

**Postcondiciones:** Sesión activa seteada; las pestañas operan con el chico elegido.

### UC-01.2 — Crear un perfil

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Agregar un chico al dispositivo |
| **Precondiciones** | Pantalla Perfil (modo adulto) |
| **Disparador** | Botón (+) de la sección Chicos |

**Flujo principal:**
1. El diálogo pide nombre, color de la paleta fija (8 opciones) y foto opcional (galería/cámara; en web la cámara va deshabilitada).
2. El adulto confirma.
3. El perfil se persiste y la lista se recarga con el nuevo chico.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Nombre vacío | El diálogo no envía (sin mensaje) |
| 2 | Sin foto | El avatar cae al círculo de color |
| 3 | Falla de imagen | Error silencioso: se crea sin foto |

**Postcondiciones:** El perfil aparece en selector y lista; puede elegirse como sesión activa.

### UC-01.3 — Borrar un perfil

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Eliminar un chico y sus datos |
| **Precondiciones** | Perfil existente en la lista de Perfil |
| **Disparador** | Papelera del tile del chico |

**Flujo principal:**
1. Diálogo 1: consecuencias ("borra también sus pictos") → Siguiente.
2. Diálogo 2: "Conservar" / "Borrar para siempre" (rojo).
3. El perfil se elimina, se purgan sus pictos custom en cascada y la lista se recarga.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Conservar en el paso 2 | No se borra nada |
| 2 | El chico borrado era el de la sesión activa | La sesión queda sin chico activo |

**Postcondiciones:** El perfil y sus pictos personalizados dejaron de existir en el dispositivo.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-2.1 | **Given** la app recién abierta, **when** se carga la primera pantalla de sesión, **then** es el selector de chico (nunca se preselecciona el último). |
| CA-2.2 | **Given** el selector, **when** se toca la tarjeta de un chico, **then** queda como sesión activa y la app navega al Home. |
| CA-2.3 | **Given** un chico activo, **when** se navega entre pestañas, **then** la sesión se mantiene. |
| CA-2.4 | **Given** el Home con chico activo, **when** se toca el botón de cambio, **then** se vuelve al selector. |
| CA-2.5 | **Given** un dispositivo sin perfiles, **when** se abre el selector, **then** se muestra el estado vacío con acceso a crear el primer perfil. |
| CA-2.6 | **Given** el modo adulto, **when** se crea un perfil con nombre y color, **then** aparece persistido en la lista y en el selector. |
| CA-2.7 | **Given** un perfil, **when** se lo borra con la doble confirmación, **then** se elimina y sus pictos personalizados se purgan. |
| CA-2.8 | **Given** el chico de la sesión activa, **when** se lo borra, **then** la sesión queda sin chico activo. |
| CA-2.9 | **Given** dos creaciones de perfil en el mismo microsegundo, **when** se generan los ids, **then** no colisionan (contador anti-colisión). |

Cobertura de tests: `test/perfiles_flow_test.dart`, `test/child_profile_repository_test.dart`, `test/catalog_perfil_test.dart` (fakes con el mismo contrato que la implementación real).

## 8. Fuera de alcance

- Edición de perfiles (v2).
- Persistir la sesión de chico activo entre aperturas de la app.
- Puertas parentales o PIN para salir del modo niño (decisión del usuario: sin puertas en v1).
- Cuentas de adulto con contraseña (el acceso actual no valida credenciales: ver [specs/por-aprobar/acceso.md](../../specs/por-aprobar/acceso.md)).
- Foto gestionada desde edición de perfil (v2; hoy solo al crear).

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Sesión activa | Decisión (mi llamada): estado a nivel app (`SessionProvider` sobre el `MaterialApp`), no argumento de ruta. |
| 2 | Persistencia de sesión | Pendiente (pregunta abierta #1): no se persiste; cada apertura arranca en el selector. |
| 3 | Preselección del último chico | Pendiente (pregunta abierta #2): v1 siempre empieza en selector. |
| 4 | Puertas parentales | Confirmado (usuario): salida con botón simple visible, sin PIN. |
| 5 | Edad | Confirmado (usuario): v1 sin edad; la entidad la conserva opcionalmente. |
| 6 | Cascada de borrado | Decisión (mi llamada): por composición en el composition root, para no acoplar profiles al catálogo. |
| 7 | Nombre vacío al crear | Decisión (mi llamada): el repo rechaza (`DataSourceException`); el diálogo simplemente no envía si está vacío. |
