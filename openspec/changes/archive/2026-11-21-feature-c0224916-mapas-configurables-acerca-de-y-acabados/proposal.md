# Proposal

## Why

La app ya graba, consulta y exporta, pero el mapa está fijado a OpenStreetMap y no hay una
pantalla que explique versión, privacidad y licencias. Además, en Android 13+ falta pedir
el permiso de notificaciones que hace visible el servicio de grabación. Este change cierra
esas carencias para que la app sea usable y publicable como APK.

## What Changes

- Selector de proveedor de mapas libres en Ajustes: OpenStreetMap, OpenTopoMap, CyclOSM o
  sin mapas. La elección se persiste y el mapa y su atribución cambian en consecuencia.
- Estado «mapas desactivados» en grabación y detalle, sin peticiones de teselas.
- Permiso de notificaciones POST_NOTIFICATIONS en Android 13+ al iniciar la primera
  grabación, para que la notificación del servicio en primer plano sea visible.
- Notificación de grabación propia con acciones Pausar/Reanudar y Finalizar, conectada al
  controlador, para controlar la ruta sin abrir la app.
- Ajuste de batería: exención de la optimización del sistema y wake lock del servicio,
  con aviso de fiabilidad y consumo.
- Pantalla «Acerca de» con versión, privacidad, atribuciones de mapas, licencia del código
  y enlace al repositorio.
- Acabados: README completo (funciones, privacidad, mapas, exportación), documentación de
  la gobernanza y hoja de ruta actualizada.

## Capabilities

### New Capabilities

- `acerca-de`: información de versión, privacidad, atribuciones y proyecto.

### Modified Capabilities

- `mapas-ruta`: el proveedor de teselas es configurable y puede desactivarse.
- `configuracion`: Ajustes incluye el proveedor de mapas y el acceso a Acerca de.
- `grabacion-rutas`: se solicita el permiso de notificaciones para el servicio en primer
  plano.

## Impact

- Código: `lib/core/models/proveedor_mapas.dart`, `MapaRuta`, Ajustes, Acerca de,
  `MainActivity` (canal de permisos) y `ServicioUbicacion`.
- Dependencia nueva: `package_info_plus` para la versión.
- Android: permiso POST_NOTIFICATIONS ya declarado; se pide en tiempo de ejecución.
- Sin cambios en el formato de sesiones ni en la exportación.

## Fuera de alcance

- Mapas offline o estilos vectoriales.
- Traducciones a otros idiomas.
- Play Store, iOS o escritorio.
- Cambios de licencia del código (se documenta la situación actual).
