# Requerimientos

Esta carpeta es **meramente normativa**: contiene la documentación de requerimientos del proyecto (funcionales y no funcionales).

## Estructura

- `implementados/` — requerimientos ya implementados, **un documento por feature**, con el formato `REQ-<MODULO>-NN-<slug>.md`:

  | Documento | Feature | Requerimientos |
  |---|---|---|
  | [`REQ-COM-01-comunicacion.md`](implementados/REQ-COM-01-comunicacion.md) | Comunicación (tira de frase + Play) | RF-1.x |
  | [`REQ-PER-01-perfiles.md`](implementados/REQ-PER-01-perfiles.md) | Perfiles de niño | RF-2.x |
  | [`REQ-CAT-01-catalogo.md`](implementados/REQ-CAT-01-catalogo.md) | Catálogo y pictogramas personalizados | RF-3.x |
  | [`REQ-IDI-01-idioma.md`](implementados/REQ-IDI-01-idioma.md) | Idioma de la app (i18n) | RF-4.x |

  Formato interno de cada documento: Objetivo, Estado actual, Estado objetivo, Requerimientos funcionales (RF), Requerimientos no funcionales (RNF), Casos de uso (UC), Criterios de aceptación (CA, Given/When/Then), Fuera de alcance y Decisiones.

## Convenciones

- Documentar en Markdown (`.md`), un documento por tópico.
- Los requerimientos aquí definidos son la referencia de verdad: los cambios en el código o en prototipos deben alinearse con ellos, no al revés.
- Cualquier cambio sobre un requerimiento aprobado queda registrado en el propio documento (historial / versión).
- Los specs de usuario de cada funcionalidad viven en [`../specs/`](../specs/): el detalle de "cómo funciona hoy" va ahí, no acá.
