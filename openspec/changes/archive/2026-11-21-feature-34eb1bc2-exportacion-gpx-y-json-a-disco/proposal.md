# Proposal

## Why

Las rutas son datos del usuario y deben poder salir del móvil sin depender de una nube:
para archivarlas, analizarlas en otra herramienta o compartirlas. MyTracks exportaba GPX;
TolochaTracks añade también JSON nativo. La carpeta de destino se elige una vez y se
recuerda.

## What Changes

- Exportación de una sesión o de todas las visibles a una carpeta elegida con el selector
  SAF de Android, con permiso persistente.
- Dos formatos por sesión: GPX 1.1 (estándar para rutas) y JSON nativo (copia completa).
- Nombres de archivo estables y legibles; informe de exportados y errores parciales.
- Ajustes reales: tema (sistema/claro/oscuro), carpeta de exportación con nombre visible
  y opción de cambiarla o quitarla.
- Acciones «Exportar ruta» en el detalle y «Exportar todo» en el historial, con estados de
  progreso y mensajes en español.
- Si no hay carpeta configurada, se pide elegirla antes de exportar; cancelar no exporta.

## Capabilities

### New Capabilities

- `exportacion-sesiones`: generación de GPX/JSON y escritura en una carpeta concedida por
  el usuario mediante el selector del sistema.
- `configuracion`: preferencias persistentes (tema y carpeta de exportación) con valores
  por defecto y una pantalla de ajustes real.

### Modified Capabilities

_(ninguna: los botones de exportación forman parte de la nueva capacidad
`exportacion-sesiones`)_

## Impact

- Código: `lib/core/servicios/exportacion.dart`, `lib/core/exportacion`,
  `lib/features/exportacion`, `lib/features/configuracion`, detalle e historial.
- Android: se usa el canal SAF ya creado en `MainActivity`; sin permisos nuevos.
- Dependencias existentes `shared_preferences`, `path_provider` y `url_launcher`.
- Tests de GPX/JSON, nombres, controlador de exportación y ajustes.

## Fuera de alcance

- Exportación automática o programada.
- Compartir por correo/otras apps (se puede añadir después con el share sheet).
- Importar GPX/JSON.
- Formatos KML, TCX o CSV.
- Mapas y «Acerca de» (changes posteriores).
