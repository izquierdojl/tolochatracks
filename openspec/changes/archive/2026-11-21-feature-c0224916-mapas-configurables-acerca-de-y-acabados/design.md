# Design

## Context

`MapaRuta` está fijado a OSM. `Configuracion` ya persiste tema y carpeta. El servicio en
primer plano necesita POST_NOTIFICATIONS en Android 13+; el permiso está declarado pero
no se pide. `package_info_plus` permite mostrar la versión real sin duplicarla.

## Goals / Non-Goals

**Goals:**

- Proveedor de mapas configurable y desactivable, con atribución correcta.
- Pedir notificaciones al empezar a grabar sin romper si se deniega.
- Acerca de completo y documentación de proyecto.

**Non-Goals:**

- Mapas offline, vectoriales o de pago.

## Decisions

- **`ProveedorMapas`** enum puro con etiqueta, plantilla de URL, subdominios, atribución,
  URL de licencia y zoom nativo. OSM, OpenTopoMap, CyclOSM y `ninguno`. Se guarda la clave
  en `shared_preferences`; valor por defecto OSM.
- **`MapaRuta`** recibe `ProveedorMapas` (o lo lee del `ConfiguracionController` en la
  pantalla) y usa `TileLayer` con la plantilla y subdominios elegidos. Si es `ninguno`,
  muestra el aviso «Mapas desactivados» sin construir `TileLayer`. La atribución se toma
  del proveedor y enlaza a su licencia.
- **Notificaciones**: se añade un canal nativo
  `com.izquierdojl.tolochatracks/permisos` con `pedirNotificaciones`, que solicita
  POST_NOTIFICATIONS en API 33+ y espera la respuesta. `ServicioUbicacion` expone
  `prepararNotificaciones()`; `GrabacionController` la llama antes del permiso de
  ubicación y muestra un aviso si se deniega.
- **Servicio de notificación propio**: `RutaForegroundService` (tipo `location`) sustituye
  a la notificación estática de geolocator. Muestra Pausar/Reanudar y Finalizar como
  `PendingIntent` al propio servicio; las acciones se envían al isolate principal por
  `CanalRuta` y un `MethodChannel`. `GrabacionController` inicia/actualiza/detiene el
  servicio y el `main` conecta las acciones: pausar, reanudar y finalizar (guardando y
  refrescando el historial). Si el proceso muere, el borrador sigue siendo la red de
  seguridad. La notificación abre la app al tocarla.
- **Acerca de**: `package_info_plus` para versión; enlaces con `url_launcher`; atribuciones
  desde los `ProveedorMapas`; licencia Inter OFL y código público.
- **UI de Ajustes**: nueva sección Mapas con un `DropdownButtonFormField<ProveedorMapas>`
  y atribución; sección Acerca de con `ListTile`.
- **Batería**: el servicio usa `PARTIAL_WAKE_LOCK` con timeout de 12 h y se apoya en un
  `foregroundServiceType="location"`. Ajustes consulta
  `PowerManager.isIgnoringBatteryOptimizations` y lanza
  `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`; el estado se refresca al volver del
  sistema. El GPS usa `LocationAccuracy.high` y `distanceFilter: 3` para un equilibrio
  razonable. Se documenta que fabricantes agresivos pueden requerir permitir el inicio
  automático.
- **Documentación**: README con funcionalidades, instalación, privacidad, mapas,
  exportación y desarrollo; AGENTS actualiza la hoja de ruta y deja constancia de las
  decisiones.

## Risks / Trade-offs

- **Dependencia `package_info_plus`**: plugin pequeño y estándar; se justifica para no
  duplicar la versión.
- **Proveedores con menos disponibilidad**: OpenTopoMap/CyclOSM pueden ir más lentos; el
  usuario puede volver a OSM o desactivar mapas.
- **Permiso de notificaciones**: si se deniega, el servicio sigue; se informa sin bloquear.
