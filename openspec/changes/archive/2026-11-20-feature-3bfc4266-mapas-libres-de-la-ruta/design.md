# Design

## Context

`flutter_map` y `latlong2` ya están en el proyecto. La app es Android-only y usa
OpenStreetMap como proveedor libre por defecto. La ruta se dibuja a partir de los puntos
ya cargados; no se consulta ningún servicio de rutas.

## Goals / Non-Goals

**Goals:**

- Mapa legible de la traza en grabación y detalle.
- Atribución correcta y peticiones identificadas.
- La app sigue funcionando sin red o sin teselas.

**Non-Goals:**

- Mapas offline, estilos vectoriales o selección de proveedor (change de configuración).
- Edición de puntos.

## Decisions

- **Widget único** `MapaRuta` con `FlutterMap`, `TileLayer` de
  `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, `userAgentPackageName` y
  `PolylineLayer`/`MarkerLayer`. Recibe `puntos`, `seguir` y una altura; no conoce el
  repositorio.
- **Encuadre**: al estar listo el mapa, si hay dos o más puntos se usa
  `fitCamera(CameraFit.bounds(LatLngBounds.fromPoints(...)))`; con uno se centra con
  zoom 16. En grabación, si `seguir` está activo, `didUpdateWidget` mueve el mapa al
  último punto con `MapController.move(..., 16)`.
- **Marcadores**: inicio (círculo verde), fin (pin ocre) y punto actual durante la
  grabación. En el detalle solo inicio y fin; si solo hay un punto se muestra ese.
- **Atribución**: overlay inferior con «© OpenStreetMap contributors», fondo semitransparente
  y enlace a `openstreetmap.org/copyright` con `url_launcher`. Se añade también un aviso
  «Las teselas necesitan conexión» discreto.
- **Sin conexión**: no se bloquea el mapa; si las teselas fallan, la polilínea y el resto
  siguen. No se usa caché de teselas en esta versión.
- **Rendimiento**: la polilínea usa los puntos ya filtrados de la sesión; en grabación se
  reconstruye con cada punto (frecuencia baja, 2 s) y no hay animaciones costosas. El mapa
  no se muestra si no hay ningún punto.
- **Tests**: widget de estado sin puntos (no toca red) y de atribución; los tests de
  detalle usan una ruta y no esperan a que carguen teselas (`pump` acotado).

## Risks / Trade-offs

- **Dependencia de teselas**: OSM puede limitar o bloquear tráfico si se abusa; se respeta
  la política (user agent, sin descarga masiva, atribución). Un proveedor alternativo se
  añadirá en configuración.
- **Red en tests**: cargar imágenes en tests puede dejar timers; se evita `pumpAndSettle`
  indefinido y se prueba el estado vacío/atribución.
- **Mapa en grabación**: consume batería y datos; es opcional en el change de
  configuración («sin mapas»).
