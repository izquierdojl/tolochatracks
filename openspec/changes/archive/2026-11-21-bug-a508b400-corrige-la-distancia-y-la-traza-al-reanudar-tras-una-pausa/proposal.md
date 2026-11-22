# Proposal

## Why

La primera grabación real destapó que, al reanudar tras una pausa, la app suma a la
distancia el trecho recorrido durante la pausa y lo dibuja como una línea recta. En esa
sesión fueron 100,1 m (5,9 % de 1,705 km), incluida una línea de 79,8 m, y la traza y las
estadísticas quedan falseadas. La pausa debe cortar la ruta, no unir sus extremos. Es un
fallo independiente del filtro de precisión GPS, así que se corrige primero y por
separado.

## What Changes

- Al pausar, la grabación cierra el segmento activo; al reanudar, el primer punto válido
  abre un segmento nuevo y no suma distancia ni velocidad desde el punto anterior a la
  pausa.
- La sesión guarda los cortes de segmento para que el GPX escriba varios `<trkseg>`, el
  mapa no una los extremos de la pausa y las estadísticas calculen el tiempo activo sin
  los huecos.
- Las series, parciales y el gráfico por minuto usan tiempo activo; los minutos de pausa
  no aparecen como minutos con cero metros ni desplazan la escala.
- Compatibilidad: las sesiones antiguas sin cortes guardados se interpretan con cortes
  inferidos en huecos superiores a 60 s (o con el tiempo activo guardado); no se reescribe
  el JSON original.
- La primera posición de cada segmento no genera velocidad ni distancia; solo marca el
  inicio.
- El formato de sesión añade un campo opcional y tolerante: las sesiones antiguas siguen
  abriéndose sin migración.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `grabacion-rutas`: la pausa y la reanudación cortan el segmento; la distancia y la
  velocidad no cruzan la pausa.
- `estadisticas-ruta`: series, parciales y por minuto usan tiempo activo y respetan los
  segmentos.
- `mapas-ruta`: la polilínea se dibuja por segmentos y no une los extremos de una pausa.
- `exportacion-sesiones`: el GPX usa un `<trkseg>` por segmento; el JSON conserva los
  cortes.

## Impact

- `lib/core/models/punto_ruta.dart` y `sesion.dart`: segmento o cortes y formato tolerante.
- `lib/features/grabacion/ui/grabacion_controller.dart`: cortes al pausar/reanudar y
  borrador recuperable.
- `lib/core/calculos/calculos_ruta.dart`: acumulador, series, parciales y por minuto.
- `lib/core/exportacion/gpx.dart` y `exportacion_sesion.dart`: varios `<trkseg>`.
- `lib/features/sesiones/ui/widgets/mapa_ruta.dart` y `grafico_sesion.dart`: segmentos y
  tiempo activo.
- Tests de cálculos, serialización, exportación y widgets; fixtures sintéticos.
- Sin cambios de permisos, dependencias ni red.

## Fuera de alcance

- El filtro de precisión GPS, la velocidad reportada y los perfiles de Ajustes: van en el
  change `feature-f5cfb939-calidad-gps-configurable-y-velocidad-fiable`.
- Pausa automática, map matching y suavizado de la traza.
- Reescribir los archivos JSON de sesiones antiguas.
- Cambiar el formato GPX más allá de separar los segmentos de pausa.
