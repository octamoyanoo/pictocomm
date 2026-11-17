# REQ-COM-01 — Comunicación: tira de frase y Play

**Mockup:** `docs/prototipos/wireframes.pen` → frame **`Comunicar`**
**Specs vigentes:** [`comunicar.md`](../../specs/aprobadas/comunicar.md), [`catalogo.md`](../../specs/aprobadas/catalogo.md) (pictos visibles)
**Archivos implicados:** `lib/features/catalog/presentation/screens/comunicar_screen.dart`, `lib/features/catalog/presentation/widgets/picto_card.dart`, `lib/features/catalog/presentation/providers/pictos_provider.dart`, `lib/features/voice/domain/voice_provider.dart`, `lib/features/voice/data/tts_voice_provider.dart`, `lib/core/di/injector.dart`, `lib/app.dart`

---

## 1. Objetivo

Que el niño se comunique seleccionando pictos y presionando Play cuando está listo, siguiendo el modelo de la tira de frase de PECS: **construir primero, "hablar" bajo demanda**. El sonido nunca es automático: el niño controla cuándo se emite la palabra.

## 2. Estado actual

Implementado y verificado por tests (estado al 2026-11-12):

- La pestaña Comunicar (`/comunicar`) arma la frase tocando pictos, con feedback solo visual.
- Play reproduce palabra por palabra con TTS del sistema, en el orden de selección, con diálogo tipo karaoke.
- Corrección por niveles: mini-basura individual, backspace y basura global.
- La voz está detrás de la abstracción `VoiceProvider` (`domain/`), inyectada por el composition root; la UI no conoce el mecanismo concreto.

## 3. Estado objetivo (elementos definidos)

| Elemento | Contenido | Estado |
|---|---|---|
| Tira de frase | Chips de pictos en orden de selección, con scroll horizontal y **reordenamiento por arrastre** | **Implementado** |
| Toque de picto | Sin sonido; flash visual ~450 ms + aparición en la barra | **Implementado** |
| Play | Reproduce cada picto en orden; funciona con 1 o varios | **Implementado** |
| Diálogo de reproducción | Picto activo agrandado + auto-scroll (karaoke de facto) | **Implementado** |
| Mini-basura / backspace / basura global | Corrección individual, del último y total | **Implementado** |
| Voz | TTS del sistema (offline) detrás de `VoiceProvider` | **Implementado** |

## 4. Requerimientos funcionales

| ID | Requerimiento |
|---|---|
| RF-1.1 | El niño navega por categorías y visualiza los pictos de cada una. |
| RF-1.2 | Tocar un picto **no produce sonido**. El toque agrega el picto a la barra de selección y debe producir un feedback **visual** inequívoco (picto destacado + aparición en la barra). El único canal que confirma que el toque "entró" es el visual. |
| RF-1.3 | El orden de los pictos en la barra es, por defecto, el **orden en que fueron seleccionados**, y puede **reordenarse**: mantener presionado un chip y arrastrarlo a su nueva posición (drag & drop horizontal). |
| RF-1.4 | Cantidad de pictos seleccionables: **sin límite**. La barra soporta scroll horizontal cuando desborda. |
| RF-1.5 | Botón **Play**, siempre visible, reproduce la palabra de cada picto seleccionado: funciona con 1 picto o con varios. |
| RF-1.6 | La reproducción se hace en el **orden de la barra** (selección o reordenamiento, RF-1.3). |
| RF-1.7 | Tras reproducir, la barra **se mantiene** (el niño puede reproducir de nuevo). |
| RF-1.8 | Botón **Basura** (global) limpia toda la barra de una vez. |
| RF-1.9 | Cada picto de la barra tiene su propia **mini-basura** para quitarse individualmente. |
| RF-1.10 | La voz en v1 es **TTS del sistema**, ejecutado en el dispositivo (offline, sin costo en runtime). |
| RF-1.11 | La generación de voz debe estar detrás de una **abstracción** que permita, en un futuro, operar un modo híbrido: audios pre-generados con IA empaquetados como assets para el catálogo incluido, y TTS del sistema para pictos personalizados. Ninguna parte de la UI debe conocer el mecanismo de voz concreto. |

