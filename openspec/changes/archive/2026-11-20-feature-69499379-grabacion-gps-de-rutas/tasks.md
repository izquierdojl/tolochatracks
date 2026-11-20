# Tasks

## 1. Modelo y cálculos

- [x] 1.1 Añadir `geolocator_android` y `path` a `pubspec.yaml`
- [x] 1.2 Crear `Actividad`, `PuntoRuta` y `Sesion` con JSON versionado y parseo tolerante
- [x] 1.3 Implementar Haversine, filtros de puntos, distancia y desnivel con histéresis
- [x] 1.4 Implementar estadísticas completas (velocidad media/máxima, ritmo, altitudes)
- [x] 1.5 Tests unitarios de distancia, desnivel, estadísticas y round-trip JSON

## 2. Persistencia y ubicación

- [x] 2.1 `SesionesRepositorio` con guardado atómico, listado tolerante y borrador
- [x] 2.2 Tests del repositorio con directorio temporal (guardar, listar, borrar, corrupto)
- [x] 2.3 Interfaz `ServicioUbicacion` e implementación con geolocator y primer plano
- [x] 2.4 Comprobar permisos, GPS activo y abrir ajustes; estados en español

## 3. Controlador de grabación

- [x] 3.1 Máquina de estados, cronómetro activo y cambio de actividad
- [x] 3.2 Suscripción al stream, filtrado de puntos y estadísticas en vivo
- [x] 3.3 Pausa/reanudación y detección de pérdida de señal
- [x] 3.4 Finalización con guardado atómico, descarte sin puntos y reintento de error
- [x] 3.5 Autoguardado del borrador y recuperación/descarte al arrancar
- [x] 3.6 Tests del controlador con servicio y repositorio falsos

## 4. Pantalla

- [x] 4.1 Selector de actividad y botón de inicio con estados de permiso/GPS
- [x] 4.2 Estadísticas en vivo adaptadas a ritmo o velocidad según actividad
- [x] 4.3 Controles de pausa, reanudar y finalizar con confirmación
- [x] 4.4 Banner de borrador recuperable y aviso de pérdida de señal
- [x] 4.5 Resumen al finalizar y acceso al historial
- [x] 4.6 Widget tests de estados inactivo, grabando, pausado y borrador

## 5. Integración y verificación

- [x] 5.1 Montar controladores y proveedores en `lib/main.dart`
- [x] 5.2 Historial mínimo que lista las sesiones guardadas del repositorio
- [x] 5.3 `npm run verify` en verde y build APK correcto
