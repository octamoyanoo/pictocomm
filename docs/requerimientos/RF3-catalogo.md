# RF3 — Catálogo y pictogramas personalizados

| Campo | Valor |
|---|---|
| Estado | En implementación |
| Versión | 1.0 |
| Fecha | 2026-11-05 |

## Descripción

El catálogo incluido viene con la app, pero **los pictos que de verdad comunican
son los de la casa**: la banana real, la abuela, el juguete favorito. RF3 define
cómo se crean, a quién pertenecen y cómo se borran.

Decisiones del usuario: v1 = pictos + borrado (doble confirmación); pictos
**por perfil**; imagen desde galería, cámara y **URL pegada** (el buscador
integrado de Google queda para el backend, v2); sí a la **foto del niño**
(rinde RF2.12).

## Requisitos

### Creación de pictos personalizados

- **RF3.1** — El adulto crea pictos desde modo adulto (+ → Nuevo pictograma) eligiendo: imagen, nombre y categoría.
- **RF3.2** — Fuentes de imagen: **galería, cámara** y **URL web pegada**. La imagen elegida se almacena **localmente** (bytes en el dispositivo): después de crearla, el picto funciona sin conexión. En web, la opción cámara queda deshabilitada con aviso (limitación del navegador).
- **RF3.3** — Imagen desde URL: la app descarga los bytes y los guarda. Si el sitio bloquea la descarga (cors en web), mensaje claro con la alternativa ("guardá la imagen y elegila de la galería").
- **RF3.4** — Los pictos personalizados pertenecen al **perfil del niño activo** (`childProfileId`): se crean solo con sesión iniciada; requieren chico elegido.

### Visibilidad

- **RF3.5** — Catálogo incluido: lo ve cualquier chico del dispositivo.
- **RF3.6** — Pictos personalizados: los ve **solo su chico**, en todas las pestañas (home, pictogramas, comunicar, categoría).
- **RF3.7** — Compatibilidad: pictos personalizados creados antes de RF3 (sin chico asociado) siguen visibles para todos hasta que se agregue edición (v2).

### Borrado

- **RF3.8** — Borrar picto personalizado: papelera en el detalle del picto, con **doble confirmación**. El catálogo incluido no se puede borrar.
- **RF3.9** — Borrar categoría personalizada: papelera en su pantalla, con **doble confirmación** y aviso de que **elimina en cascada sus pictos**. Afecta solo pictos de ese chico en esa categoría.
- **RF3.10** — El borrado tiene sentido en modo adulto; los chicos no acceden (los detalles están tras navegación de gestión).

### Foto del niño (RF2.12)

- **RF3.11** — Al crear el perfil, el adulto puede elegir **foto del niño** (galería/cámara). Si no hay, el avatar cae al círculo de color con inicial.
- **RF3.12** — La foto se guarda local y se muestra en selector de chico, home y lista de perfiles.

## Preguntas abiertas

| # | Pregunta | Estado |
|---|---|---|
| 1 | Límite de tamaño por imagen URL vs galería (¿comprimir? ¿rechazar > N MB?) | Pendiente |
| 2 | Editar picto personalizado (renombrar, cambiar imagen/categoría) | v2 |
| 3 | Categorías custom: ¿visibles para todos? | Sí, v1 — a definir découpage en versión de perfiles (v2) |

## Notas de implementación (no normativas)

- `Picto.childProfileId` nullable: `bundled` siempre `null`; `custom` lleva su chico; `remote` (futuro) lo definirá el backend.
- La descarga de URL usa `http` (funciona en web vía cors del navegador; en móvil sin restricción).
- Categoría custom viaja con flag `custom` del lado de presentación/persistencia: las **incluídas** no se borran (RF3.8) y quedan solo lectura.
- Cascada del borrado de categoría (RF3.9): con sesión activa se depuran **solo los pictos con dueño == chico activo**; los de otro chico y los legacy sin dueño (RF3.7) sobreviven. Los sobrevivientes quedan sin categoría visible hasta que el catálogo se recree con el mismo nombre (slug) o se agregue edición (v2).
- Borrado de picto (RF3.8): el repositorio valida con el chico de la sesión activa que el picto sea suyo; sin sesión (modo gestión) borra cualquier custom. La papelera del detalle solo se muestra al dueño.
- Borrar un perfil purga sus pictos (RF2.7): el wiring es por composición en `core/di` (`purgePictosForChild`), sin dependencia cross-feature.
