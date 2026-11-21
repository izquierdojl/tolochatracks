# Tasks

## 1. Perfil y persistencia

- [x] 1.1 Crear `PerfilGps` (Ahorro, Equilibrada, Máxima) con etiqueta, descripción, intervalo, distancia mínima, precisión máxima y calidad; verificar con un test de valores y `flutter analyze` en verde.
- [x] 1.2 Añadir el perfil a `Ajustes`, `ConfiguracionRepositorio` y `ConfiguracionController` con clave `config.gps.perfil` y valor por defecto Equilibrada; verificar con tests de guardado, carga y clave ausente, y `flutter analyze` en verde.

## 2. Servicio de ubicación

- [x] 2.1 Usar `Position.hasSpeed` al convertir a `PuntoGps` y extraer la conversión para poder testear `hasSpeed` true/false y velocidad 0; verificar con tests y `flutter analyze` en verde.
- [x] 2.2 Mapear cada perfil a `AndroidSettings` (calidad, intervalo, distancia mínima, `forceLocationManager` y `useMSLAltitude`) en una función testeable; verificar con tests de los tres perfiles y `flutter analyze` en verde.
- [x] 2.3 Cambiar `ServicioUbicacion.posiciones` para recibir el perfil y actualizar el fake y `GrabacionController`; verificar con un test que el perfil elegido llega al servicio, y `flutter analyze` en verde.

## 3. Filtro y velocidad

- [x] 3.1 Parametrizar `puntoAceptable` con precisión máxima y velocidad máxima de la actividad; verificar con tests de 25/35/45 m, correr/caminar/bicicleta y `flutter analyze` en verde.
- [x] 3.2 Añadir a `AcumuladorRuta` el filtro por perfil y actividad, el calentamiento por segmento y la velocidad `min(reportada, derivada)` con respaldo de ventana; verificar con tests de 52,5/3,8, 18,4/5,9, sin `vel` y primer punto de segmento, y `flutter analyze` en verde.
- [x] 3.3 Crear una vista única de puntos válidos (40 m, tope de actividad, segmentos) para estadísticas, mapa y exportación; verificar con una sesión antigua sintética con puntos de 44,2/54,7 m y segmentos, y `flutter analyze` en verde.
- [x] 3.4 Hacer que `calcularEstadisticas` use la vista válida, el tope de actividad y la velocidad fiable en máximo y series; verificar con tests de máximo y serie sin picos de un solo punto, y `flutter analyze` en verde.

## 4. Captura

- [x] 4.1 Inyectar el perfil en `GrabacionController` y usarlo al iniciar y reanudar; verificar con tests de que la grabación usa el perfil vigente y `flutter analyze` en verde.
- [x] 4.2 Implementar el calentamiento de 5 s o dos posiciones buenas tras arrancar/reanudar; verificar con tests de arranque impreciso y reanudación con 33,9/21,4 km/h, y `flutter analyze` en verde.
- [x] 4.3 Exponer `precisionActual` y `senalDebil` en el controlador y actualizarlos con cada punto; verificar con tests de precisión buena, precisión débil y más de 5 s sin punto, y `flutter analyze` en verde.

## 5. Interfaz

- [x] 5.1 Añadir la sección GPS a Ajustes con el selector de perfil y la explicación de batería/precisión; verificar con un widget test de las tres opciones y la persistencia, y `flutter analyze` en verde.
- [x] 5.2 Mostrar `±N m` y el aviso de señal débil en la pantalla de grabación; verificar con un widget test de los estados buena/débil/sin señal, y `flutter analyze` en verde.

## 6. Integración de la ruta válida

- [x] 6.1 Hacer que el detalle, el mapa y la exportación usen la misma vista válida y conserven los segmentos; verificar con tests de GPX, JSON y mapa con un punto descartado, y `flutter analyze` en verde.
- [x] 6.2 Actualizar `AGENTS.md` §2 con los perfiles y revisar que la configuración de OpenSpec sigue intacta; verificar con `scripts/check_openspec_config.sh` y `flutter analyze` en verde.

## 7. Verificación final

- [x] 7.1 Ejecutar `npm run verify` y comprobar formato, análisis y tests en verde.
- [x] 7.2 Revisar con una sesión sintética que imita el GPX real (52,5 km/h, 80 m de pausa) que el máximo ronda 11 km/h y la distancia no incluye la pausa; verificar el resultado y `flutter analyze` en verde.

## Workflow follow-up

- Aplicar este change después de archivar `bug-a508b400-corrige-la-distancia-y-la-traza-al-reanudar-tras-una-pausa`.
- Archivar el change tras la revisión y el commit en `dev`.
- No tocar la versión a mano: `version.yml` la calcula al fusionar en `dev`.
