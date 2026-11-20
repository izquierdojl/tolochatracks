# Design

## Context

`calcularEstadisticas` ya filtra puntos y calcula totales; el detalle recibe la sesión
completa y la calcula una vez. `fl_chart` ya está en el proyecto. Las series deben ser
datos puros para poder testearlas sin widgets.

## Goals / Non-Goals

**Goals:**

- Series y parciales deterministas, testables y reutilizables.
- Gráficos legibles con pocas muestras y sin dependencia de red.
- Estados vacíos claros para sesiones de un solo punto o sin altitud.

**Non-Goals:**

- Mapas, exportación y comparación entre rutas.
- Edición o suavizado avanzado con filtros de Kalman.

## Decisions

- **Modelos de resultado**: `MuestraRuta` (x, y), `ParcialKm` (número, distancia,
  duración, velocidad media) y `DistanciaMinuto` (minuto, metros) dentro de
  `estadisticas_ruta.dart`; `EstadisticasRuta` los expone inmutables.
- **Filtrado compartido**: se reutiliza `puntoAceptable` y el umbral de jitter de
  `AcumuladorRuta`; los puntos con precisión > 100 m o saltos imposibles no entran en
  las series.
- **Tiempo**: las series y parciales usan el tiempo transcurrido desde el inicio de la
  sesión (incluye pausas), porque el formato de sesión actual no guarda intervalos de
  pausa. El tiempo activo oficial sigue siendo el del cronómetro. Se documenta como
  limitación y una futura versión puede añadir pausas al JSON.
- **Distancia por minuto**: se reparte la distancia de cada segmento entre los minutos
  que solapa proporcionalmente al tiempo, y se rellenan con cero los minutos
  intermedios.
- **Parciales**: se interpolan los cruces de cada 1.000 m sobre la distancia y el tiempo
  acumulados; el último tramo se añade si supera 20 m. La velocidad media del parcial se
  calcula con su duración.
- **Muestreo**: las series se reducen a un máximo de 240 muestras (conservando primera y
  última) antes de pasarlas a `fl_chart`; los parciales y minutos no se muestrean.
- **UI**: tarjeta de gráficos con `SegmentedButton` (Distancia, Velocidad, Altitud, Por
  minuto), `LineChart` para las tres primeras y `BarChart` para minutos; tarjeta de
  parciales con filas compactas. Los gráficos llevan títulos de ejes formateados en
  español y colores del tema (`ColoresRuta`).
- **Cálculo único**: el detalle calcula `EstadisticasRuta` en `initState`, igual que hoy.

## Risks / Trade-offs

- **Pausas**: incluirlas en el tiempo de los parciales simplifica el modelo pero puede
  inflar un parcial; se indica en la especificación y se resolverá con pausas en el JSON
  si el uso lo exige.
- **Rutas largas**: dibujar miles de puntos penaliza; el muestreo de 240 conserva la forma
  y mantiene la interacción fluida.
- **Altitud ruidosa**: se suaviza con media exponencial para el gráfico; los desniveles de
  las tarjetas usan el acumulador con histéresis.
