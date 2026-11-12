# REQ-CAT-01 — Catálogo y pictogramas personalizados

**Mockup:** `docs/prototipos/wireframes.pen` → frames **`Home`**, **`Pictogramas`**, **`Categoría`**, **`Detalle picto`**, **`Nuevo pictograma`**, **`Nuevo catálogo`**
**Specs vigentes:** [`catalogo.md`](../../specs/aprobadas/catalogo.md), [`perfiles.md`](../../specs/aprobadas/perfiles.md) (sesión activa)
**Archivos implicados:** `lib/features/catalog/presentation/screens/home_screen.dart`, `.../pictogramas_screen.dart`, `.../category_screen.dart`, `.../picto_detail_screen.dart`, `.../add_picto_screen.dart`, `.../add_category_screen.dart`, `lib/features/catalog/presentation/providers/catalog_provider.dart`, `.../pictos_provider.dart`, `lib/features/catalog/domain/repositories/picto_repository.dart`, `.../category_repository.dart`, `lib/features/catalog/data/repositories/local_picto_repository.dart`, `lib/features/catalog/data/datasources/`, `lib/core/utils/data_url.dart`

---

## 1. Objetivo

El catálogo incluido viene con la app, pero **los pictos que de verdad comunican son los de la casa**: la banana real, la abuela, el juguete favorito. Este requerimiento define cómo se crean los pictogramas y categorías personalizados, a quién pertenecen y cómo se borran.

Decisiones del usuario: v1 = pictos + borrado (doble confirmación); pictos **por perfil**; imagen desde galería, cámara y **URL pegada** (el buscador integrado de Google queda para el backend, v2); sí a la **foto del niño** (rinde RF-2.12 de REQ-PER-01).

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-12):

- El catálogo incluido se infiere de los assets (`assets/images/<categoría>/<archivo>`); no está hardcodeado.
- Creación de pictos custom con imagen de galería, cámara (móvil) o URL pegada; se guardan como data URL base64 en SharedPreferences, pertenecen al chico activo y funcionan sin conexión.
- Creación de categorías custom con slug + color de paleta fija; duplicados rechazados (contra incluidas también).
- Borrado con doble confirmación: pictos desde el detalle, categorías con cascada selectiva; el catálogo incluido no se borra.
- Foto del niño implementada: opcional al crear el perfil, se muestra en selector, Home y lista.

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Creación de pictos | Imagen (galería/cámara/URL) + nombre + categoría | **Implementado** |
| Almacenamiento de imagen | Local: data URL base64 dentro del JSON del picto | **Implementado** |
| Pertenencia | `childProfileId` del chico activo; requieren sesión de chico | **Implementado** |
| Visibilidad | Incluidos para todos; custom solo de su chico (+ legacy sin dueño) | **Implementado** |
| Borrado de picto | Papelera en el detalle, doble confirmación, solo customs | **Implementado** |
| Borrado de categoría | Papelera en su pantalla, doble confirmación, cascada selectiva | **Implementado** |
| Foto del niño | Opcional al crear perfil; visible en selector, Home y lista | **Implementado** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-3.1 | El adulto crea pictos desde modo adulto (+ → Nuevo pictograma) eligiendo: imagen, nombre y categoría. |
| RF-3.2 | Fuentes de imagen: **galería, cámara** y **URL web pegada**. La imagen elegida se almacena **localmente** (bytes en el dispositivo): después de crearla, el picto funciona sin conexión. En web, la opción cámara queda deshabilitada con aviso (limitación del navegador). |
| RF-3.3 | Imagen desde URL: la app descarga los bytes y los guarda. Si el sitio bloquea la descarga (cors en web), mensaje claro con la alternativa ("guardá la imagen y elegila de la galería"). |
| RF-3.4 | Los pictos personalizados pertenecen al **perfil del niño activo** (`childProfileId`): se crean solo con sesión iniciada; requieren chico elegido. |
| RF-3.5 | Catálogo incluido: lo ve cualquier chico del dispositivo. |
| RF-3.6 | Pictos personalizados: los ve **solo su chico**, en todas las pestañas (home, pictogramas, comunicar, categoría). |
| RF-3.7 | Compatibilidad: pictos personalizados creados antes de RF-3 (sin chico asociado) siguen visibles para todos hasta que se agregue edición (v2). |
| RF-3.8 | Borrar picto personalizado: papelera en el detalle del picto, con **doble confirmación**. El catálogo incluido no se puede borrar. |
| RF-3.9 | Borrar categoría personalizada: papelera en su pantalla, con **doble confirmación** y aviso de que **elimina en cascada sus pictos**. Afecta solo pictos de ese chico en esa categoría. |
| RF-3.10 | El borrado tiene sentido en modo adulto; los chicos no acceden (los detalles están tras navegación de gestión). |
| RF-3.11 | Al crear el perfil, el adulto puede elegir **foto del niño** (galería/cámara). Si no hay, el avatar cae al círculo de color con inicial. |
| RF-3.12 | La foto se guarda local y se muestra en selector de chico, home y lista de perfiles. |

