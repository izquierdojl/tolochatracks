# Tasks

## 1. Servicio de compartir

- [x] 1.1 Crear `ServicioCompartir` y `ServicioCompartirCanal`, que escribe el GPX en
  `getTemporaryDirectory()/compartir` y llama al canal de plataforma; verificar con
  `flutter analyze && flutter test` en verde.
- [x] 1.2 Añadir `compartirArchivo` a `MainActivity` con `FileProvider`, `ACTION_SEND` y
  `file_paths.xml`, y declarar el provider en el manifiesto; verificar con
  `flutter build apk --debug` y abriendo el selector en el emulador.
- [x] 1.3 Crear `CompartirController` con progreso, sesión activa, error y limpieza de
  errores, y un `ServicioCompartirFalso` para tests; verificar con tests del controlador
  (éxito, error, sin puntos y doble pulsación) y `flutter analyze && flutter test` en
  verde.

## 2. Puntos de acceso

- [x] 2.1 Añadir «Compartir ruta» al `AppBar` del detalle con progreso y `SnackBar` de
  error, sin pedir carpeta de exportación; verificar con widget test del detalle y
  `flutter analyze && flutter test` en verde.
- [x] 2.2 Añadir la acción de compartir a cada tarjeta del historial sin abrir el detalle
  y sin perder el filtro; verificar con widget test del historial y
  `flutter analyze && flutter test` en verde.
- [x] 2.3 Inyectar `CompartirController` en `main.dart` y en el harness de tests; verificar
  con `flutter analyze && flutter test` en verde.

## 3. Verificación

- [x] 3.1 Ejecutar `npm run verify` (formato, analyze y tests) y corregir cualquier fallo.
- [x] 3.2 Compilar el APK y probar en el emulador: compartir desde el detalle y desde una
  tarjeta, cancelar el selector, compartir sin carpeta configurada y sin conexión.

## Workflow follow-up

- Archivar el change cuando la revisión y el `npm run verify` estén en verde.
- Commitear los artefactos y el código en `dev` antes del merge.
