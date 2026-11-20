# Proposal

## Why

La grabación es la capacidad fundacional de TolochaTracks: sin una captura de GPS fiable,
rápida y con recuperación ante cierres, el historial, las estadísticas y la exportación no
tienen datos que mostrar. La referencia es MyTracks: elegir actividad, pulsar grabar y
poder guardar el móvil sin perder la ruta.

## What Changes

- Modelo de dominio de una ruta: actividad, puntos GPS (posición, altitud, precisión,
  velocidad), inicio/fin, duración activa y serialización JSON versionada.
- Cálculos incrementales de distancia (Haversine con filtro de ruido), desnivel con
  umbral, velocidad y ritmo, reutilizables por el historial y las estadísticas.
- Servicio de ubicación sobre `geolocator` con permiso bajo demanda, alta precisión,
  notificación de servicio en primer plano y manejo de GPS desactivado/permiso denegado.
- Controlador de grabación con estados inactivo/iniciando/grabando/pausado/guardando/error,
  pausa y reanudación sin perder puntos, y guardado automático en un borrador.
- Recuperación al arrancar: si existe un borrador de una grabación interrumpida, la app
  ofrece recuperarlo o descartarlo.
- Pantalla de grabación: selector de actividad, botón grande de inicio, estadísticas en
  vivo (tiempo, distancia, ritmo/velocidad, desnivel), aviso de señal y controles de
  pausa/finalizar. Guardado local obligatorio antes de dar la sesión por terminada.
- Al finalizar, la sesión se guarda en el registro interno y se muestra un resumen con
  acceso al historial.

## Capabilities

### New Capabilities

- `grabacion-rutas`: inicio, pausa, reanudación y finalización de una grabación GPS con
  actividades, servicio en primer plano, tolerancia a pérdida de señal y borrador
  recuperable.

### Modified Capabilities

_(ninguna: es la primera capacidad del producto)_

## Impact

- Código nuevo: `lib/core/models`, `lib/core/calculos`, `lib/core/servicios`,
  `lib/features/grabacion`.
- Almacenamiento: `path_provider` y archivos JSON en documentos de la app; borrador fijo
  `sesiones/borrador.json`.
- Android: permisos de ubicación, servicio en primer plano y notificación persistente.
- Dependencias: `geolocator` y `geolocator_android` (configuración específica de Android),
  `path` para rutas de archivos.
- `lib/main.dart` monta el controlador y la pantalla real; el historial queda como
  consumidor mínimo para confirmar que la sesión se guardó (se completa en su change).

## Fuera de alcance

- Historial completo, detalle, gráficos y mapas (changes posteriores).
- Exportación GPX/JSON a disco.
- Cuentas, sincronización o subida de rutas.
- Auto-pausa por velocidad, sensores de cadencia/pulso o grabación tras reiniciar el
  teléfono.