## 5. Requerimientos visuales / no funcionales

| ID | Requerimiento |
|---|---|
| RNF-3.1 | `Picto.childProfileId` nullable: `bundled` siempre `null`; `custom` lleva su chico; `remote` (futuro) lo definirá el backend. |
| RNF-3.2 | La descarga de URL usa `http` con timeout de 15 s; mime desde `content-type` (default `image/jpeg`). |
| RNF-3.3 | El switch de render por `PictoSource` (bundled/custom/remote) vive en un solo widget (`PictoCard`). |
| RNF-3.4 | El catálogo incluido se infiere del `AssetManifest`: `assets/images/<categoría>/<archivo>.png` → categoría humanizada + picto con label del archivo; cualquier error → lista vacía. |
| RNF-3.5 | Las imágenes y la foto viajan como **data URLs base64** dentro del JSON persistido (SharedPreferences); nunca hay archivos en disco ni red en lectura. |
| RNF-3.6 | La validación de borrado se duplica en UI (papelera condicional) y repositorio (por si el estado cambió entre build y tap). |
| RNF-3.7 | Al cambiar de chico en el selector, catálogo y pictos se recargan (`reloadAfterSessionChange`) para respetar la visibilidad. |

## 6. Casos de uso

### UC-01.1 — Crear un pictograma personalizado

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Agregar un picto de la casa para un chico |
| **Precondiciones** | Modo adulto, sesión de chico activa, categorías disponibles |
| **Disparador** | (+) → Nuevo pictograma |

**Flujo principal:**
1. El adulto elige imagen (galería, cámara o URL pegada) y ve el preview.
2. Completa el nombre y elige la categoría (chips deseleccionables).
3. Guarda: el picto se persiste localmente con `childProfileId` del chico activo.
4. El picto es visible solo para ese chico en todas las pestañas.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Sin chico activo | Bloqueado: `selectChildFirst` |
| 2 | Nombre, imagen o categoría faltante | Error visible en rojo, no se guarda |
| 3 | URL no descargable (CORS/red) | Mensaje con la alternativa de galería |
| 4 | Cámara en web | Opción deshabilitada con aviso |
| 5 | Sin categorías creadas | Aviso `firstCatalogWarning` en lugar del selector |

**Postcondiciones:** Picto custom persistido y visible para su chico, incluso sin conexión.

### UC-01.2 — Borrar un pictograma personalizado

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Eliminar un picto custom |
| **Precondiciones** | Detalle del picto; el picto es custom y del chico activo (o modo gestión) |
| **Disparador** | Papelera del detalle |

**Flujo principal:**
1. Diálogo 1: "¿Borrar {nombre}?" → Siguiente.
2. Diálogo 2: "Conservar" / "Borrar para siempre".
3. El picto se elimina y las pantallas se recargan.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Picto del catálogo incluido | Sin papelera (y el repo lo rechaza) |
| 2 | Picto de otro chico (con sesión) | Sin papelera (y el repo lo rechaza) |

**Postcondiciones:** El picto dejó de existir en el dispositivo.

### UC-01.3 — Borrar una categoría personalizada

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Eliminar una categoría custom |
| **Precondiciones** | Pantalla de la categoría; es custom |
| **Disparador** | Papelera del header de la categoría |

