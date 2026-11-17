# REQ-CAT-02 — Pictos multicategoría y edición de custom

**Mockup:** `docs/prototipos/wireframes.pen` → frames `Home`, `Pictogramas`, `Categoría`, `Detalle picto`, `Nuevo pictograma` (nuevo: `Editar picto`, `Editar catálogo` — a definir en implementación)
**Specs vigentes:** (se crean tras implementar — este REQ está en diseño)
**Archivos implicados:** `lib/features/catalog/domain/entities/picto.dart`, `.../data/models/picto_model.dart`, `.../data/repositories/local_picto_repository.dart`, `.../data/datasources/custom_catalog_data_source.dart`, `.../presentation/screens/add_picto_screen.dart` (+ pantalla de edición), `.../picto_detail_screen.dart`, `.../add_category_screen.dart`, `.../category_screen.dart`, `.../providers/`, `src/backend/` (formato JSON compartido)

---

## 1. Objetivo

Hoy un picto vive en **un solo catálogo** (se lo crea "dentro" de uno) y los custom **no se pueden corregir**: si el adulto escribió mal el nombre, su única salida es borrarlo y recrearlo. Este requerimiento define:

1. **Pertenencia múltiple**: un picto pertenece a **1 o más categorías**.
2. **Creación global**: "Nuevo pictograma" desde el botón (+) sin estar dentro de una categoría, marcando ahí mismo el/los catálogos.
3. **Edición**: renombrar pictos y categorías custom (y en pictos también imagen y categorías), cerrando el pendiente v2 de REQ-CAT-01.

Decisiones del usuario: sí a multi-categoría en esta iteración (agrupado con el backend bidireccional, REQ-BCK-02); sí a edición en la app ahora; el backend sube pictos **y** categorías custom.

## 2. Estado actual

Implementado (REQ-CAT-01, estado al 2026-11-16):

- `Picto.categoryId` es un único string; la creación exige elegir una categoría (chips de selección simple) y solo se llega desde (+) en modo adulto.
- No existe UI de edición: RF-3.7 deja los pictos legacy sin dueño "visibles para todos hasta que se agregue edición (v2)".
- Borrar una categoría elimina en cascada los pictos de esa categoría del chico activo; los de otros chicos quedan apuntando a un id de categoría inexistente (huérfanos).

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Pertenencia múltiple | `Picto.categoryIds` (lista no vacía); JSON compat con `categoryId` de v1 | **A implementar** |
| Creación global | (+) → Nuevo pictograma: imagen + nombre + 1..n categorías (multi-select) | **A implementar** |
| Entrada desde categoría | Crear picto dentro de una categoría pre-selecciona esa categoría (se pueden sumar otras) | **A implementar** |
| Visibilidad en grillas | Un picto multicategoría aparece en **cada una** de sus categorías | **A implementar** |
| Edición de picto | Nombre, imagen (mismas fuentes) y categorías; solo custom | **A implementar** |
| Edición de categoría | Nombre y color; solo custom | **A implementar** |
| Dueño en edición | Pictos legacy sin dueño (RF-3.7): asignables al editar | **A implementar** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-3.13 | Un picto pertenece a **1 o más categorías** (`categoryIds`). La creación y la edición permiten marcar varias con chips multi-select; no se puede guardar sin ninguna. |
| RF-3.14 | La creación de picto disponible desde (+) (entrada global) **no exige categoría previa**: se eligen las categorías en el formulario. Al crear desde la pantalla de una categoría, esa categoría viene pre-seleccionada y se pueden sumar otras. |
| RF-3.15 | Las grillas filtran por pertenencia: un picto con N categorías aparece en las N pantallas de categoría y en todas las pestañas donde hoy aparece (Home, Pictogramas, Comunicar). |
| RF-3.16 | **Edición de picto custom**: desde el detalle (lápiz) se edita nombre, imagen (mismas fuentes que la creación: galería/cámara/URL) y categorías. Guardar actualiza `updatedAt` y recarga las pantallas. |
| RF-3.17 | **Edición de categoría custom**: nombre y color. Renombrar no rompe nada: la pertenencia de los pictos es por id. El catálogo incluido no se edita. |
| RF-3.18 | Solo los custom son editables: bundled y remote no muestran lápiz (UI) y el repositorio rechaza la edición. Con sesión de chico, solo lo del chico activo; en gestión (sin sesión), cualquier custom. |
| RF-3.19 | Los pictos legacy sin dueño (RF-3.7) pueden **asignarse a un chico al editarlos**; si el adulto no elige uno, quedan sin dueño (visibles para todos). |
| RF-3.20 | **Borrado de categoría con multi-pertenencia**: borrar una categoría quita esa membresía de los pictos; los que quedan **sin ninguna categoría** y son del chico activo se eliminan en cascada; los de otros chicos que quedan sin categoría sobreviven como huérfanos (como hoy). La doble confirmación avisa esta cantidad. |
| RF-3.21 | La edición respeta las reglas de visibilidad y pertenencia vigentes (RF-3.4/3.6): un picto editado sigue siendo de su chico, salvo asignación explícita de RF-3.19. |

