# Proposal

## Why

La primera grabación real mostró una velocidad máxima de 52,5 km/h cuando la velocidad
reportada por el GPS era 3,8 km/h: un salto de posición de 43,8 m con precisión de 54,7 m
pasó los filtros de 100 m y 198 km/h. La app ignora la velocidad del GPS al calcular el
máximo y no ofrece al usuario elegir entre más detalle y más batería. Sin un filtro
coherente, la traza, el resumen y el GPX no son fiables. Este change se aplica después del
bug de pausas, porque comparte el modelo de segmentos y la exportación.

## What Changes

- Añadir en Ajustes un perfil de calidad GPS persistente: Ahorro, Equilibrada (por
  defecto) y Máxima. Cada perfil fija intervalo, distancia mínima, calidad del proveedor y
  umbral de precisión; el texto explica el intercambio batería/precisión.
- Filtrar posiciones por precisión (40/30/20 m según perfil) y por velocidad plausible
  según actividad; descartar los primeros segundos de velocidad tras arrancar o reanudar.
- Calcular la velocidad máxima con la velocidad reportada por el GPS cuando existe,
  combinada con la derivada (`min`), y usar una ventana de 10-15 s cuando no hay velocidad
  reportada. Usar `Position.hasSpeed` para distinguir 0 de «sin dato».
- Mostrar la precisión actual (`±8 m`) y un aviso de señal débil durante la grabación.
- Usar los mismos puntos válidos en estadísticas, mapa y exportación; las sesiones
  antiguas se recalculan al abrir el detalle sin reescribir su JSON.
- Actualizar `AGENTS.md` para sustituir la configuración fija `LocationAccuracy.high` y
  `distanceFilter: 3 m` por los perfiles.
- Sin permisos nuevos; todo sigue funcionando sin conexión y sin mapas.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `grabacion-rutas`: calidad de los puntos, filtro por perfil, velocidad fiable y aviso de
  precisión.
- `estadisticas-ruta`: velocidad máxima y series a partir de la velocidad reportada y los
  puntos válidos.
- `configuracion`: nueva preferencia de calidad GPS y control en Ajustes.
- `exportacion-sesiones`: el GPX y el JSON exportan la ruta filtrada, conservando los
  segmentos de pausa del change anterior.

## Impact

- `lib/core/servicios/ubicacion.dart`: perfiles, `hasSpeed` y `AndroidSettings`.
- `lib/core/calculos/calculos_ruta.dart`: filtros, velocidad máxima y series.
- `lib/features/configuracion/data/...` y `ui/...`: persistencia y control del perfil.
- `lib/features/grabacion/ui/grabacion_controller.dart` y `grabacion_pantalla.dart`:
  perfil, calentamiento tras reanudar, precisión y señal.
- `lib/features/sesiones/ui/...`: detalle, mapa y gráficos con puntos válidos.
- `lib/core/exportacion/...`: puntos válidos y segmentos.
- `lib/main.dart`: inyección del perfil; tests y fixtures sintéticos.
- `AGENTS.md` §2: configuración de ubicación. Sin dependencias nuevas.

## Fuera de alcance

- Map matching, suavizado Kalman/EMA y descarga de mapas.
- Cambiar a Play Services/FusedLocationProvider fuera del `LocationManager` actual.
- Pausa automática, ubicación en segundo plano y permisos nuevos.
- Umbrales manuales por actividad o perfiles personalizados.
- Reescribir el JSON de sesiones antiguas; se recalculan al mostrarlas.