## 5. Requerimientos visuales / no funcionales

| ID | Requerimiento |
|---|---|
| RNF-1.1 | El destaque visual del toque vive en `PictoCard` y es autónomo: la card flashea (borde/scale transitorio de ~450 ms, key de test `picto_highlighted`) sin acoplar la barra al estado de la grilla. |
| RNF-1.2 | El diálogo de reproducción avanza al siguiente picto recién cuando el TTS terminó la palabra actual (`awaitSpeakCompletion`); timeout de 6 s por palabra como red de seguridad. |
| RNF-1.3 | Cerrar el diálogo de reproducción corta la voz de inmediato (`stop()` en dispose). |
| RNF-1.4 | Si el TTS falla o expira, el diálogo muestra el aviso `voiceUnavailable` y la secuencia sigue avanzando: el niño nunca queda trancado. |
| RNF-1.5 | Play con frase vacía está deshabilitado (no es un error). |
| RNF-1.6 | El ritmo del TTS es pausado (`speechRate 0.5`), adecuado para niños de 2-5 años. |

## 6. Casos de uso

### UC-01.1 — Armar una frase y reproducirla

| | |
|---|---|
| **Actor** | Niño con sesión de chico activa |
| **Objetivo** | Expresar una necesidad con la frase de pictos |
| **Precondiciones** | Pantalla Comunicar visible con pictos del chico activo |
| **Disparador** | El niño toca pictos y luego Play |

**Flujo principal:**
1. El niño toca pictos (opcionalmente filtrando por categoría): cada toque flashea la card y agrega el picto al final de la barra.
2. Pulsa Play: se abre el diálogo de reproducción.
3. El diálogo pronuncia cada palabra en orden, con el picto activo agrandado y la tira auto-scrolleando.
4. Al terminar, cierra el diálogo; la frase queda en la barra.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Frase vacía | Play está deshabilitado |
| 2 | TTS falla o tarda > 6 s | Aviso `voiceUnavailable`; la secuencia sigue avanzando |
| 3 | Cierra el diálogo a mitad de palabra | La voz se corta de inmediato |

**Postcondiciones:** El niño comunicó su frase; la barra se mantiene para reproducir de nuevo o corregir.

### UC-01.2 — Corregir la frase

| | |
|---|---|
| **Actor** | Niño (o adulto acompañando) |
| **Objetivo** | Quitar pictos de la barra |
| **Precondiciones** | Hay al menos un picto en la barra |
| **Disparador** | Mini-basura, backspace o basura global |

**Flujo principal:**
1. Mini-basura bajo un picto: lo quita solo a él, manteniendo el orden del resto.
2. Backspace: quita el último agregado.
3. Basura global: limpia toda la barra de una vez.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Barra vacía | Las acciones son no-ops seguros |

**Postcondiciones:** La barra refleja la corrección; el orden de los restantes se preserva.

### UC-01.3 — Reordenar la frase

| | |
|---|---|
| **Actor** | Niño (o adulto acompañando) |
| **Objetivo** | Cambiar el orden de los pictos antes de hablar (estructura de la frase) |
| **Precondiciones** | Hay al menos dos pictos en la barra |
| **Disparador** | Mantener presionado un chip y arrastrarlo |

**Flujo principal:**
1. Mantener presionado un chip de la barra lo levanta en modo arrastre.
2. Arrastrar horizontalmente mueve el chip sobre sus vecinos (feedback de posición).
3. Soltar asienta el chip en la nueva posición; el resto se corre para mantener la secuencia sin huecos.

**Flujos alternativos y excepciones:**

| # | Caso | Resultado |
|---|---|---|
| 1 | Toque corto (sin mantener) | Nada: el toque simple no reordena ni dispara drag |
| 2 | Soltar fuera de la barra o en el mismo lugar | El chip vuelve a su posición (no-op) |
| 3 | Un solo picto en la barra | No hay nada que reordenar (el drag es no-op) |

**Postcondiciones:** La barra refleja el orden nuevo; Play reproduce en ese orden (RF-1.6).

## 7. Criterios de aceptación



