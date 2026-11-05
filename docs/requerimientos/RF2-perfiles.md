# RF2 — Perfiles de niño

| Campo | Valor |
|---|---|
| Estado | En implementación |
| Versión | 1.0 |
| Fecha | 2026-11-05 |

## Descripción

La app es usada por un adulto responsable con uno o más niños a la vez:
cada dispositivo puede tener varios perfiles y la sesión de comunicación
se abre **para un chico específico**.

## Requisitos

### Entrada de sesión

- **RF2.1** — Tras iniciar sesión se muestra el **selector de chico**: una grilla de tarjetas grandes (avatar circular + nombre). El niño (o el adulto con el chico en brazos) toca su tarjeta y entra.
- **RF2.2** — El chico elegido queda como **sesión activa**: es un estado a nivel app, no un argumento de ruta, para que sobreviva la navegación entre pestallas.
- **RF2.3** — Volver al selector de chico es con **botón simple visible** desde las pantallas de sesión (en v1, desde home). Sin puertas parentales para salir (decisión del usuario).
- **RF2.4** — Si no hay perfiles creados, el selector muestra estado vacío con acceso directo a crear el primer perfil.

### Gestión (modo adulto, pantalla Perfil)

- **RF2.5** — La pantalla Perfil lista los perfiles **reales y persistidos** (v1 hoy: mock hardcodeado, se elimina).
- **RF2.6** — Crear un perfil pide **nombre + color de avatar** elegible de una paleta fija. La foto del chico queda para RF3 (precisa permisos de cámara/galería).

  > Supuesto a validar: v1 sin edad. La entidad la conserva opcionalmente para uso futuro.
- **RF2.7** — Borrar un perfil exige **doble confirmación**: primer diálogo con consecuencias ("borra también sus datos"), segundo diálogo de confirmación final.
- **RF2.8** — Si se borra el chico de la sesión activa, la sesión queda sin chico activo.

### Persistencia y arquitectura

- **RF2.9** — Local-first: los perfiles se guardan en el dispositivo (SharedPreferences, JSON). Sin cuenta ni conexión.
- **RF2.10** — Nueva interfaz `ChildProfileRepository` en `domain/` con `getChildren / createChild / deleteChild`. El nombre no puede quedar vacío. Edición de perfiles: v2 (fuera de alcance).
- **RF2.11** — El modelo de `data/models/` lleva `toJson`/`fromJson`, backend-ready como el resto.
- **RF2.12** — La foto del niño se proyecta como campo futuro (`photoUrl` nullable): no se agrega ahora.

## Preguntas abiertas

| # | Pregunta | Estado |
|---|---|---|
| 1 | ¿El login guarda sesión (recuerda usuario y saltea el login)? | Pendiente — hoy se sale con cerrar sesión al reingresar siempre |
| 2 | ¿El selector recuerda el último chico y lo preselecciona? | Pendiente — v1 siempre empieza en selector |

## Notas de implementación (no normativas)

- `SessionProvider` (presentation/providers) guarda el chico activo a nivel `MaterialApp`; no se persiste (cada apertura arranca en selector).
- Los tests usan `FakeChildProfileRepository` en memoria con el mismo contrato.
