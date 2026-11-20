# Tasks

## 1. Proveedores de mapas

- [x] 1.1 Crear `ProveedorMapas` con OSM, OpenTopoMap, CyclOSM y sin mapas
- [x] 1.2 Persistir el proveedor en Ajustes y exponerlo en el controlador
- [x] 1.3 Adaptar `MapaRuta` al proveedor, atribución y estado sin mapas
- [x] 1.4 Tests del modelo, persistencia y mapa desactivado

## 2. Notificaciones y controles

- [x] 2.1 Añadir canal nativo `pedirNotificaciones` en MainActivity (esperando respuesta)
- [x] 2.2 Exponer `prepararNotificaciones` en ServicioUbicacion y llamarlo al grabar
- [x] 2.3 Servicio `RutaForegroundService` con notificación y acciones Pausar/Reanudar/Finalizar
- [x] 2.4 Canal `.../ruta` y `ServicioNotificacionRuta` en Dart; ciclo de vida en el controlador
- [x] 2.5 Conectar acciones en `main` (pausar, reanudar, finalizar y refrescar historial)
- [x] 2.6 Tests del controlador con fake y comprobación en Android 13+

## 3. Acerca de y ajustes

- [x] 3.1 Dependencia `package_info_plus` y pantalla Acerca de
- [x] 3.2 Enlaces a repositorio, mapas y licencias con url_launcher
- [x] 3.3 Sección Mapas y acceso a Acerca de en Ajustes
- [x] 3.4 Widget tests de Ajustes y Acerca de

## 4. Batería y acabados

- [x] 4.1 Exención de optimización de batería en Ajustes y canal nativo
- [x] 4.2 Wake lock, `stopWithTask` y GPS de alta precisión con distancia 3 m
- [x] 4.3 README definitivo con funciones, privacidad, mapas, batería y exportación
- [x] 4.4 AGENTS y hoja de ruta actualizados
- [x] 4.5 `npm run verify`, APK y prueba final en emulador (mapas, notificación, batería)
