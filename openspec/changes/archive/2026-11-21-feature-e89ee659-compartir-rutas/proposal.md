# Proposal

**Tipo:** feature · **Rama:** dev

## Why

Hoy una ruta solo se puede sacar del móvil exportándola a una carpeta; para enviarla a
otra persona o app hay que localizar el archivo y compartirlo manualmente. Un botón de
compartir con el selector de Android reduce esa fricción y mantiene la ruta en el
dispositivo hasta que el usuario elige el destino.

## What Changes

- Nuevo servicio de compartir que genera un GPX 1.1 temporal y abre el selector de
  Android (`ACTION_SEND`), sin pedir carpeta de exportación ni conexión.
- Acción «Compartir ruta» en la barra superior del detalle.
- Acción de compartir en cada tarjeta del historial, sin abrir el detalle.
- Estados de progreso, cancelación y error en español; la ruta local no se modifica.
- Sin dependencias nuevas: canal propio de plataforma y `FileProvider`.

## Capabilities

### New Capabilities

- `compartir-rutas`: envío explícito de una sesión como GPX por el selector del sistema,
  con archivos temporales en la caché y sin subida a servidores.

### Modified Capabilities

_(ninguna: el comportamiento de exportación no cambia en este change)_

## Impact

- Código: `lib/core/servicios/compartir.dart`, `lib/features/compartir/`,
  `lib/features/sesiones/ui/sesion_detalle_pantalla.dart`,
  `lib/features/sesiones/ui/historial_pantalla.dart`, `lib/main.dart`.
- Android: `MainActivity` (canal `compartir`), `AndroidManifest.xml` (FileProvider) y
  `res/xml/file_paths.xml`; sin permisos nuevos.
- Tests: controlador de compartir, fake del servicio y widget tests de los dos puntos de
  acceso.
- Dependencias existentes: `path_provider` para la caché y el generador GPX actual.

## Fuera de alcance

- Compartir JSON, un resumen de texto o un enlace.
- Compartir varias rutas a la vez o toda la lista.
- Compartir desde la cabecera global de la app (no hay una ruta seleccionada).
- Subir rutas a la nube, generar enlaces públicos o enviar por correo desde la app.
- Editar el nombre o el contenido del GPX antes de compartir.
- Importar GPX.
