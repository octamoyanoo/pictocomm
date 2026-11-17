# Pictos multicategoría y edición de custom (REQ-CAT-02)

Funcionalidad que **hace que un picto pueda vivir en 1 o más catálogos y que los pictos y categorías custom se puedan editar** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md). El requerimiento normativo es [`REQ-CAT-02-catalogo-multicategoria.md`](../../requerimientos/implementados/REQ-CAT-02-catalogo-multicategoria.md).

---

## Qué hace

- **Pertenencia múltiple**: un picto pertenece a **1 o más categorías** (`categoryIds`). Aparece en cada una de sus categorías, en todas las pestañas (Home, Pictogramas, Comunicar), y el contador de cada catálogo lo suma.
- **Creación global**: "Nuevo pictograma" desde (+) no exige entrar a una categoría: se eligen los catálogos en el formulario con **chips multi-select**. Si se entra desde la pantalla de una categoría, esa viene pre-seleccionada (se pueden sumar otras).
- **Edición de picto custom**: lápiz en el detalle → mismo formulario precargado: nombre, imagen (galería/cámara/URL) y categorías.
- **Edición de categoría custom**: lápiz en la pantalla de la categoría → nombre y color, sin cambiar el id (la pertenencia de los pictos es por id).
- **Asignación de dueño (legacy)**: los pictos custom sin chico (RF-3.7) son editables y al editarlos el adulto puede **asignarles un chico** de la lista; si no elige, quedan visibles para todos.
- **Borrado de categoría con cascada revisada**: quita esa membresía de los pictos; los que quedan **sin ninguna categoría** y son del chico activo (o sin dueño) **se eliminan**; los que viven en otras categorías **sobreviven**; los de otros chicos quedan huérfanos (sin categorías, invisibles en las grillas). La doble confirmación muestra ambas cantidades (cuántos se eliminan y cuántos solo pierden la membresía).

## Experiencia de usuario

1. El adulto toca (+) → Nuevo pictograma: elige imagen, nombre, y marca **todos** los catálogos donde vive (por ejemplo "leche" en Alimentos y Rutina).
2. Si un nombre quedó mal escrito: detalle del picto → lápiz → corrige y guarda. Las grillas se refrescan al instante.
3. Un catálogo creado de más se puede renombrar con el lápiz de su pantalla; sus pictos no se enteran (siguen por id).
4. Al borrar un catálogo, el diálogo avisa: "Se borra el catálogo y N pictogramas de este niño" y, si aplica, "Además, M pictogramas pierden este catálogo pero se conservan".

## Cómo lo hace (implementación)

| Parte | Archivo | Rol |
|---|---|---|
| Entidad | `lib/features/catalog/domain/entities/picto.dart` | `categoryIds` (lista) + `belongsTo(id)` + `copyWith` |
| Modelo JSON | `.../data/models/picto_model.dart` | `categoryIds` nuevo; **migración**: si el JSON trae `categoryId` (v1) se lee como lista de uno (RNF-3.8); siempre se escribe el formato nuevo |
| Storage custom | `.../data/datasources/custom_catalog_data_source.dart` | `savePicto`/`saveCategory` con **upsert por id** (edición); `deleteCategory` reescrita para la cascada multicategoría (RF-3.20); los sobrevivientes avanzan `updatedAt` (viaja al backend) |
| Repositorio | `.../data/repositories/local_picto_repository.dart` | Filtro por pertenencia en `getPictos`; `createPicto` exige ≥1 categoría; `updatePicto` (RF-3.16/3.18/3.19) y `updateCategory` (RF-3.17, colisión de slug rechazada) |
| Providers | `catalog_provider.dart`, `pictos_provider.dart` | Conteos por pertenencia; `pictosOf` por pertenencia; `updatePicto`/`updateCategory` + `deletionImpact` (cantidades del diálogo); `refresh()` público |
| Formulario compartido | `.../screens/add_picto_screen.dart` | Crea **o edita** (RNF-3.11): `FilterChip` multi-select, preselección por ruta, dropdown de asignación de chico para legacy |
| Edición de categoría | `.../screens/add_category_screen.dart` | Modo edición con `categoryToEdit` precargado |
| Botones | `picto_detail_screen.dart` (lápiz en detalle), `category_screen.dart` (lápiz + impacto de borrado) | Condicionales por `source` y dueño (RF-3.18), validación duplicada en repositorio |
| Rutas | `lib/app.dart`, `lib/core/constants/app_routes.dart` | `addPicto` acepta `Picto` (edita), `Category` (preselecciona) o nada (crea); `addCategory` acepta `Category` (edita) |
| i18n | `lib/l10n/app_*.arb` | Claves nuevas: `editPictoTitle`, `editCategoryTitle`, `updatePictoButton`, `assignChild*`, `deleteCategoryKeepContent`, `categoryRequired` ("al menos una") en es/en/pt |

### Compatibilidad de datos

- Storage viejo en `categoryId` se **migra al leer** (lista de un elemento); se pierde nada (CA-3.18).
- El catálogo remoto (backend) también viaja con `categoryIds` (RNF-3.9): seed actualizado en `src/backend/data/seed.json` y API serializando listas.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Guardar sin ninguna categoría | Error visible, no se guarda (RF-3.13) |
| Editar un bundled/remote | Sin lápiz (UI) y el repositorio rechaza (RF-3.18) |
| Editar picto de otro chico con sesión | Sin lápiz y el repositorio rechaza |
| Picto huérfano tras cascada (otro chico) | Sobrevive con lista vacía: invisible en grillas de categoría, visible en Pictogramas |
| Renombrar categoría a un nombre que colisiona | `DuplicateCatalogException` (mismo criterio que crear) |
| Storage en formato v1 | Migración automática al leer (CA-3.18) |
| `updatedAt` | La edición avanza la fecha (para el backend); los sobrevivientes de cascada también |

## Limitaciones conocidas

- Reordenar pictos dentro de una categoría y duplicar pictos: fuera de alcance.
- Los custom sin dueño que quedan huérfanos tras la cascada no suben al backend (no tienen dueño; RF-5.16 del REQ-BCK-02).
- No hay tests de widget del flujo de edición (image picker difícil de mockear); la cobertura es a nivel repositorio + el comportamiento de UI usa el formulario ya probado de creación.

---

Volver a [`0000-index.md`](../0000-index.md).
