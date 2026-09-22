# AGENTS.md

## Project Status

App Flutter (local-first) para comunicación por imágenes en niños autistas no verbales de 2-5 años.

## Objetivo del Proyecto

Ver [overview.md](overview.md) para detalles del propósito y alcance del proyecto.

## Ubicación del código

- **frontend (app Flutter)**: `src/frontend/`
- **backend**: `src/backend/` (sin contenido todavía, app es local-first)

## Arquitectura

Local-first con interfaz `StorageService` (services/) pensada para migrar a cloud después. State management con **Provider**. Todo en `lib/`:

- `models/` — `Category`, `ImageItem`
- `screens/` — `HomeScreen` (categorías), `CategoryScreen` (imágenes)
- `widgets/` — `CategoryCard`, `ImageCard`
- `providers/` — `AppProvider` (ChangeNotifier)
- `services/` — `StorageService` (abstract) / `LocalStorageService`
- `assets/images/{comida,lugares,emociones}/` — imágenes empaquetadas

## Comandos

```bash
# desde src/frontend (SDK de Flutter en D:\flutter\bin)
flutter pub get        # instalar dependencias
flutter analyze        # lint
flutter test           # tests
flutter run            # correr la app
```

## Gotchas

- El SDK de Flutter vive en `D:\flutter` (clonado de GitHub, rama stable) — `flutter` NO está en el PATH; usar `D:\flutter\bin\flutter.bat`.
- Git no está en el PATH por defecto; usar `& "C:\Program Files\Git\bin\git.exe"`.
- `Category` colisiona con la anotación `Category` de `flutter/foundation.dart` → importar con `hide Category`.
- Las carpetas `assets/images/*` están vacías; a medida que se agreguen imágenes reales se listan en `pubspec.yaml` bajo `flutter: assets:`.