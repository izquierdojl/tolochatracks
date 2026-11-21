# Design

## Context

La app ya genera GPX 1.1 puro con `gpxDeSesion` y nombres seguros con `nombreGpx`, y usa
`path_provider` para sus archivos internos. `MainActivity` ya concentra los canales de
exportación, permisos, batería y servicio de ruta, así que añadir un canal de compartir
sigue el mismo patrón y no requiere dependencias nuevas. Ver `proposal.md` para la
motivación y `specs/compartir-rutas/spec.md` para el comportamiento exigido.

## Goals / Non-Goals

**Goals:**

- Compartir una sesión concreta como GPX por el selector de Android desde el detalle y
  desde el historial.
- Mantener la ruta en el dispositivo hasta que el usuario elija el destino.
- Funcionar sin conexión y sin carpeta de exportación.
- Poder testear la lógica con un fake del servicio, sin plugins.

**Non-Goals:**

- Compartir JSON, texto o enlaces; varias rutas a la vez; importar GPX.
- Añadir `share_plus` u otra dependencia de plataforma.
- Cambiar el formato de la sesión o el flujo de exportación.

## Decisions

- **Canal propio + `FileProvider` en vez de `share_plus`.** El stack está cerrado y el
  proyecto ya resuelve plataforma con `MethodChannel`. `share_plus` ahorraría código pero
  añade una dependencia y su configuración; `url_launcher` no puede exponer un `file://`
  a otras apps. Se usa `Intent.ACTION_SEND` con un `content://` de `FileProvider` y
  `FLAG_GRANT_READ_URI_PERMISSION`.
- **GPX temporal en la caché.** `ServicioCompartirCanal` escribe
  `getTemporaryDirectory()/compartir/<nombreGpx>` y llama al canal con la ruta, el MIME
  `application/gpx+xml` y un asunto legible. No se escribe en la carpeta de exportación
  ni se conserva una copia permanente. Antes de escribir, elimina GPX temporal antiguos
  para no crecer sin límite; no se borra el archivo justo después de compartir porque la
  app receptora puede leerlo de forma asíncrona.
- **Servicio inyectable y controlador.** `ServicioCompartir` es una interfaz;
  `ServicioCompartirCanal` es la implementación real y `ServicioCompartirFalso` se usa en
  tests. `CompartirController` expone `compartiendo`, `sesionCompartiendoId` y `error`,
  evita duplicados y no marca la sesión como exportada.
- **Dos puntos de entrada.** El `AppBar` del detalle añade un `IconButton` con tooltip
  «Compartir ruta»; cada `_TarjetaSesion` del historial añade una acción de compartir
  fuera del `InkWell` que abre el detalle, para que pulsarla no navegue. Ambas leen el
  controlador del `Provider`, muestran progreso en la sesión activa y presentan el error
  en un `SnackBar`. No se pide carpeta ni se abre el detalle desde la tarjeta.
- **Sin permisos nuevos.** El selector de Android y `FileProvider` no necesitan permisos
  de almacenamiento. El manifiesto solo declara el provider y `file_paths.xml` con
  `cache-path`.
- **Privacidad por diseño.** El GPX solo se genera al pulsar compartir, no hay subida
  propia ni enlaces públicos, y el archivo temporal queda en la caché de la app.

## Risks / Trade-offs

- **Apps receptoras que no aceptan `application/gpx+xml`** → se usa el MIME estándar de
  GPX y el nombre `.gpx`; el selector del sistema muestra las apps compatibles. Si el
  selector no puede abrirse, se captura el fallo y se muestra un mensaje en español. El
  usuario puede seguir exportando a disco.
- **Archivos temporales acumulados** → se limpian los GPX de compartir anteriores antes
  de cada nueva preparación y Android puede vaciar la caché; no se guardan en documentos.
- **Lectura asíncrona del archivo por la app receptora** → no se borra el temporal al
  volver del selector; se deja en caché y se limpia en una preparación posterior.
- **Privacidad** → compartir siempre exige una pulsación explícita y la elección de una
  app; no hay envío automático ni telemetría.
- **Tres acciones en el `AppBar` del detalle** → el título puede truncarse en pantallas
  estrechas; se mantiene porque las acciones son iconos compactos y con tooltip.
