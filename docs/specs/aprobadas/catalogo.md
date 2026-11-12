# Catálogo y pictogramas

Funcionalidad que **describe cómo se ven las categorías y los pictos, cómo el adulto crea pictogramas y categorías personalizadas, a quién pertenecen y cómo se borran** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- **Catálogo incluido**: categorías y pictos que vienen con la app, inferidos de los assets (`assets/images/<categoría>/<archivo>.png`), visibles para **cualquier chico** del dispositivo. No se puede borrar.
- **Pictogramas personalizados**: el adulto los crea desde modo adulto (+ → Nuevo pictograma) eligiendo **imagen, nombre y categoría**; pertenecen al **perfil del niño activo** y funcionan sin conexión (la imagen se guarda como data URL base64 dentro del JSON, en el dispositivo).
- **Categorías personalizadas**: el adulto las crea (+ → Nuevo catálogo) con nombre y color de una paleta fija; se borran con doble confirmación y **cascada selectiva** de sus pictos.
- **Visibilidad**: con chico activo, se ven el catálogo incluido + los pictos custom de ese chico (+ los legacy sin dueño); sin sesión de chico (modo gestión), se ven todos los custom.
- La pantalla **Home** lista las categorías con búsqueda y conteos; **Pictogramas** muestra la grilla plana de todos los pictos visibles con búsqueda; **Categoría** muestra los pictos de una categoría con papelera si es custom; el **detalle del picto** muestra papelera si es custom borrable.

## Experiencia de usuario

1. **Home** (`/home`): header con saludo al chico activo (avatar + "Hola, {nombre}" o saludo genérico), campo de búsqueda (filtra categorías por nombre), fila "Mis catálogos" con **Ver todos** → Pictogramas, y la lista/grilla de categorías (ícono según nombre, color, conteo de pictos, chevron). Botón (+) abre el menú *Nuevo catálogo / Nuevo pictograma*. Botón de cambio de chico (`swap_horiz`) vuelve al selector.
2. **Pictogramas** (`/pictogramas`): grilla plana de todos los pictos visibles (2–5 columnas según ancho) con búsqueda por nombre. Tap → detalle.
3. **Categoría** (`/category`): header con back, nombre, conteo y — **solo si la categoría es custom** — botón papelera. Grilla de pictos de la categoría; si está vacía, texto central.
4. **Detalle del picto** (`/picto`): fondo negro, label grande, imagen centrada, botón Cerrar y — solo para customs borrables — papelera.
5. **Nuevo pictograma** (`/add-picto`): tile de imagen (galería / cámara / URL pegada), campo nombre, chips de categoría (o aviso si no hay categorías aún) y botón Guardar con validaciones visibles en rojo.
6. **Nuevo catálogo** (`/add-category`): nombre, preview con color y paleta fija de 8 colores; Guardar devuelve la categoría creada.
7. **Borrado**: siempre **doble confirmación** (diálogo 1 "Siguiente" con las consecuencias; diálogo 2 "Conservar" / "Borrar para siempre" en rojo).

## Cómo lo hace (implementación)

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Home | `lib/features/catalog/presentation/screens/home_screen.dart` | Búsqueda de categorías, grilla 1–3 columnas, `pictoCountOf(id)`; `CatalogFailureState` se renderiza como estado vacío (falla silenciosa) |
| Pictogramas | `lib/features/catalog/presentation/screens/pictogramas_screen.dart` | Grilla plana por `PictosProvider`, búsqueda por `picto.label` |
| Categoría | `lib/features/catalog/presentation/screens/category_screen.dart` | Recibe `Category` por argumentos de ruta; papelera solo si `category.custom`; al borrar vuelve a home |
| Detalle | `lib/features/catalog/presentation/screens/picto_detail_screen.dart` | Papelera si `picto.source == custom` y `_allowsDelete` (dueño o modo gestión); bundled nunca |
| Crear picto | `lib/features/catalog/presentation/screens/add_picto_screen.dart` | Galería/cámara/URL → data URL (`DataUrl.encode/decode` en `lib/core/utils/data_url.dart`); cámara `enabled: !kIsWeb`; validaciones en orden |
| Crear categoría | `lib/features/catalog/presentation/screens/add_category_screen.dart` | Paleta fija de 8; slug del nombre como id; error de duplicado detectado por texto (`'Ya existe'`) → `duplicateCategory` |
| Card de picto | `lib/features/catalog/presentation/widgets/picto_card.dart` | Render único según `PictoSource` (el `switch` vive aquí) + flash de selección (ver [comunicar.md](./comunicar.md)) |
| Estado catálogo | `.../presentation/providers/catalog_provider.dart` | Categorías + conteos; `createCategory/createPicto/deletePicto/deleteCategory` (recargan al terminar) |
| Estado pictos | `.../presentation/providers/pictos_provider.dart` | Categorías + pictos visibles; helpers `pictosOf(categoryId)` |
| Repositorio | `lib/features/catalog/data/repositories/local_picto_repository.dart` | Implementa `CategoryRepository` + `PictoRepository`; valida visibilidad y borrado (RF3.6–3.9); crea ids `custom-<microsegundos>-<contador>` |
| Catálogo incluido | `.../data/datasources/local_catalog_data_source.dart` | Lee `AssetManifest`: `assets/images/<categoria>/<archivo>.<ext>` → categoría + picto; cualquier error → lista vacía |
| Pictos custom | `.../data/datasources/custom_catalog_data_source.dart` | SharedPreferences `pictocomm.custom_categories` + `pictocomm.custom_pictos` (JSON); cascada selectiva de borrado |
| Modelos | `.../data/models/` | `PictoModel`: `{ id, label, categoryId, imageUrl (data URL), source, createdAt/updatedAt (ISO-8601 UTC), childProfileId? }` — backend-ready. `CategoryModel`: `{ id, name, color "#RRGGBB", icon, custom? }` |
| Backend-ready | `.../data/datasources/remote_catalog_data_source.dart` | Contrato del backend; la impl lanza `UnimplementedFeatureException` y **nunca se llama en lectura** (local-first; si un test la dispara, hay bug) |