## 5. Requerimientos no funcionales

| ID | Requerimiento |
|---|---|
| RNF-3.8 | El modelo pasa a `categoryIds: List<String>` (inmutable, no vacío en dominio). **Compat JSON**: si el JSON trae `categoryId` (formato v1), se migra a `[categoryId]` al leer; siempre se escribe el formato nuevo. |
| RNF-3.9 | El formato JSON es **compartido con el backend** (`PictoModel`): cambiar el campo exige actualizar `src/backend/data/seed.json` y `src/backend/lib/src/` en el mismo cambio (regla del repo). |
| RNF-3.10 | El render de imagen sigue centralizado en el switch por `PictoSource` (`PictoCard`/`PictoImage`); la edición no duplica lógica de render. |
| RNF-3.11 | Creación y edición comparten el **mismo formulario** (widget de imagen + nombre + categorías multi-select); solo cambian título, valores iniciales y acción. |
| RNF-3.12 | La validación de edición se duplica en UI (lápiz condicional) y repositorio (por si el estado cambió entre build y tap), igual que el borrado (RNF-3.6). |
| RNF-3.13 | Todo texto nuevo de edición va a i18n (es/en/pt, RF-4.x de REQ-IDI-01). |

## 6. Casos de uso

### UC-02.1 — Crear un picto en varios catálogos

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Agregar un picto que viva en más de un catálogo (ej. "leche" en Alimentos y en Rutina) |
| **Precondiciones** | Modo adulto con sesión de chico activa |
| **Disparador** | (+) → Nuevo pictograma (desde cualquier pantalla) |

**Flujo principal:**
1. Elige imagen (galería/cámara/URL) y nombre.
2. Marca **una o varias** categorías (chips multi-select); si entró desde una categoría, esa ya está marcada.
3. Guarda: el picto queda en todas las categorías marcadas, del chico activo.
4. REQ-BCK-02: el cambio se encola y sube al backend en background.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Sin categoría marcada | Error visible, no se guarda |
| 2 | Sin chico activo / sin nombre / sin imagen | Igual que REQ-CAT-01 (UC-01.1) |

**Postcondiciones:** Picto visible en cada categoría marcada para su chico.

### UC-02.2 — Editar un picto custom

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Corregir nombre/imagen/categorías de un picto |
| **Precondiciones** | Detalle de un picto custom editable (RF-3.18) |
| **Disparador** | Lápiz en el detalle |

**Flujo principal:**
1. El formulario abre precargado con los valores actuales.
2. El adulto cambia lo que necesita y guarda.
3. `updatedAt` avanza; las pantallas se recargan; el cambio se encola para el backend (REQ-BCK-02).

**Flujos alternativos:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Picto bundled/remote | Sin lápiz; el repo rechaza |
| 2 | Picto de otro chico con sesión | Sin lápiz |
| 3 | Picto legacy sin dueño | Editable; ofrece asignar chico (RF-3.19) |

**Postcondiciones:** Picto actualizado localmente y pendiente de subida.

