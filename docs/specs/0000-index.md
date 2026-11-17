# Funcionalidades

Listado general de las funcionalidades implementadas en **PictoComm**, con una descripción breve de lo que permiten hacer.

> Cada funcionalidad se detalla en un archivo propio dentro de `docs/specs/`.
>
> **(v2)** — marca los archivos que cambiaron: son funcionalidades que ya fueron vistas y se implementaron sin errores, con su spec actualizado a la segunda versión (v2).

---

## Acceso y sesión

- [**Acceso (login, registro y sesión)**](./aprobadas/acceso.md) — Cuentas reales contra el backend: registro y login con credenciales verificadas, sesión recordada (la app abre directo en el selector) y logout desde Perfil; los perfiles de chico quedan atados a la cuenta.

## Perfiles de niño

- [**Selector de chico**](./aprobadas/perfiles.md) — Grilla de tarjetas grandes (avatar + nombre) donde se elige para quién es la sesión de comunicación; el último chico usado de la cuenta aparece preseleccionado ("Último en usar"); estado vacío con acceso directo a crear el primer perfil.
- [**Sesión activa**](./aprobadas/perfiles.md) — El chico elegido es un estado a nivel app que sobrevive la navegación; el catálogo y los pictos visibles se refrescan al cambiarlo.
- [**Gestión de perfiles (modo adulto)**](./aprobadas/perfiles.md) — Crear perfiles (nombre + color + foto opcional), listarlos y borrarlos con doble confirmación (purga en cascada sus pictos).

## Catálogo y pictogramas

- [**Catálogo incluido**](./aprobadas/catalogo.md) — Categorías y pictos que vienen con la app (inferidos de los assets), visibles para cualquier chico del dispositivo.
- [**Pictogramas personalizados**](./aprobadas/catalogo.md) — El adulto crea pictos con imagen (galería, cámara o URL) que pertenecen al chico activo y funcionan sin conexión; la imagen se comprime al entrar (máx. 1024px).
- [**Categorías personalizadas**](./aprobadas/catalogo.md) — Categorías creadas por el adulto, con nombre, color de una paleta fija y borrado con doble confirmación (cascada selectiva de pictos).
- [**Borrado con doble confirmación**](./aprobadas/catalogo.md) — Pictos y categorías custom se borran con dos diálogos; el catálogo incluido no se puede borrar.
- [**Pictos multicategoría y edición**](./aprobadas/catalogo-multicategoria.md) — Un picto vive en 1 o más catálogos (elegidos en el formulario, con preselección al crear desde una categoría); pictos y categorías custom se editan (nombre, imagen, color); la cascada de borrado quita membresías en vez de dejar huérfanos.

## Comunicación

- [**Comunicar (tira de frase + Play)**](./aprobadas/comunicar.md) — El niño arma la frase tocando pictos (feedback solo visual, sin sonido) y la reproduce palabra por palabra con Play, en el orden de selección; la voz sigue el idioma de la interfaz (TTS del sistema, offline).
- [**Corrección de la frase**](./aprobadas/comunicar.md) — Mini-basura por picto, backspace del último y basura global para limpiar la barra completa.

## Idioma

- [**Idioma de la interfaz (i18n)**](./aprobadas/idioma.md) — La app se ofrece en español (default), inglés y portugués; el adulto elige en la pantalla Perfil y el cambio aplica al instante, sin reiniciar.

## Backend y sync

- [**Backend y sync del catálogo (descarga)**](./aprobadas/backend-sync.md) — Backend Dart (shelf) en `src/backend/` que sirve un catálogo ampliado desde un seed JSON; la app lo sincroniza al arrancar (incremental por `updatedAt`), lo cachea local y lo mergea con lo suyo.
- [**Backend bidireccional (subida del catálogo custom)**](./aprobadas/backend-bidireccional.md) — Lo creado en la app sube al backend (alta, edición y borrado lógico de pictos y categorías custom, con conflictos last-write-wins); outbox con reintentos y estado de sync visible en modo adulto.
