# Tasks

## 1. Modelo y persistencia

- [x] 1.1 Añadir `exportada` a `Sesion`, subir el formato de sesión a 2 y hacer el parser
  tolerante con JSON antiguos, con un método de copia inmutable; verificar con tests de
  round-trip, sesión sin el campo y `flutter analyze && flutter test` en verde.
- [x] 1.2 Añadir `HistorialController.actualizarExportadas(intentadas, correctas)` que
  actualiza la lista en memoria y guarda cada sesión con el repositorio; verificar con
  tests de marcar, desmarcar, sesiones no intentadas y fallo de guardado, y
  `flutter analyze && flutter test` en verde.

## 2. Resultado por sesión

- [x] 2.1 Extender `ResultadoExportacion` con los nombres de archivos correctos y las
  sesiones exportadas; hacer que el canal nativo devuelva `nombres` y actualizar el fake;
  verificar con tests del controlador (una sesión, varias, error parcial) y
  `flutter analyze && flutter test` en verde.
- [x] 2.2 Tras exportar desde el detalle y desde el historial, llamar a
  `actualizarExportadas` con las sesiones intentadas y las completas; verificar con widget
  tests de exportación correcta y fallida y `flutter analyze && flutter test` en verde.

## 3. Borrado de archivos exportados

- [x] 3.1 Añadir `borrar` a `ServicioExportacion`, implementarlo en el canal SAF nativo y
  en el fake, devolviendo borrados, no encontrados y errores; verificar con tests del
  servicio y `flutter analyze && flutter test` en verde.
- [x] 3.2 Añadir `ExportacionController.borrarArchivosDeSesion` usando la carpeta actual y
  los nombres GPX/JSON; verificar con tests de éxito, sin carpeta y permiso perdido, y
  `flutter analyze && flutter test` en verde.
- [x] 3.3 Implementar el diálogo de eliminación con casilla desmarcada por defecto, nombre
  de la carpeta, aviso si no hay carpeta y mensajes de resultado parcial; verificar con
  widget tests de borrar con archivos, conservarlos, ruta no exportada y fallo externo, y
  `flutter analyze && flutter test` en verde.

## 4. Check en la UI

- [x] 4.1 Mostrar el check «Exportada a disco» en la tarjeta del historial con etiqueta
  semántica y color del tema; verificar con widget test de ruta exportada y no exportada,
  y `flutter analyze && flutter test` en verde.
- [x] 4.2 Mostrar «Exportada a disco» en la cabecera del detalle; verificar con widget test
  de sesión exportada y no exportada, y `flutter analyze && flutter test` en verde.

## 5. Verificación

- [x] 5.1 Ejecutar `npm run verify` (formato, analyze y tests) y corregir cualquier fallo.
- [x] 5.2 Compilar el APK y probar en el emulador: exportar una ruta, ver el check,
  eliminar con y sin archivos, y repetir con la carpeta cambiada o el permiso perdido.

## Workflow follow-up

- Archivar el change cuando la revisión y el `npm run verify` estén en verde.
- Commitear los artefactos y el código en `dev` antes del merge.
