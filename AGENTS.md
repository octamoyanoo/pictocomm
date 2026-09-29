# AGENTS.md

## Project Status

App Flutter (local-first) para comunicación por imágenes en niños autistas no verbales de 2-5 años.

Frontend definido y verificado. **El backend todavía NO existe**: `src/backend/` está vacío a propósito.

## Objetivo del Proyecto

Ver [overview.md](overview.md) para detalles del propósito y alcance del proyecto.

## Ubicación del código

- **frontend (app Flutter)**: `src/frontend/`
- **backend**: `src/backend/` — se implementa cuando el usuario lo pida. El frontend ya está preparado para recibirlo (ver "Backend-ready").

## Arquitectura: Clean Architecture ligera por features

Clean Architecture *por feature*, no por capa global. Cada feature es vertical y autonomous; agregar una feature nueva no obliga a tocar las existentes.

```
lib/
├── main.dart                  # Bootstrap: bindings + orientación portrait
├── app.dart                   # PictoCommApp (recibe AppDependencies) + AppRouter
├── core/                      # Transversal, no pertenece a ninguna feature
│   ├── constants/app_routes.dart
│   ├── di/injector.dart       # AppDependencies: el composition root
│   ├── error/app_exception.dart
│   └── theme/app_theme.dart
└── features/
    ├── catalog/               # Categorías + pictos
    │   ├── domain/            # Entidades + interfaces de repositorio (puro)
    │   ├── data/              # models (JSON) + datasources + repos + mappers
    │   └── presentation/      # providers + screens + widgets
    └── profiles/              # Perfiles de niños (misma estructura)
```

### Reglas de dependencia (van en una sola dirección)

```
presentation  →  domain  ←  data
```

- `domain/` no importa nada de Flutter salvo `dart:ui` (`Color`). No sabe qué son assets, ni SharedPreferences, ni HTTP.
- `presentation/` depende de las **interfaces** de `domain/`, nunca de `data/`.
- `data/` implementa las interfaces de `domain/` y traduce excepciones.
- `core/` no importa features.

### Terminos de dominio

| Concepto | Clase | Nota |
|---|---|---|
| Imagen que toca el niño | `Picto` | Antes se llamaba `ImageItem`. **No usar `Symbol`**: colisiona con `dart:core.Symbol`. |
| De dónde sale la imagen | `PictoSource` | enum `bundled` / `custom` / `remote` |
| Grupo de pictos | `Category` | |
| Niño usuario | `ChildProfile` | Varios niños por dispositivo |

`PictoSource` existe para evitar el `if (isLocal) Image.file else Image.asset` disperso por los widgets: el `switch` queda en un solo lugar (`PictoCard`).

## Backend-ready (aún no implementado)

La app es **local-first**: lee SIEMPRE de local y funciona sin conexión.

- `RemoteCatalogDataSource` (`features/catalog/data/datasources/`) ya define el contrato del backend. Todos sus métodos lanzan `UnimplementedFeatureException` a propósito.
- `LocalPictoRepository` ya recibe el remote por constructor. Cuando exista el backend, se implementa el datasource y se agrega la lógica de sync **sin tocar pantallas ni providers**.
- Los modelos de `data/models/` ya tienen `fromJson`/`toJson`, listos para parsear respuestas HTTP.
- `test/helpers/fakes.dart` incluye `ExplodingRemoteDataSource`: falla ruidosamente si algún camino de lectura toca el remoto. Si un test lo dispara, hay un bug de local-first.
- `Picto` ya tiene `createdAt`/`updatedAt` para resolución de conflictos al sincronizar.

## Comandos

```bash
# desde src/frontend (SDK de Flutter en D:\flutter\bin)
flutter pub get        # instalar dependencias
flutter analyze        # lint (debe dar 0 issues)
flutter test           # tests
flutter run            # correr la app
```

## Gotchas

- El SDK de Flutter vive en `D:\flutter` (clonado de GitHub, rama stable) — `flutter` NO está en el PATH; usar `D:\flutter\bin\flutter.bat`.
- Git no está en el PATH por defecto; usar `& "C:\Program Files\Git\bin\git.exe"`.
- `Category` colisiona con la anotación `Category` de `flutter/foundation.dart` → importar con `hide Category`.
- `Symbol` colisiona con `dart:core.Symbol` → **usar `Picto`**.
- `Color.value` está deprecado → usar `toARGB32()`.
- `CupertinoPageTransitionsBuilder` no viene de `material.dart` → importarlo de `package:flutter/cupertino.dart`.
- `rootBundle` / `AssetManifest` vienen de `package:flutter/services.dart`, no de `material.dart`.
- Las carpetas `assets/images/*` están vacías; a medida que se agreguen imágenes reales se listan en `pubspec.yaml` bajo `flutter: assets:`. Con assets vacíos la home muestra el estado vacío, no un error.
- En tests, `expect(() => futureQueLanza, throwsA(...))` no funciona: usar `await expectLater(future, throwsA(...))`.
- `Set-Content` en PowerShell 5.1 no tiene `-NoNewline`; para reescribir archivos usar `[System.IO.File]::WriteAllText`.

## Testing

- `test/helpers/fakes.dart` centraliza los fakes. Todo pide interfaces, así que los widget tests inyectan `fakeDependencies()` y no tocan `AssetManifest`.
- Al agregar un método a una interfaz de `domain/`, actualizar los fakes: el compiler avisa, que es justamente el objetivo.
- Los fakes deben respetar el **mismo contrato** que la implementación real (mismas excepciones). Un fake más permisivo esconde bugs.