| ID | Criterio (Given / When / Then) |
|---|---|
| CA-1.1 | **Given** la pantalla Comunicar, **when** se toca un picto, **then** no hay sonido y aparece el chip en la barra con flash (key `picto_highlighted` durante ~450 ms). |
| CA-1.2 | **Given** varios toques, **when** se observa la barra, **then** el orden es el de selección y la cantidad no tiene límite. || CA-1.3 | **Given** una frase de uno o varios pictos, **when** se pulsa Play, **then** cada palabra suena en orden, una tras otra. |
| CA-1.4 | **Given** una frase reproducida, **when** se cierra el diálogo, **then** la barra se mantiene y se puede reproducir de nuevo. |
| CA-1.5 | **Given** la barra vacía, **when** se observa el Play, **then** está deshabilitado. |
| CA-1.6 | **Given** la mini-basura de un chip, **when** se toca, **then** solo ese picto se quita de la barra. |
| CA-1.7 | **Given** la basura global, **when** se toca, **then** la barra queda vacía. |
| CA-1.8 | **Given** cualquier pantalla de la app, **when** se construye la UI, **then** nunca se llama `speak` salvo por el Play (la voz se verifica con un fake que registra los `speak`; si la UI sonara al tocar, los tests de RF-1.2 rompen). |
| CA-1.9 | **Given** una frase con 2+ pictos, **when** se mantiene presionado un chip y se lo arrastra a otra posición, **then** la barra refleja el orden nuevo sin huecos ni duplicados. |
| CA-1.10 | **Given** una frase reordenada, **when** se pulsa Play, **then** las palabras suenan en el orden nuevo de la barra. |
| CA-1.11 | **Given** un toque simple sobre un chip, **when** se suelta sin mantener presionado, **then** no hay reordenamiento (el drag exige long-press). |

Cobertura de tests: `test/comunicar_flow_test.dart` (RF-1.2 a RF-1.9, Play deshabilitado con frase vacía y reordenamiento RF-1.3).

## 8. Fuera de alcance

- Sonido automático al tocar o al construir la frase.
- Editar la palabra de un picto ya agregado.
- Modo híbrido de voz con audios pre-generados (RF-1.11 deja la abstracción lista, no la implementación).
- Configuración del TTS por perfil o desde UI.

## 9. Decisiones

| # | Punto | Decisión |
|---|---|---|
| 1 | Modelo de comunicación | Confirmado (usuario): tira de frase de PECS, construir primero y "hablar" bajo demanda. |
| 2 | Canal de confirmación del toque | Confirmado (usuario): solo visual; el audio es exclusivo del Play. |
| 3 | Karaoke durante el Play | Confirmado (usuario, cierre v2): el karaoke (picto activo agrandado + auto-scroll) es **normativo**: es parte del flujo del Play descrito en [comunicar.md](../../specs/aprobadas/comunicar.md). Pregunta abierta #1 cerrada. |
| 4 | Idioma del TTS | Confirmado (usuario, cierre v2): la voz **sigue el idioma de la interfaz** (`es`/`en`/`pt`) con fallback silencioso a la voz del sistema si el idioma no está instalado. Se implementó con `setLanguage()` en la interfaz `VoiceProvider` (RF-1.11); la pantalla Comunicar le pasa el `languageCode` del `LocaleController` antes del primer `speak`. Pregunta abierta #2 cerrada. |
| 5 | Abstracción de voz | Decisión (mi llamada): `VoiceProvider` en `domain/`, inyección en `core/di` (`TtsVoiceProvider` en v1); cambiar de proveedor no toca pantallas ni providers. |
| 6 | Corte de voz | Decisión (mi llamada): cerrar el diálogo corta la voz de inmediato (garantía del modelo PECS). |
| 7 | Reordenamiento (v3) | Decisión (mi llamada): **drag & drop horizontal con long-press** (`ReorderableListView`): el toque simple nunca reordena (un niño de 2-5 toca constantemente; el arrastre accidental es el riesgo), y el orden de la barra es el orden de habla. Sin modos ni botones extra: el arrastre vive sobre los chips que ya existen. |
