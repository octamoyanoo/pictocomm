# RF1 — Comunicación

| Campo | Valor |
|---|---|
| Estado | Aprobado |
| Versión | 1.0 |
| Fecha | 2026-11-05 |

## Descripción

El niño se comunica seleccionando pictos y presionando Play cuando está listo.
El modelo es el de la tira de frase de PECS: **construir primero, "hablar" bajo demanda**.
El sonido nunca es automático: el niño controla cuándo se emite la palabra.

## Requisitos

### Navegación y selección

- **RF1.1** — El niño navega por categorías y visualiza los pictos de cada una.
- **RF1.2** — Tocar un picto **no produce sonido**. El toque agrega el picto a la barra de selección y debe producir un feedback **visual** inequívoco (picto destacado + aparición en la barra). El único canal que confirma que el toque "entró" es el visual.
- **RF1.3** — El orden de los pictos en la barra es el **orden en que fueron seleccionados**. Sin reordenamiento manual (v1).
- **RF1.4** — Cantidad de pictos seleccionables: **sin límite**. La barra soporta scroll horizontal cuando desborda.

### Barra de frase

- **RF1.5** — Botón **Play**, siempre visible, reproduce la palabra de cada picto seleccionado: funciona con 1 picto o con varios.
- **RF1.6** — La reproducción se hace en el orden de selección (RF1.3).
- **RF1.7** — Tras reproducir, la barra **se mantiene** (el niño puede reproducir de nuevo).
- **RF1.8** — Botón **Basura** (global) limpia toda la barra de una vez.
- **RF1.9** — Cada picto de la barra tiene su propia **mini-basura** para quitarse individualmente.

### Voz

- **RF1.10** — La voz en v1 es **TTS del sistema**, ejecutado en el dispositivo (offline, sin costo en runtime).
- **RF1.11** — La generación de voz debe estar detrás de una **abstracción** que permita, en un futuro, operating un modo híbrido: audios pre-generados con IA empaquetados como assets para el catálogo incluido, y TTS del sistema para pictos personalizados. Ninguna parte de la UI debe conocer el mecanismo de voz concreto.

## Preguntas abiertas

| # | Pregunta | Estado |
|---|---|---|
| 1 | ¿Cada picto se ilumina mientras suena su palabra ("efecto karaoke") durante el Play? | Pendiente |
| 2 | Idioma del TTS: español (¿variante regional?) — configuración global o por perfil. | Pendiente |

## Notas de implementación (no normativas)

- RF1.11 sugiere un `VoiceProvider` en `domain/` con una implementación sobre `flutter_tts` (u equivalente nativo). Cambiar de proveedor no debe tocar pantallas ni providers de presentación.
- Con selects ilimitados + scroll en la barra, considerar qué pasa con usability de la mini-basura cuando la barra scrollea (targets pequeños en movimiento =ASSWORD riesgo de toques accidentales).
