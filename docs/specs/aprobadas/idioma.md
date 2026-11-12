# Idioma de la interfaz (i18n)

Funcionalidad que **permite usar la app en español, inglés o portugués: la interfaz completa se presenta en el idioma elegido por el adulto, y el cambio aplica al instante sin reiniciar** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- La app soporta **tres idiomas**: **español** (default), **inglés** y **portugués**, con un solo idioma activo por vez.
- El **selector de idioma** vive en la pantalla **Perfil** (espacio del adulto): una lista corta con los tres idiomas, cada uno mostrado en su idioma nativo (Español / English / Português), con el activo destacado por radio.
- El cambio aplica **inmediatamente** en todas las pantallas visibles, sin reiniciar la app.
- Local-first: el idioma se guarda en el dispositivo (SharedPreferences) y la app **siempre arranca en el idioma almacenado**; el primer arranque usa el idioma del sistema si está soportado y si no cae al español.
- El **100% de los textos de interfaz** sale de las tablas de traducción: no hay texto hardcodeado en widgets.
- **Fuera de alcance**: la voz del pictograma (TTS) no es parte de este requerimiento (su idioma se resuelve en [comunicar.md](./comunicar.md)), y los nombres de pictos, categorías y perfiles son **contenido**: no se traducen.

## Experiencia de usuario

1. El adulto abre la pestaña **Perfil**: arriba de todo ve la sección de idioma con las tres opciones (nombres siempre en idioma nativo, independiente del idioma activo).
2. El idioma activo muestra el radio marcado (`radio_button_checked`); los demás, vacío.
3. Toca otro idioma: **todas las pantallas** (labels de la barra inferior, saludos, botones, diálogos de borrado, mensajes de error, estados vacíos) cambian al instante, sin reiniciar ni recargar.
4. Cierra y reabre la app: arranca en el idioma que quedó guardado.

## Cómo lo hace (implementación)

### Frontend (Flutter)

| Parte | Archivo | Rol |
|---|---|---|
| Controller | `lib/core/i18n/locale_controller.dart` | `LocaleController extends ChangeNotifier`: `locale`, `setLanguage(code)`, `supportedLanguageCodes = {es, en, pt}`. Persiste en SharedPreferences clave `pictocomm.ui_locale` |
| Resolución de arranque | `locale_controller.dart` (constructor) | Valor guardado → si no hay (o no es soportado) → idioma del sistema si está soportado → **español** |
| Selector | `lib/features/profiles/presentation/screens/profile_screen.dart` (`_LanguageSection`) | `ListTile` denso por idioma con radio propio (no `RadioListTile`); nombres fijos `{'es': 'Español', 'en': 'English', 'pt': 'Português'}` |
| Reconstrucción global | `lib/app.dart` (`PictoCommApp`) | El `LocaleController` vive **por encima del `MaterialApp`**: un `Builder` hace `context.watch<LocaleController>().locale`, así el cambio de idioma reconstruye el `MaterialApp` completo con el locale nuevo |
| Tablas de traducción | `lib/l10n/app_es.arb`, `app_en.arb`, `app_pt.arb` | Mecanismo estándar de Flutter (`flutter_localizations` + código generado `AppLocalizations`); agregar un idioma nuevo = agregar una tabla, sin tocar pantallas ni providers |
| Arranque anticipado | `lib/main.dart` | `await SharedPreferences.getInstance()` **antes del primer frame**: el idioma se resuelve antes de que exista UI |
| Config | `src/frontend/l10n.yaml` + `pubspec.yaml` | `generate: true`, `supportedLocales` y delegates en `app.dart` |

### Flujo paso a paso

1. `main` resuelve SharedPreferences antes del primer frame y crea `PictoCommApp` con el `LocaleController` persistente (en tests se inyecta `LocaleController.ephemeral()`: español fijo, sin tocar storage, para determinismo).
2. El controller resuelve el locale inicial en su constructor (guardado → sistema → español) y queda expuesto como `ChangeNotifierProvider` sobre el `SessionProvider`.
3. Al cambiar el idioma en Perfil: `setLanguage(code)` ignora códigos no soportados o el valor repetido; sino setea `Locale(code)`, persiste el string y `notifyListeners()`.
4. El `Builder` que hace watch reconstruye el `MaterialApp` con el locale nuevo → todas las rutas re-renderizan con las tablas del idioma elegido (RF4.3 sin reiniciar).
5. El locale **no** depende de la sesión de chico activo: cambiar de niño no cambia el idioma y borrar un perfil no lo toca.

## Validaciones y casos límite

| Situación | Comportamiento |
|---|---|
| Idioma no soportado | `setLanguage` lo ignora |
| Idioma repetido (ya activo) | No-op (sin notify innecesario) |
| Primer arranque, sistema en es/en/pt | Arranca en el idioma del sistema |
| Primer arranque, sistema en otro idioma | Cae al **español** |
| Valor guardado corrupto o no soportado | Se ignora y se cae al sistema/español |
| Cambio de chico o borrado de perfil | El idioma no cambia |
| Tests | `LocaleController.ephemeral()`: sin persistencia, español fijo |

## Limitaciones conocidas

- Los nombres del catálogo incluido **no se traducen** (son contenido): siguen en español aunque la UI esté en otro idioma (pregunta abierta #1: etiquetas bilingües, v2).
- No hay localización de formatos de fecha/número (hoy no hay fechas visibles en la UI; pendiente si aparecen pantallas nuevas).
- El idioma del **TTS** está fijado por código en `TtsVoiceProvider` y no sigue el idioma de la interfaz (resuelto en el spec de comunicar).

---

Volver a [`0000-index.md`](../0000-index.md).
