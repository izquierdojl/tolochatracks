# Proposal

## Why

Los números y gráficos no dicen por dónde se pasó. MyTracks destacaba por ver la ruta
dibujada sobre un mapa. TolochaTracks debe mostrar la traza durante la grabación y en el
detalle, usando mapas libres y sin convertir el mapa en un requisito para grabar.

## What Changes

- Widget de mapa compartido con `flutter_map` y teselas de OpenStreetMap, atribución
  visible y `userAgentPackageName` propio.
- Mapa en la pantalla de grabación cuando hay posiciones, siguiendo el último punto.
- Mapa en el detalle con la ruta completa, marcadores de inicio y fin, y encuadre
  automático de la traza.
- Comportamiento sin conexión: el mapa puede quedarse sin teselas, pero la polilínea, la
  grabación y las estadísticas siguen funcionando; se muestra un aviso discreto.
- Estados para rutas sin puntos y atribución enlazada a OpenStreetMap.

## Capabilities

### New Capabilities

- `mapas-ruta`: visualización de una ruta sobre teselas libres, con atribución,
  encuadre y funcionamiento degradado sin red.

### Modified Capabilities

- `grabacion-rutas`: la pantalla de grabación muestra un mapa con la traza y el punto
  actual cuando hay posiciones.
- `historial-sesiones`: el detalle incorpora el mapa de la ruta.

## Impact

- Código: `lib/features/sesiones/ui/widgets/mapa_ruta.dart`, pantallas de grabación y
  detalle.
- Dependencias existentes `flutter_map`, `latlong2` y `url_launcher`; sin permisos nuevos
  (INTERNET ya está).
- Red: solo teselas del proveedor libre; no se envían puntos ni datos de la ruta.
- Los tests de widgets no dependerán de la red.

## Fuera de alcance

- Descarga de mapas para uso sin conexión.
- Proveedores de pago, mapas vectoriales o estilos personalizados.
- Edición de la ruta sobre el mapa.
- Selección de proveedor desde Ajustes (se hará en el change de configuración).
