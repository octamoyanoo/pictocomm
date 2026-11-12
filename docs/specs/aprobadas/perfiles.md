# Perfiles de niño

Funcionalidad que **permite usar la app con uno o más niños: cada dispositivo tiene varios perfiles y la sesión de comunicación se abre para un chico específico** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- Tras el acceso, la app siempre arranca en el **selector de chico**: una grilla de tarjetas grandes (avatar circular + nombre) donde el niño (o el adulto con el chico en brazos) toca su tarjeta y entra.
- El chico elegido queda como **sesión activa**: es un estado a nivel app (no un argumento de ruta), de modo que sobrevive la navegación entre pestañas y define qué pictos personalizados se ven.
- El **modo adulto** (pestaña Perfil) permite crear perfiles (nombre + color de avatar + foto opcional), listarlos y borrarlos con **doble confirmación**. Borrar un perfil purga en cascada sus pictos personalizados.
- Local-first: los perfiles se guardan en el dispositivo (SharedPreferences, JSON), sin cuenta ni conexión.

## Experiencia de usuario

1. La app abre en el selector de chico (`/child-selector`), una pantalla **sin barra inferior** (no es una pestaña más, es un portón).
2. Sin perfiles creados, muestra el estado vacío (ícono `child_care_outlined`, título y subtítulo) con el botón **Crear perfil** que lleva directo a la pantalla Perfil.
3. Con perfiles, muestra la grilla de tarjetas (avatar + nombre); tocar una tarjeta activa al chico y navega a `/home`.
4. Volver al selector desde las pantallas de sesión es con el **botón simple visible** del Home (ícono `swap_horiz` en el header). Sin puertas parentales para salir (decisión del usuario).
5. En la pestaña **Perfil** (modo adulto), la sección *Chicos* lista los perfiles reales y persistidos: cada tile muestra avatar + nombre + papelera. El botón (+) abre el diálogo de creación.
6. Crear perfil pide **nombre** (obligatorio), **color de avatar** de una paleta fija de 8 y **foto opcional** (galería o cámara; en web la cámara aparece deshabilitada). Sin foto, el avatar cae al círculo de color.
7. Borrar un perfil exige **doble confirmación**: primer diálogo con las consecuencias ("borra también sus pictos"), segundo diálogo final ("Conservar" / "Borrar para siempre" en rojo).
8. Si se borra el chico de la sesión activa, la sesión queda sin chico activo.

## Cómo lo hace (implementación)

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Selector | `lib/features/profiles/presentation/screens/child_selector_screen.dart` | Grilla (`maxCrossAxisExtent: 180`), estado vacío y tap → `setActiveChild` + `pushReplacementNamed(home)` |
| Gestión | `lib/features/profiles/presentation/screens/profile_screen.dart` | Lista, idioma (ver [idioma.md](./idioma.md)), `AddChildDialog` y las dos confirmaciones de borrado |
| Diálogo de creación | `profile_screen.dart` (`AddChildDialog`) | Nombre + paleta `AppColors.avatarPalette` (8 colores) + foto opcional (data URL); devuelve `(nombre, colorARGB, photoDataUrl)` |
| Avatar | `lib/features/profiles/presentation/widgets/child_avatar.dart` | Muestra la foto si hay; si no, círculo de color con inicial |
| Sesión activa | `lib/features/profiles/presentation/providers/session_provider.dart` | `activeChild`, `setActiveChild()`, `clearIfDeleted(id)`. Volátil: no se persiste (cada apertura arranca en selector) |
| Estado de perfiles | `lib/features/profiles/presentation/providers/children_provider.dart` | `ChildrenLoadingState / ChildrenLoadedState / ChildrenFailureState`; `load()`, `createChild()`, `deleteChild()` |
| Repositorio | `lib/features/profiles/data/repositories/local_child_profile_repository.dart` | Interfaz `ChildProfileRepository` de `domain/`: `getChildren / createChild / updateChild / deleteChild`. Nombre vacío → `DataSourceException`; ids `child-<microsegundos>-<contador>` (contador anti-colisión) |
| Persistencia | `lib/features/profiles/data/datasources/local_child_profile_data_source.dart` | SharedPreferences clave `pictocomm.children_profiles`, JSON array |
| Modelo | `lib/features/profiles/data/models/child_profile_model.dart` | JSON: `{ id, name, age?, avatarColorValue? (ARGB int), photoUrl? (data URL) }` — backend-ready con `toJson/fromJson` |
| Cascada de borrado | `lib/core/di/injector.dart` | `LocalChildProfileRepository` recibe `purgePictosForChild` por composición: borrar un perfil purga sus pictos custom **sin acoplar** la feature profiles al catálogo |
| Recarga al cambiar chico | `lib/app.dart` | `session.addListener(appRouter.reloadAfterSessionChange)`: al cambiar de chico se recargan `CatalogProvider` y `PictosProvider` |

### Flujo paso a paso

1. La ruta `/child-selector` crea un `ChildrenProvider` nuevo con `..load()` en el `create` (no se recarga en `initState` para no disparar `notifyListeners` durante el build).
2. Tap en tarjeta → `SessionProvider.setActiveChild(child)` → `pushReplacementNamed(AppRoutes.home)`.
3. Crear: el diálogo valida solo que el nombre no esté vacío (si está vacío, no hace nada); la foto se elige con `pickImage(maxWidth: 400, imageQuality: 70)` → bytes → data URL (cualquier error se traga en silencio: sin foto, avatar de color).
4. `ChildrenProvider.createChild(name, age, colorARGB, photo)` → repo (genera id, append, save) → recarga → devuelve el creado.
5. Borrar: doble confirmación (paso 1 "Siguiente", paso 2 "Conservar"/"Borrar para siempre") → `deleteChild(id)` → repo filtra por id, guarda y `await purgePictosForChild(id)` → `session.clearIfDeleted(id)` (RF2.8).

### Nota sobre la sesión

- `SessionProvider` vive **por encima del `MaterialApp`** (`PictoCommApp.build`): por eso el chico activo sobrevive la navegación entre pestañas (RF2.2), aunque no la reapertura de la app.
- El idioma de la interfaz **no** depende de la sesión: cambiar de niño no cambia el idioma, y borrar un perfil no toca el idioma almacenado (RF4).

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Sin perfiles creados | Estado vacío con botón directo a crear el primer perfil |
| Nombre vacío al crear | El diálogo no hace nada (sin mensaje de error) |
| Sin foto al crear | Avatar cae al círculo de color con inicial |
| Cámara en web | Opción deshabilitada con aviso (limitación del navegador) |
| Borrar perfil | Doble confirmación; purga sus pictos en cascada |
| Borrar el chico activo | La sesión queda sin chico activo (`clearIfDeleted`) |
| Error de carga | La pantalla selector/perfil muestra el mensaje del error |
| Dos creaciones en el mismo microsegundo | No colisionan: id con contador además del timestamp |

## Limitaciones conocidas

- La sesión activa **no se persiste**: cada apertura de app arranca en el selector (decisión v1; pendiente decidir si el login/selector recuerda lo último).
- La **edición de perfiles** es v2 (fuera de alcance); el repositorio ya expone `updateChild` pero la UI no lo usa.
- El diálogo `AddChildDialog` no muestra error cuando el nombre está vacío (simplemente no envía); es una UX más silenciosa que la de los formularios del catálogo.
- La edad no se pide en la UI (v1 sin edad); la entidad la conserva opcionalmente para uso futuro.

---

Volver a [`0000-index.md`](../0000-index.md).