### UC-02.3 — Borrar una categoría con pictos multicategoría

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Eliminar una categoría custom |
| **Precondiciones** | Categoría custom |
| **Disparador** | Papelera en su pantalla (doble confirmación, como UC-01.3 de REQ-CAT-01) |

**Flujo principal:**
1. Diálogo 1 avisa cuántos pictos **se eliminan** (quedan sin ninguna categoría y son del chico activo) y cuántos solo **pierden esta membresía**.
2. Confirmación final; la categoría se borra, las membresías se quitan, la cascada corre.

**Postcondiciones:** Categoría eliminada; ningún picto apunta a un id inexistente.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-3.11 | **Given** la creación global de picto, **when** se marcan 2 categorías y se guarda, **then** el picto aparece en ambas grillas y en Pictogramas una sola vez. |
| CA-3.12 | **Given** la creación desde una categoría, **when** se abre el formulario, **then** esa categoría viene marcada y se pueden sumar otras. |
| CA-3.13 | **Given** el formulario de picto, **when** se guarda sin ninguna categoría, **then** error visible y no se guarda. |
| CA-3.14 | **Given** un picto custom del chico activo, **when** se edita su nombre y se guarda, **then** el detalle y las grillas muestran el nombre nuevo y `updatedAt` avanza. |
| CA-3.15 | **Given** un picto bundled o remote (o de otro chico con sesión), **when** se abre su detalle, **then** no hay lápiz y el repositorio rechaza la edición. |
| CA-3.16 | **Given** un picto legacy sin dueño, **when** se edita y se asigna un chico, **then** pasa a ser visible solo para ese chico (RF-3.6). |
| CA-3.17 | **Given** una categoría custom compartida por pictos con otras categorías, **when** se borra con doble confirmación, **then** esos pictos sobreviven sin esa membresía y solo se eliminan los que quedaron sin ninguna (del chico activo). |
| CA-3.18 | **Given** un cache/storage en formato v1 (`categoryId`), **when** se lee, **then** se migra a `categoryIds` de un elemento sin pérdida. |
| CA-3.19 | **Given** una categoría custom, **when** se renombra, **then** los pictos conservan su pertenencia (por id) y no hay duplicados. |

Cobertura de tests (prevista): `test/catalog_models_test.dart` (migración JSON), `test/agregar_catalogo_test.dart` (multi-select, edición), `test/cascada_test.dart` (borrado de categoría con multi-pertenencia), fakes actualizados al nuevo contrato.

## 8. Fuera de alcance

- Reordenar pictos dentro de una categoría; duplicar picto.
- Editar elementos del catálogo incluido o remotos.
- Permisos granulares por categoría ("esta categoría solo la ve X"): sigue las reglas de pertenencia por chico.
- Buscador integrado de imágenes (Google): backend, REQ-BCK-02+.
- Límite de tamaño/compresión por imagen (sigue la pregunta abierta de REQ-CAT-01).

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Multi-categoría | Confirmado (usuario): un picto vive en 1..n catálogos, elegidos en el formulario; agrupado en esta iteración con el backend bidireccional. |
| 2 | Edición | Confirmado (usuario): sí, ahora; incluye nombres y (en pictos) imagen y categorías. |
| 3 | Edición de categoría | Decisión (mi llamada): también nombre y color — no tiene sentido poder corregir el picto y no su catálogo. |
| 4 | Asignar dueño al editar | Decisión (mi llamada): solo pictos legacy sin dueño (cierra RF-3.7); los custom con dueño no se reasignan desde la UI. |
| 5 | Cascada con multi-pertenencia | Decisión (mi llamada): quitar membresía + borrar solo los que quedan sin ninguna (del chico activo); avisa la cantidad en la confirmación. |
| 6 | Formato JSON | Decisión (mi llamada): `categoryIds` nuevo campo; `categoryId` de v1 se acepta solo para migrar (RNF-3.8). |
| 7 | Compartir formulario | Decisión (mi llamada): un solo widget para crear/editar (RNF-3.11); evita que la edición diverja de la creación. |
