# PictoComm

App Flutter **local-first** para comunicación por imágenes en niños autistas no verbales de 2 a 5 años: el niño arma una frase tocando pictogramas por categoría y la reproduce en voz alta (TTS) con Play, siguiendo el modelo de la tira de frase de PECS (construir primero, "hablar" bajo demanda).

![Flutter](https://img.shields.io/badge/Flutter-stable-blue) ![Backend](https://img.shields.io/badge/backend-Dart%20(shelf)-green)

## Qué puede hacer

- **Comunicar**: tira de frase con feedback visual al tocar, Play palabra por palabra con TTS offline, corrección por niveles (mini-basura, backspace, basura global).
- **Catálogo**: categorías y pictos incluidos, pictos multicategoría, pictos y categorías personalizadas (crear, editar, borrar con doble confirmación).
- **Perfiles**: varios niños por dispositivo, sesión activa, último chico preseleccionado en el selector.
- **Cuentas**: registro/login contra el backend, sesión recordada (la app abre sin conexión con sesión válida), logout.
- **Backend y sync**: catálogo remoto sincronizado al arrancar (descarga) + subida bidireccional de lo custom (outbox con reintentos, borrado lógico), indicador de sync en modo adulto.
- **Idioma**: UI en español (default), inglés y portugués; la voz sigue el idioma de la UI.

## Estructura

```
src/frontend/     # App Flutter (features verticales: catalog, profiles, auth, voice, idioma, sync)
src/backend/      # Paquete Dart puro (shelf): API del catálogo + cuentas, seed JSON
docs/             # Requerimientos (REQ-*) y specs por funcionalidad; índice en docs/specs/0000-index.md
```

Arquitectura y convenciones de código: ver [AGENTS.md](AGENTS.md). Propósito y alcance: [overview.md](overview.md).

## Requisitos

- Flutter SDK (rama stable) en `D:\flutter` — `flutter` **no** está en el PATH: usar `D:\flutter\bin\flutter.bat`.
- Dart (viene con Flutter).
- Git en `C:\Program Files\Git\bin\git.exe`.

## Correr el proyecto

### 1. Backend (API del catálogo + cuentas)

```powershell
cd src\backend
D:\flutter\bin\dart.bat pub get
D:\flutter\bin\dart.bat run bin\server.dart   # escucha en http://localhost:8080 (env: PORT)
```

El backend sirve el catálogo desde `src/backend/data/seed.json` + `data/images/` y persiste cuentas/sesiones en `data/accounts.json` (se crea al primer registro).

### 2. App (frontend)

```powershell
cd src\frontend
D:\flutter\bin\flutter.bat pub get
# Windows desktop (requiere Developer Mode y nuget.exe — ver "Gotchas" de AGENTS.md):
D:\flutter\bin\flutter.bat run -d windows
# Android (sync contra el backend en la máquina host):
D:\flutter\bin\flutter.bat run --dart-define=PICTOCOMM_BACKEND_URL=http://10.0.2.2:8080
```

La URL del backend se configura con `--dart-define=PICTOCOMM_BACKEND_URL` (default `http://localhost:8080`). Sin backend la app funciona igual: es local-first, el sync falla en silencio.

## Tests y lint

```powershell
# backend (desde src\backend)
D:\flutter\bin\dart.bat analyze ; D:\flutter\bin\dart.bat test

# frontend (desde src\frontend)
D:\flutter\bin\flutter.bat analyze ; D:\flutter\bin\flutter.bat test
```

## Build de release

```powershell
# APK Android (desde src\frontend; con backend remoto pasar el --dart-define correspondiente)
D:\flutter\bin\flutter.bat build apk --release

# Windows desktop
D:\flutter\bin\flutter.bat build windows --release
```

Para cambiar el ícono de la app: editar `src/frontend/icon.png` y correr `dart run flutter_launcher_icons` (config en `pubspec.yaml`).

## Documentación funcional

- **Requerimientos** (qué debe hacer): `docs/requerimientos/implementados/REQ-*.md` — RF/RNF, casos de uso, criterios Given/When/Then.
- **Specs** (cómo lo hace hoy): `docs/specs/aprobadas/*.md` — comportamiento real, archivos, limitaciones.
- **Índice**: `docs/specs/0000-index.md`.

Flujo: cambiar una funcionalidad = actualizar el REQ primero y luego su spec.

## Decisiones vigentes (cierre v2)

| Tema | Decisión |
|---|---|
| Auth de escritura del backend | Los endpoints de escritura quedan abiertos (v1/v2); el riesgo está aceptado y documentado en REQ-BCK-02 |
| Idioma de la voz (TTS) | Sigue el idioma de la UI, con fallback a la voz del sistema |
| Imágenes custom | Se comprimen al entrar (reescala a máx. 1024px) |
| Chico activo | La app abre en el selector con el último chico de la cuenta preseleccionado (un tap confirma) |
| Distribución | Demo local pulida; el backend corre local (sin deploy) |