### Flujo paso a paso (crear picto personalizado)

1. El adulto toca (+) → *Nuevo pictograma* → `/add-picto` (recarga `CatalogProvider` en microtask).
2. Elige imagen: **galería** (`pickImage(maxWidth: 600, imageQuality: 70)` → bytes → data URL, mime por extensión), **cámara** (solo móvil) o **URL pegada** (`http.get` con timeout de 15 s; status ≠ 200 o falla de red → error `urlDownloadError` con la alternativa de guardar la imagen y elegirla de la galería).
3. Completa nombre y elige categoría (chips deseleccionables; sin categorías, aviso `firstCatalogWarning`).
4. Guardar valida en orden: chico activo elegido (`selectChildFirst`) → nombre (`nameFieldRequired`) → imagen (`imageRequired`) → categoría (`categoryRequired`).
5. `CatalogProvider.createPicto` → repo re-valida nombre e imagen, fuerza `source: custom`, `childProfileId` del chico activo, timestamps UTC y genera el id → persiste en SharedPreferences → recarga → `pop`.
6. Al volver, el Home recarga y el picto ya es visible para **solo ese chico** en todas las pestañas.

### Flujo paso a paso (borrar categoría custom)

1. En `/category` de una categoría custom, el adulto toca la papelera.
2. Diálogo 1: "¿Borrar {nombre}?" con la cantidad de pictos que elimina → **Siguiente**.
3. Diálogo 2: "Borrar para siempre" → `PictosProvider.deleteCategory(id)` con el chico de la sesión activa.
4. El repo valida que no sea bundled (`DataSourceException` si lo es) y la datasource ejecuta la **cascada selectiva**: con sesión, elimina solo los pictos de esa categoría cuyo dueño sea el chico activo; los de otros chicos y los legacy sin dueño **sobreviven** (quedan sin categoría visible hasta que se recree una categoría con el mismo slug o llegue la edición en v2).
5. Éxito → `pushNamedAndRemoveUntil(home)`; error → `SnackBar` con el mensaje.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Crear picto sin chico activo | Bloqueado: `selectChildFirst` (los pictos requieren dueño) |
| Crear picto/categoría con nombre vacío | Error visible en rojo (`nameFieldRequired`) |
| Crear picto sin imagen o sin categoría | Error visible (`imageRequired` / `categoryRequired`) |
| Categoría con nombre duplicado (contra incluidas también) | `duplicateCategory` con mensaje claro |
| URL que no descarga (CORS en web, red) | Mensaje con la alternativa de galería |
| Cámara en web | Deshabilitada con aviso |
| Borrar picto/categoría del catálogo incluido | Bloqueado: bundled nunca muestra papelera y el repo lo rechaza |
| Borrar picto de otro chico (con sesión) | Bloqueado: no hay papelera en UI y el repo rechaza por si el estado cambió entre build y tap |
| Cascada de categoría | Con sesión solo borra pictos del chico activo; otros dueños y legacy sobreviven |
| Borrar un perfil | Purga sus pictos custom en cascada (por composición en `core/di`) |
| Pictos legacy (creados antes de RF3, sin dueño) | Visibles para todos hasta que exista edición (v2) |
| Falla de carga del catálogo | Home y Pictogramas muestran estado vacío (falla silenciosa) |

## Limitaciones conocidas

- **Editar pictos/categorías** (renombrar, cambiar imagen, mover de categoría) es v2.
- Las imágenes viajan como **data URLs base64 dentro del JSON** de SharedPreferences: el tamaño por imagen está limitado en la práctica por SharedPreferences (pregunta abierta #1 del REQ-CAT-01: límite/compresión aún sin definir).
- La pantalla de pictogramas **no distingue visualmente** bundled vs custom (sin badge): la distinción solo existe en el borrado.
- El home trata `CatalogFailureState` igual al estado vacío: el usuario no ve un error explícito de carga del catálogo.
- El buscador integrado de imágenes (Google) queda para el backend (v2); hoy solo galería/cámara/URL.
- Las categorías custom son visibles para todos los chicos (decisión v1); el découpage por perfil es v2.

---

Volver a [`0000-index.md`](../0000-index.md).
