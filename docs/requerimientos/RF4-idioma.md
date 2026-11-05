# RF4 — Idioma de la app (i18n)

| Campo | Valor |
|---|---|
| Estado | Aprobado |
| Versión | 1.0 |
| Fecha | 2026-11-05 |

## Descripción

La app se ofrece en varios idiomas: su interfaz (textos de pantallas, botones,
diálogos, mensajes y errores visibles) se presenta en el idioma elegido por el
adulto responsable. Es una decisión **global del dispositivo**: el adulto arma
la sesión y define el idioma; los chicos de esa casa comparten ese idioma de
interfaz.

**Fuera de alcance (frontera con los otros RF):**

- La **voz** del pictograma (TTS) no es parte de este requerimiento: su idioma
  quedó como pregunta abierta de RF1 y se resuelve allí. Que la UI esté en un
  idioma no condiciona el idioma de la voz.
- Los **nombres de pictos, categorías y perfiles** son contenido (del catálogo
  incluido o ingresado por el adulto), no interfaz: no se traducen.

## Requisitos

### Idiomas soportados

- **RF4.1** — La app soporta tres idiomas: **español** (default), **inglés** y
  **portugués**. La app funciona con un solo idioma activo por vez (no es
  contenido bilingüe simultáneo).

### Selector

- **RF4.2** — El selector de idioma vive en la **pantalla Perfil** (espacio del
  adulto): una lista corta con los tres idiomas; el activo queda destacado.
- **RF4.3** — El cambio de idioma aplica **inmediatamente** en todas las
  pantallas visibles, **sin reiniciar la app**.

### Persistencia y arranque

- **RF4.4** — Local-first: el idioma se guarda en el dispositivo
  (SharedPreferences) y la app **siempre arranca en el idioma almacenado**,
  sin conexión ni cuenta.
- **RF4.5** — Primer arranque (nunca configurado): la app usa el **idioma del
  sistema** si está soportado (es/en/pt); si no, cae al **español**.

### Cobertura y centralización

- **RF4.6** — El **100% de los textos de interfaz** sale de la centralización
  de strings: pantallas, botones, diálogos, tooltips, SnackBar y mensajes de
  error visibles. Queda prohibido el texto hardcodeado en widgets.
- **RF4.7** — Agregar un idioma nuevo **no obliga a tocar pantallas ni
  providers**: se agrega la tabla de traducciones correspondiente y nada más.
- **RF4.8** — Los tres idiomas tienen **cobertura completa**: ninguna pantalla
  casa cabezas (texto mezclado) en ningún idioma soportado.

## Preguntas abiertas

| # | Pregunta | Estado |
|---|---|---|
| 1 | ¿Los nombres del catálogo incluido se traducen alguna vez (etiquetas bilingües de pictos)? | Pendiente — v2 |
| 2 | ¿Localizar además formatos de fecha/número si aparecen en pantallas nuevas? | Pendiente — hoy no hay fechas visibles en UI |

## Notas de implementación (no normativas)

- Mecanismo estándar de Flutter: `flutter_localizations` + código generado
  (tablas ARB: `app_es.arb`, `app_en.arb`, `app_pt.arb`). Cumple RF4.6/4.7 por
  diseño: el texto vive en las tablas, no en los widgets.
- El idioma configurado es un aspecto **transversal** (no es catálogo ni
  perfiles): pertenece a `core/`, junto al theme. Un `LocaleController` a nivel
  `MaterialApp` con la misma persistencia que ya usa RF2 (SharedPreferences,
  JSON) es suficiente; sin entidad de dominio nueva.
- El locale del `MaterialApp` no depende de la sesión de chico activo (RF2.2):
  cambiar de niño **no** cambia el idioma, y borrar un perfil **no** toca el
  idioma almacenado.
- Los tests de cobertura (RF4.8) van a ser la primera línea que rompe cuando
  alguien agregue texto suelto en un widget: barato de escribir, útil para sí.
