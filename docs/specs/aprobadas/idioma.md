# Idioma de la interfaz (i18n)

Funcionalidad que **permite usar la app en español, inglés o portugués: la interfaz completa se presenta en el idioma elegido por el adulto, y el cambio aplica al instante sin reiniciar** en **PictoComm**. Es una de las funcionalidades listadas en [`0000-index.md`](../0000-index.md).

---

## Qué hace

- La app soporta **tres idiomas**: **español** (default), **inglés** y **portugués**, con un solo idioma activo por vez.
- El **selector de idioma** vive en la pantalla **Perfil** (espacio del adulto): una lista corta con los tres idiomas, cada uno mostrado en su idioma nativo (Español / English / Português), con el activo destacado por radio.
- El cambio aplica **inmediatamente** en todas las pantallas visibles, sin reiniciar la app.
- Local-first: el idioma se guarda en el dispositivo (SharedPreferences) y la app **siempre arranca en el idioma almacenado**; el primer arranque usa el idioma del sistema si está soportado y si no cae al español.
- El **100% de los textos de interfaz** sale de las tablas de traducción: no hay texto hardcodeado en widgets.
- **Etiquetas del catálogo incluido traducidas (v3, REQ-IDI-01 RF-4.9/4.10)**: pictos y categorías del catálogo incluido (bundled + seed del backend) muestran y **se hablan** en el idioma activo. Los pictos/categorías **personalizados** y los **perfiles** son contenido del adulto: no se traducen (caen a su texto original).
- **Fuera de alcance**: la voz del pictograma (TTS) como requerimiento es parte de [comunicar.md](./comunicar.md) (allí se definió que la voz sigue el idioma de la UI, RF-1.11); los perfiles son contenido del adulto: no se traducen.

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

## Etiquetas multilingües del catálogo (v3)

Los pictos y categorías del catálogo incluido llevan **traducciones dentro de la entidad**, con la etiqueta base (español) como fallback:

| Parte | Archivo | Rol |
|---|---|---|
| Entidades | `Picto.labels` / `Category.names` | Mapa `idioma → texto` opcional (default vacío). Resolución pura en dominio: `labelFor(code)` / `nameFor(code)` devuelven la traducción o la base; `matchesQuery(query)` busca en la base **y todas** las traducciones |
| Manifiesto bundled | `assets/catalog_labels.json` | Traducciones de los 31 pictos y 4 categorías incluidos, indexadas por slug. `LocalCatalogDataSource.bundledLabels()` lo carga (si falta o está roto: mapas vacíos, sin crash) y `LocalPictoRepository` lo mergea al construir los bundled |
| Modelos JSON | `PictoModel.labels` / `CategoryModel.names` | Opcionales y tolerantes (cache/outbox viejos sin el campo no rompen); `toJson` omite la clave si está vacía, así el JSON de un item sin traducir queda igual al de siempre |
| Seed del backend | `src/backend/data/seed.json` | `labels` en los 13 pictos y `names` en las 2 categorías, con `updatedAt` bump-eado (2026-11-15) para que el sync incremental los re-descargue |
| API del backend | `api_handler.dart` + `catalog_store.dart` | Parseo/validación tolerante de `labels`/`names` (mal formado se ignora); POST/PUT los aceptan, PUT sin la clave conserva las existentes; se re-emiten en formato frontend y se persisten en `uploads.json` |
| UI | grillas, tira de frase, chips, detalle, diálogos | Resuelven con `labelFor`/`nameFor` según el locale activo; los íconos de categoría mapean por el **nombre base** español (no cambian con el idioma) |
| TTS | `comunicar_screen.dart` (`_play`) | El karaoke dice `picto.labelFor(widget.languageCode)`: la palabra hablada es la del idioma activo (coherente con RF-1.11) |

Fallback (RF-4.10): picto/categoría custom, contenido sin entrada para el idioma activo o idioma no soportado → etiqueta base en español, nunca texto vacío ni crash.

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

- Los pictos/categorías **personalizados** no se traducen: el adulto los crea en un solo idioma y se muestran tal cual (contenido del adulto, decisión #7 del REQ).
- No hay localización de formatos de fecha/número (hoy no hay fechas visibles en la UI; pendiente si aparecen pantallas nuevas).
- El idioma del **TTS** sigue el idioma de la interfaz (RF-1.11, resuelto en [comunicar.md](./comunicar.md)).

---

Volver a [`0000-index.md`](../0000-index.md).
