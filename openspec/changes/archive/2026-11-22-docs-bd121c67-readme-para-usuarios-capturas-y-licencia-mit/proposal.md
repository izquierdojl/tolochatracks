# Proposal

Tipo de change: `docs`.

## Why

TolochaTracks ya se puede instalar y usar, pero su README está escrito para quien
desarrolla: empieza por la arquitectura, OpenSpec y los releases, y no muestra la app.
Quien llega desde una release no ve qué hace ni cómo se ve, y el repositorio no declara
una licencia explícita. Este change convierte la portada del repositorio en una
presentación para personas usuarias, con capturas reales y licencia MIT.

## What Changes

- Reescribir `README.md` con un enfoque de producto: qué es TolochaTracks, capturas,
  funciones explicadas sin jerga, instalación del APK, privacidad, licencia y enlaces.
- Añadir capturas reales de la app (grabación, historial, detalle con gráficos, mapa y
  ajustes) en `docs/capturas/` y mostrarlas en el README.
- Crear `docs/` con la documentación técnica que sale del README: índice, desarrollo,
  arquitectura, releases/CI y mapas/privacidad. El README enlaza a estos documentos.
- Añadir `LICENSE` con la licencia MIT y titular `izquierdojl`, y una sección de licencia
  en el README.
- Actualizar la pantalla «Acerca de» para indicar que el código se distribuye bajo
  licencia MIT.
- Mantener intactas las funciones: solo cambian la documentación y el texto de licencia
  de la app.

## Capabilities

### New Capabilities

Ninguna. La documentación del repositorio se entrega como artefactos del change, no como
comportamiento de la app.

### Modified Capabilities

- `acerca-de`: la licencia del código deja de remitir genéricamente al repositorio y pasa
  a declararse explícitamente como MIT.

## Impact

- Documentación: `README.md`, `docs/**` y `LICENSE`.
- Código: `lib/features/configuracion/ui/acerca_de_pantalla.dart` (texto de licencia) y
  una prueba de widget que lo verifica.
- Specs: delta de `acerca-de`; el resto de capacidades no cambia.
- Sin cambios de dependencias, permisos, datos, exportación ni grabación.
- Las capturas se generan en el emulador con sesiones de ejemplo locales; no incluyen
  rutas ni datos personales reales.

## Fuera de alcance

- Cambiar la licencia de las dependencias, de las teselas o de la tipografía Inter (SIL
  Open Font License 1.1).
- Publicar en Play Store, iOS, escritorio o web.
- Traducciones a otros idiomas.
- Rediseñar la interfaz o añadir funciones nuevas.
- Vídeos, GIF animados o una web de presentación: solo capturas estáticas.
- Reescribir `AGENTS.md`, que sigue siendo la constitución interna del proyecto.
