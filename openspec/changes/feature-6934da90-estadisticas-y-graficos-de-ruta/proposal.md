# Proposal

## Why

El detalle actual solo muestra cifras agregadas. La referencia MyTracks destaca por sus
gráficos y parciales, que permiten entender cómo fue la ruta: dónde se subió, dónde se
bajó el ritmo y cómo se distribuyó el esfuerzo. Sin esto, el historial es solo una lista
de totales.

## What Changes

- Cálculos puros de series a partir de los puntos: distancia acumulada frente a tiempo,
  velocidad frente a distancia, altitud frente a distancia y metros por minuto activo.
- Parciales por kilómetro con distancia, duración y ritmo/velocidad media, incluido el
  último tramo incompleto.
- Pantalla de detalle con tarjeta de gráficos conmutables (Distancia, Velocidad,
  Altitud, Por minuto) y tarjeta de parciales.
- Estados vacíos para rutas sin puntos o sin altitudes, sin romper la pantalla.
- Filtros y muestreo de series para mantener los gráficos fluidos en rutas largas.

## Capabilities

### New Capabilities

- `estadisticas-ruta`: series temporales, parciales por kilómetro y distribución por
  minuto calculadas de forma determinista a partir de los puntos de una sesión.

### Modified Capabilities

- `historial-sesiones`: el detalle añade gráficos y parciales; se mantienen sus
  requisitos actuales.

## Impact

- Código: `lib/core/models/estadisticas_ruta.dart`, `lib/core/calculos/calculos_ruta.dart`,
  `lib/features/sesiones/ui/sesion_detalle_pantalla.dart` y widgets de gráficos.
- Dependencia existente `fl_chart`; sin cambios de Android ni de formato de archivos.
- Los tests de cálculos cubren series, parciales y minutos con datos sintéticos.

## Fuera de alcance

- Mapas de la ruta (change posterior).
- Exportación.
- Comparación entre sesiones o mejores marcas.
- Edición de puntos o recorte.
