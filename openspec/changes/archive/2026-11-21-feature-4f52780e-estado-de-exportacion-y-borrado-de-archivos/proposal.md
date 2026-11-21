# Proposal

**Tipo:** feature · **Rama:** dev

## Why

La exportación actual no deja rastro en la app: el usuario no sabe qué rutas ya tienen
copia en disco y, al borrar una ruta, los GPX/JSON exportados quedan huérfanos. Marcar
las rutas exportadas y ofrecer borrar sus archivos mantiene el historial y la carpeta
de exportación coherentes, sin borrar documentos sin permiso explícito.

## What Changes

- La sesión guarda si su última exportación completó el GPX y el JSON; el historial y el
  detalle muestran un check «Exportada a disco».
- La exportación de una ruta o del historial visible actualiza ese estado solo para las
  sesiones cuyos dos archivos se escribieron correctamente.
- Al eliminar una ruta exportada, el diálogo ofrece una casilla desmarcada por defecto
  para borrar también el GPX y el JSON de la carpeta de exportación actual.
- Si no hay carpeta o se perdió el permiso, se explica y se puede eliminar solo la ruta.
- El resultado del borrado de archivos se informa por separado; la ruta local se elimina
  aunque falle el borrado externo.
- Sin dependencias nuevas: se amplía el canal SAF existente.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `exportacion-sesiones`: la exportación registra el resultado por sesión y añade el
  borrado de los archivos exportados.
- `historial-sesiones`: el listado y el detalle muestran el estado de exportación y el
  diálogo de eliminación permite borrar los archivos asociados.

## Impact

- Código: `lib/core/models/sesion.dart`,
  `lib/features/sesiones/data/sesiones_repositorio.dart`,
  `lib/features/sesiones/ui/historial_controller.dart`,
  `lib/features/exportacion/ui/exportacion_controller.dart`,
  `lib/core/servicios/exportacion.dart`, detalle e historial.
- Android: `MainActivity` (método `borrar` en el canal de exportación), sin permisos
  nuevos.
- Persistencia: nuevo campo opcional `exportada` en el JSON de sesión, tolerante con
  archivos antiguos; formato de sesión incrementado.
- Tests: serialización, controlador del historial, controlador de exportación, servicio
  falso y widget tests de check y eliminación.

## Fuera de alcance

- Verificar en cada arranque si los archivos siguen existiendo en disco.
- Borrar archivos de carpetas de exportación anteriores o ya inaccesibles.
- Borrado masivo desde el historial o limpieza automática.
- Importar GPX/JSON o editar la ruta después de exportarla.
- Compartir rutas (change separado).
