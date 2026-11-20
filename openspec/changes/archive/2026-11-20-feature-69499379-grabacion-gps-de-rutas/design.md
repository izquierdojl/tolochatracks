# Design

## Context

La app es Android-only y Flutter 3.47. No hay backend: la ruta se guarda en documentos de
la app. La grabación debe sobrevivir a la pantalla apagada y a cierres inesperados. La
precisión del GPS móvil es variable; las estadísticas no pueden depender de puntos
basura.

## Goals / Non-Goals

**Goals:**

- Empezar a grabar con un toque y mantener la captura con la pantalla apagada.
- Calcular distancia, desnivel, velocidad y ritmo de forma incremental y testeable.
- Guardar de forma atómica y recuperar un borrador si el proceso muere.
- Separar plataforma (geolocator, archivos) de la lógica para poder testear.

**Non-Goals:**

- Historial completo, mapas, gráficos ni exportación.
- Auto-pausa, sensores externos o grabación tras reiniciar el teléfono.

## Decisions

- **Modelo puro**: `PuntoRuta` (lat, lon, tiempo, altitud, precisión, velocidad, rumbo) y
  `Sesion` (id, actividad, inicio, fin, duración activa, puntos) en `lib/core/models`.
  JSON con `formato: 1`; el parseo ignora puntos inválidos en lugar de fallar.
- **Cálculos incrementales en vivo** en `GrabacionController` y funciones puras en
  `lib/core/calculos/calculos_ruta.dart` para el cálculo completo (distancia, desnivel,
  velocidad máxima, parciales futuros). La distancia usa Haversine con filtros:
  precisión ≤ 100 m, velocidad implícita ≤ 55 m/s y umbral de 1,5 m para jitter.
- **Desnivel** con histéresis de 2 m sobre altitudes suavizadas para no sumar ruido.
- **Servicio de ubicación** detrás de `ServicioUbicacion` (interfaz) con implementación
  `ServicioUbicacionGeolocator`. Usa `AndroidSettings(accuracy: bestForNavigation,
  distanceFilter: 2, intervalDuration: 2 s, forceLocationManager: true)` para depender
  del `LocationManager` de Android y no de Google Play Services, y
  `ForegroundNotificationConfig` con texto en español. El wake lock del servicio exige
  declarar `WAKE_LOCK` en el manifest. La interfaz expone `PuntoGps` para no acoplar los
  tests a `Position`.
- **Permisos**: se comprueba el servicio, se solicita el permiso al iniciar y se
  distinguen denegado/denegado para siempre. Si es permanente se ofrece abrir ajustes.
  No se pide ubicación en segundo plano aparte: el servicio en primer plano mantiene la
  captura mientras haya actividad.
- **Controlador** (`ChangeNotifier`) con máquina de estados
  `inactivo|iniciando|grabando|pausado|guardando|error`. El tiempo activo se mide con un
  `Stopwatch` acumulado, no con diferencias de timestamps de puntos (que tienen jitter).
  El stream se cancela al pausar y se recrea al reanudar.
- **Autoguardado**: cada 5 s con puntos nuevos se escribe `sesiones/borrador.json` de
  forma atómica. Al arrancar, `inicializar()` lo carga y lo expone; recuperar pasa a
  `pausado` con los puntos y el tiempo. Se borra al finalizar o descartar.
- **Persistencia** en `SesionesRepositorio`: una sesión por `id.json`, escritura en
  `.tmp` + rename. `listar()` ignora archivos corruptos y ordena por inicio descendente.
  El repositorio se inyecta para usar un directorio temporal en tests.
- **Interfaz**: pantalla única con selector de actividad, botón circular grande,
  estadísticas en tarjetas y banner de borrador. Al finalizar, un diálogo resume y ofrece
  «Ver historial»; el historial mínimo muestra las sesiones guardadas (se completa en su
  propio change).
- **Ubicación y mapas futuros**: la última posición se conserva en el controlador para
  que el mapa del change de mapas pueda seguirla sin recalcular.

## Risks / Trade-offs

- **Fabricantes agresivos** pueden matar el proceso aunque haya notificación; el borrador
  de 5 s limita la pérdida. Se documenta que no hay garantía tras reinicio.
- **Precisión**: los umbrales filtran ruido pero pueden perder metros en caminatas muy
  lentas; se prioriza una distancia creíble sobre la exactitud absoluta.
- **Consumo**: GPS de alta precisión y wake lock consumen batería; es inherente al caso
  de uso y la notificación lo hace visible.
- **Pausas**: los parciales futuros usarán tiempos de puntos; el tiempo activo oficial es
  el del cronómetro.
