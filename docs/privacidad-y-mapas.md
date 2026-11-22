# Privacidad, permisos y mapas

TolochaTracks está pensada para que las rutas se queden en el móvil. No hay cuentas,
telemetría, analítica ni servidores propios.

## Dónde se guardan los datos

- Las sesiones se guardan en el almacenamiento privado de la app, una por archivo JSON en
  `sesiones/`.
- El borrador de la ruta activa se guarda en `sesiones/borrador.json` para poder
  recuperarlo si el proceso muere.
- Los ajustes (tema, mapa, perfil GPS, parciales y carpeta de exportación) se guardan en
  `shared_preferences`.
- La base de datos, los archivos y los ajustes desaparecen al desinstalar la app. La app
  no tiene copia en la nube.
- La exportación GPX/JSON y el share sheet son acciones explícitas del usuario; a partir de
  ahí el archivo sale del control de la app.

## Permisos Android

| Permiso | Para qué |
|---|---|
| `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` | Grabar la traza GPS. |
| `FOREGROUND_SERVICE` y `FOREGROUND_SERVICE_LOCATION` | Mantener la grabación con la pantalla apagada. |
| `POST_NOTIFICATIONS` | Mostrar la notificación del servicio en Android 13+. |
| `WAKE_LOCK` | Evitar que el dispositivo duerma durante la grabación. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Pedir la exención de batería desde Ajustes. |
| `INTERNET` | Descargar las teselas del mapa elegido. |

No se solicita `ACCESS_BACKGROUND_LOCATION`. El servicio en primer plano de tipo
`location` es el que mantiene la captura; el permiso de ubicación se pide solo al iniciar
la primera grabación. Si se deniega, la app lo explica y ofrece abrir los ajustes.

La app no pide ubicación en segundo plano ni funciona como servicio permanente: al
finalizar o descartar la ruta, el servicio se detiene.

## Batería y segundo plano

- La notificación persistente permite pausar, reanudar y finalizar sin abrir la app.
- El wake lock se libera al pausar y se recupera al reanudar.
- En Ajustes se puede pedir a Android que no optimice la batería de la app. Mejora la
  fiabilidad con la pantalla apagada a cambio de un consumo mayor.
- En fabricantes que cierran apps en segundo plano (Xiaomi, Huawei, Samsung y similares)
  también conviene permitir el inicio automático en los ajustes del sistema.
- No se promete que la grabación continúe tras reiniciar el teléfono. Si el proceso muere,
  el borrador queda disponible para recuperarlo al volver.

## Mapas

Los mapas son opcionales. Se elige el proveedor en Ajustes:

| Proveedor | Teselas | Atribución |
|---|---|---|
| OpenStreetMap | `tile.openstreetmap.org` | © OpenStreetMap contributors (ODbL) |
| OpenTopoMap | `{a,b,c}.tile.opentopomap.org` | © OpenTopoMap · © OpenStreetMap contributors |
| CyclOSM | `{a,b,c}.tile-cyclosm.openstreetmap.fr` | © CyclOSM · © OpenStreetMap contributors |
| Sin mapas | Ninguna petición | Mapas desactivados |

Las teselas se piden solo para la zona visible mientras hay un mapa en pantalla. No se
descargan mapas en bloque ni se envía la ruta al proveedor. Las peticiones se identifican
con el paquete `com.izquierdojl.tolochatracks`.

La atribución es visible en el propio mapa y en «Acerca de», con enlace a la página de
licencia de cada proveedor. Los datos de OpenStreetMap están bajo ODbL; OpenTopoMap y
CyclOSM se atribuyen igualmente.

## Funcionar sin conexión y sin mapas

La app debe seguir siendo útil sin red:

- grabar, pausar, reanudar y finalizar;
- consultar el historial y el detalle;
- ver estadísticas, gráficos y parciales;
- exportar GPX/JSON.

Si no hay teselas, el mapa aparece vacío o se muestra «Sin mapas»; ninguna de las rutas
de código debe fallar por ello. Los mapas requieren conexión y la app lo avisa.

## Compartir

Compartir una ruta genera un GPX temporal en la caché de la app y lo entrega al share
sheet de Android mediante `FileProvider`. La app no envía nada por su cuenta: la persona
usuaria elige la app de destino. Los GPX temporales de más de un día se limpian al volver
a compartir.

## Dependencias y licencias

El código de TolochaTracks se distribuye bajo licencia MIT (ver
[`LICENSE`](../LICENSE)). Los datos de mapas mantienen su licencia ODbL y la tipografía
Inter usa SIL Open Font License 1.1. Las licencias de las dependencias no cambian por usar
este proyecto.