**Flujo principal:**
1. Diálogo 1: "¿Borrar {nombre}?" con la cantidad de pictos que elimina → Siguiente.
2. Diálogo 2: confirmación final irreversible.
3. La cascada elimina los pictos de esa categoría **del chico activo**; los de otros chicos y los legacy sin dueño sobreviven.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Categoría del catálogo incluido | Sin papelera (repo rechaza) |
| 2 | Pictos de otros chicos o sin dueño | Sobreviven; quedan sin categoría visible hasta recrear el slug o la edición v2 |

**Postcondiciones:** Categoría eliminada; la app vuelve al Home.

### UC-01.4 — Elegir la foto del niño

| | |
|---|---|
| **Actor** | Adulto responsable |
| **Objetivo** | Poner la cara real del chico en su perfil |
| **Precondiciones** | Diálogo de creación de perfil |
| **Disparador** | Tap al avatar del diálogo |

**Flujo principal:**
1. El adulto elige galería o cámara (cámara solo móvil).
2. La foto se guarda local (data URL) y se muestra en selector, Home y lista de perfiles.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Sin foto / error de imagen | Avatar cae al círculo de color con inicial |

**Postcondiciones:** Perfil con foto visible en todas las pantallas de perfiles.

## 7. Criterios de aceptación

| ID | Criterio (Given / When / Then) |
|---|---|
| CA-3.1 | **Given** el modo adulto con chico activo, **when** se crea un picto con imagen+nombre+categoría, **then** se persiste local y es visible solo para ese chico. |
| CA-3.2 | **Given** la creación de picto, **when** falta chico activo, nombre, imagen o categoría, **then** se muestra el error correspondiente y no se guarda. |
| CA-3.3 | **Given** una imagen de galería, cámara o URL, **when** se elige, **then** se almacena localmente (data URL) y el picto funciona sin conexión. |
| CA-3.4 | **Given** web, **when** se abre el selector de fuente de imagen, **then** la cámara está deshabilitada con aviso. |
| CA-3.5 | **Given** un picto custom del chico activo, **when** se abre su detalle, **then** aparece la papelera; con doble confirmación se borra. |
| CA-3.6 | **Given** un picto bundled o de otro chico, **when** se abre su detalle con sesión, **then** no aparece la papelera. |
| CA-3.7 | **Given** una categoría custom, **when** se borra con doble confirmación, **then** se eliminan sus pictos del chico activo y sobreviven los de otros chicos y los legacy sin dueño. |
| CA-3.8 | **Given** cualquier categoría del catálogo incluido, **when** se intenta borrar, **then** el repo la rechaza (el catálogo incluido no se borra). |
| CA-3.9 | **Given** una categoría con nombre duplicado, **when** se intenta crear, **then** se muestra `duplicateCategory` (colisión contra incluidas incluida). |
| CA-3.10 | **Given** la creación de perfil con foto, **when** se confirma, **then** la foto se muestra en selector, Home y lista; sin foto, avatar de color con inicial. |

Cobertura de tests: `test/agregar_catalogo_test.dart`, `test/catalog_perfil_test.dart`, `test/catalog_models_test.dart` (fakes con el mismo contrato que la implementación real).

## 8. Fuera de alcance

- Editar pictos o categorías personalizadas (renombrar, cambiar imagen/categoría): v2.
- Buscador integrado de imágenes (Google): backend, v2.
- Découpage de categorías custom por perfil: v2 (hoy son visibles para todos).
- Límite de tamaño/compresión por imagen (pregunta abierta #1).
- Subida de imágenes al backend (los pictos custom son locales; `remote` queda para el backend).

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Pertenencia de pictos | Confirmado (usuario): pictos por perfil; el catálogo incluido es de todos. |
| 2 | Fuentes de imagen | Confirmado (usuario): galería, cámara y URL pegada; buscador Google para backend (v2). |
| 3 | Foto del niño | Confirmado (usuario): sí, rinde RF-2.12 de REQ-PER-01. |
| 4 | Compatibilidad legacy | Decisión (mi llamada): pictos sin dueño siguen visibles para todos hasta la edición (v2). |
| 5 | Cascada de categoría | Decisión (mi llamada): selectiva — solo pictos del chico activo; los sobrevivientes quedan huérfanos de categoría. |
| 6 | Doble validación de borrado | Decisión (mi llamada): UI + repositorio, por si el estado cambia entre build y tap. |
| 7 | Formato de almacenamiento | Decisión (mi llamada): data URLs base64 en SharedPreferences (simple y offline; límite de tamaño por definir). |
