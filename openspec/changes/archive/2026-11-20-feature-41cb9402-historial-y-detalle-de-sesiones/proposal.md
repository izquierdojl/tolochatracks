# Proposal

## Why

Grabar ya es posible, pero una ruta guardada solo se ve como una tarjeta resumen y no se
puede consultar en detalle ni eliminar. Sin un historial navegable, la app no cumple el
flujo de MyTracks: grabar, consultar la ruta y gestionarla.

## What Changes

- Historial con totales (rutas, distancia, tiempo), filtro por actividad y tarjetas
  ordenadas de la más reciente a la más antigua.
- Navegación de cada tarjeta a una pantalla de detalle con estadísticas completas:
  distancia, tiempo activo y total, ritmo/velocidad media y máxima, desnivel positivo y
  negativo, altitudes mínima/máxima y número de puntos.
- Eliminación de una sesión desde el detalle y desde el historial, con confirmación,
  actualizando los totales y el estado vacío.
- Estados de carga, error con reintento y vacío ya existentes, adaptados al filtro.
- Cálculo y caché de estadísticas por sesión para no recalcular en cada reconstrucción.

## Capabilities

### New Capabilities

- `historial-sesiones`: consulta, filtrado, detalle y eliminación de las rutas guardadas
  en el dispositivo.

### Modified Capabilities

_(ninguna: `grabacion-rutas` no cambia su comportamiento)_

## Impact

- Código: `lib/features/sesiones/ui` (controlador, historial, detalle y widgets).
- Sin dependencias nuevas ni cambios de Android.
- Los archivos JSON internos no cambian de formato.
- La pantalla de detalle será el punto de entrada de los gráficos y los mapas en sus
  changes posteriores.

## Fuera de alcance

- Gráficos, parciales por km y mapas de la ruta (changes posteriores).
- Exportación a disco.
- Edición de nombre/notas o recorte de la ruta.
- Favoritos, búsqueda por texto o estadísticas globales por periodo.
