# Comunicar

Funcionalidad que **permite al niño construir una frase tocando pictos y reproducirla en voz alta, palabra por palabra, cuando está listo** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- Es la pestaña **Comunicar** de la barra inferior: vive en la ruta `/comunicar` y es la pantalla central de la app.
- Muestra el header **Comunicar**, la **tira de frase** arriba, chips de categoría para filtrar la grilla y la grilla de pictos visibles para el chico de la sesión activa.
- **Tocar un picto no produce sonido**: el toque agrega el picto al final de la tira de frase y produce un feedback **visual** inequívoco (flash de la card). El único canal que confirma que el toque entró es el visual.
- El botón **Play** (siempre visible) reproduce la palabra de cada picto seleccionado, **en el orden de selección**, con un diálogo de reproducción tipo karaoke. La voz es TTS del sistema (offline).
- La corrección es por niveles: **mini-basura** bajo cada picto de la tira (quita solo ese), **backspace** (quita el último) y **basura global** (limpia toda la frase).

## Experiencia de usuario

1. El usuario entra a la pestaña **Comunicar** desde la barra inferior. La tira de frase arranca vacía con el texto *"tocá pictos para armar la frase"* (`sentenceStripEmpty`).
2. Toca un picto de la grilla (opcionalmente filtrando antes por un chip de categoría): la card flashea ~450 ms (borde acento, escala 1.08) y el picto aparece al final de la tira, separado del siguiente por un chevron.
3. Puede seguir tocando pictos: no hay límite de cantidad y los repetidos se permiten (cada toque agrega una copia). La tira scrollea horizontalmente cuando desborda.
4. Pulsa **Play**: se abre un diálogo a pantalla oscura que agranda cada picto de la frase (340px, fondo negro, label grande) y pronuncia su palabra con la voz; la tira inferior del diálogo hace **karaoke** (el picto activo se agranda 1.12x con borde acento y la tira auto-scrollea hasta él).
5. Cada palabra suena **una tras otra**: el diálogo avanza al siguiente picto recién cuando el TTS terminó de pronunciar el actual.
6. Al cerrar el diálogo (X, tap afuera o botón back), la voz se corta de inmediato y la frase **se mantiene** en la barra (puede reproducir de nuevo).
7. Para corregir: usa la mini-basura bajo un picto (lo quita solo a él), el backspace (quita el último) o la basura global (borra todo).

## Cómo lo hace (implementación)

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Pantalla | `lib/features/catalog/presentation/screens/comunicar_screen.dart` | Estado local `_sentence` (lista de `Picto`) + `_categoryId` (filtro); compone tira, chips, grilla y diálogo |
| Tira de frase | `comunicar_screen.dart` (`_SentenceStrip`, `_SentenceChip`, `_StripAction`) | Chips de 76px con mini-basura individual (`Icons.delete_outline` 18px rojo), backspace (`removeLastTooltip`) y basura global (`clearSentenceTooltip`) |
| Feedback del toque | `lib/features/catalog/presentation/widgets/picto_card.dart` | Flash autónomo: borde `accent` 2.5px, `AnimatedScale` 1.08, sombra y texto en accent, 450 ms. Key de test `picto_highlighted` (visible solo durante el flash) |
| Grilla y filtro | `comunicar_screen.dart` (`_CategoryChips`, `EmptyCategoryHint`) | `ChoiceChip` "Todas" + un chip por categoría; categoría sin pictos muestra el hint vacío |
| Diálogo de reproducción | `comunicar_screen.dart` (`_PlaySequenceDialog`) | Loop palabra por palabra: `setState(_index = i)` + `_scrollTo(i)` (auto-scroll, chip 92px, animación 200 ms easeOut) + `await voiceProvider.speak(label)` |
| Abstracción de voz | `lib/features/voice/domain/voice_provider.dart` | `VoiceProvider { speak(word) → Future que completa al terminar; stop(); dispose(); }`. Ninguna parte de la UI conoce el mecanismo concreto |
| Implementación TTS | `lib/features/voice/data/tts_voice_provider.dart` | `TtsVoiceProvider` con `flutter_tts`: idioma preferido de `['es-AR','es-MX','es-ES']`, `speechRate 0.5` (ritmo pausado), `awaitSpeakCompletion(true)` (es lo que permite encadenar). `speak('')` lanza `VoiceException` |
| Inyección de voz | `lib/app.dart` (ruta `/comunicar`) + `lib/core/di/injector.dart` | El `VoiceProvider` se expone como `Provider` **solo en esta ruta**; el composition root decide la implementación (v1: TTS del sistema) |
| Pictos visibles | `lib/features/catalog/presentation/providers/pictos_provider.dart` | La grilla pinta lo que ve el chico activo (ver [catalogo.md](./catalogo.md)) |

### Flujo paso a paso

1. La ruta `/comunicar` envuelve la pantalla con `PictosProvider` (compartido, recargado en microtask) y `Provider<VoiceProvider>.value`.
2. Cada toque de picto pasa por `PictoCard._handleTap`: dispara el flash (450 ms) y llama al callback de la pantalla, que hace `_sentence.add(picto)` y `setState`.
3. **Play** con frase vacía está deshabilitado (`onPressed: null`, fondo gris translúcido); con frase abre `_PlaySequenceDialog`.
4. `initState` del diálogo lanza `_play()`: por cada picto, marca el índice activo, auto-scrollea la tira del diálogo y `await`speak con **timeout de 6 s** por palabra.
5. Si el TTS lanza `VoiceException` o expira el timeout, el diálogo muestra el aviso `voiceUnavailable` y **la frase sigue avanzando** (no se traba).
6. `dispose` del diálogo hace `unawaited(voiceProvider.stop())` y `_cancelled = true`: cerrar el diálogo corta la voz de inmediato.
7. La mini-basura llama `onRemoveAt(index)`; el backspace y la basura global son no-ops seguros con frase vacía.

### Nota sobre la voz

- La voz **nunca es automática**: el modelo es el de la tira de frase de PECS (**construir primero, "hablar" bajo demanda**). Si la UI sonara al tocar o al construir, los tests de RF1.2 rompen — la voz se verifica en tests con un `FakeVoiceProvider` que registra los `speak`.
- El TTS corre en el dispositivo (offline, sin costo en runtime). Cambiar a un modo híbrido futuro (audios pre-generados con IA para el catálogo incluido + TTS para pictos custom) solo requiere otra implementación de `VoiceProvider` en el composition root: pantallas y providers no se tocan.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Toque de picto | Sin sonido; flash visual de 450 ms + aparición del chip en la tira |
| Frase vacía | Play deshabilitado; backspace y basura global son no-ops seguros |
| Cantidad de pictos | Sin límite; la tira scrollea horizontal; repetidos permitidos |
| Orden | El de selección (posición de agregado); sin reordenamiento manual |
| Reproducir de nuevo | La tira se mantiene tras el Play; se puede repetir |
| TTS falla o tarda > 6 s | Aviso `voiceUnavailable` en el diálogo; la secuencia sigue avanzando |
| Cerrar el diálogo | `stop()` inmediato: la voz se corta aunque esté a mitad de palabra |
| Categoría sin pictos | Hint `emptyCategoryHint` en la grilla |

## Limitaciones conocidas

- El "karaoke" (picto activo agrandado + auto-scroll durante el Play) existe de facto en `_PlaySequenceDialog` pero sigue pendiente de decisión normativa (pregunta abierta #1 de REQ-COM-01).
- El idioma del TTS está fijado por código (`es-AR` → `es-MX` → `es-ES`, primero disponible; si ninguno, la voz del sistema): no sigue el idioma de la interfaz ni tiene configuración por perfil (pregunta abierta #2 de REQ-COM-01).
- No hay reordenamiento de la frase ni edición de un picto ya agregado (solo quitar).
- Con la tira scrolleando, los targets de la mini-basura son pequeños: no se ha resuelto el riesgo de toques accidentales anotado en las notas de implementación.

---

Volver a [`0000-index.md`](../0000-index.md).
