# Arquitectura

TolochaTracks es una app Android en Flutter y Dart estricto. Esta página resume las
decisiones que necesita conocer quien vaya a tocar el código; la constitución completa
sigue en [`AGENTS.md`](../AGENTS.md).

## Capas

| Capa | Responsabilidad |
|---|---|
| `lib/app/` | Arranque, tema centralizado, shell, menú lateral y selección de sección. |
| `lib/core/` | Modelos inmutables, cálculos puros, repositorios, servicios de plataforma, exportación y widgets compartidos. |
| `lib/features/<feature>/data/` | Repositorios específicos del feature. |
| `lib/features/<feature>/ui/` | Pantallas, controladores y widgets de presentación. |

La regla principal es que **los widgets no contienen lógica de negocio**. Las pantallas
observan controladores (`provider`), y los controladores llaman a repositorios, servicios
o funciones puras.

## Estado y navegación

- `provider` gestiona el estado con `ChangeNotifier`.
- `ShellPantalla` mantiene la sección activa y conserva las pantallas ya visitadas con un
  `IndexedStack`.
- Los controladores principales son `GrabacionController`, `HistorialController`,
  `ConfiguracionController`, `ExportacionController` y `CompartirController`.
- `lib/main.dart` construye las dependencias reales y las inyecta en la app.
- Los tests construyen los mismos controladores con fakes, sin plugins.

## Modelo de sesión

Una sesión (`Sesion`) representa una ruta terminada o un borrador:

- `id` único y seguro para usarlo como nombre de archivo.
- `actividad`: correr, caminar, senderismo, bicicleta u otras.
- `inicio`, `fin` y `duracionActiva` (esta última excluye las pausas).
- Lista inmutable de `PuntoRuta` con latitud, longitud, tiempo, altitud, precisión,
  velocidad, rumbo y segmento.
- `exportada`: marca si GPX y JSON se exportaron correctamente.
- `formato`: versión del esquema JSON; la actual es `3`.

Las distancias internas se guardan en metros, los tiempos en segundos y las velocidades
en m/s. El formato a km, ritmo o km/h se hace en la capa de UI.

El parseo es tolerante: una sesión antigua, un punto inválido o un archivo corrupto no
deben tumbar la app. Los puntos inválidos se descartan y los formatos anteriores se
normalizan (por ejemplo, infiriendo segmentos en huecos largos).

## Persistencia

- Cada sesión se guarda como un archivo JSON en el directorio de documentos de la app,
  dentro de `sesiones/`.
- La escritura es atómica: se escribe un `.tmp`, se borra el destino anterior si existe y
  se renombra.
- El borrador de la ruta activa vive en `sesiones/borrador.json` y se autoguarda cada
  pocos segundos durante la grabación.
- Al arrancar, `GrabacionController.inicializar()` carga el borrador; si existe, la app
  ofrece recuperarlo o descartarlo.
- Los ajustes se guardan en `shared_preferences`, no en los JSON de sesión.
- La app no tiene cuentas, backend ni telemetría.

## Grabación

1. Al pulsar «Empezar» se piden las notificaciones (Android 13+) y el permiso de
   ubicación. El permiso se solicita solo en ese momento.
2. Se abre un flujo de `geolocator` con el perfil GPS elegido (Ahorro, Equilibrada o
   Máxima), que ajusta precisión, intervalo y distancia mínima.
3. Los primeros segundos se usan como calentamiento para descartar posiciones malas.
4. Cada punto pasa por el filtro de precisión y velocidad plausible de la actividad.
5. Al pausar se cierra el tramo, se cancela la suscripción y se libera el wake lock; al
   reanudar se abre un segmento nuevo para no unir la traza con una línea recta.
6. El servicio en primer plano de tipo `location` mantiene la captura con la pantalla
   apagada y ofrece Pausar, Reanudar y Finalizar en la notificación.
7. Al finalizar se guarda la sesión completa y se borra el borrador. Si el guardado falla,
   el borrador se conserva y se informa del error.

No se solicita `ACCESS_BACKGROUND_LOCATION`: el servicio en primer plano es el que mantiene
la grabación. El wake lock se libera al pausar y se recupera al reanudar.

## Cálculos y estadísticas

`lib/core/calculos/` contiene funciones puras y testeables para:

- distancia acumulada y distancia entre puntos (Haversine);
- velocidad media, velocidad máxima y velocidad actual;
- desnivel positivo y negativo;
- ritmo y velocidad según la actividad;
- parciales por distancia o tiempo;
- series para los gráficos de distancia, velocidad y altitud.

La UI solo formatea los resultados. Los tests de cálculos no necesitan Flutter ni
plugins.

## Mapas

- `flutter_map` y `latlong2` dibujan las teselas y la traza.
- Los proveedores están en `ProveedorMapas`: OpenStreetMap, OpenTopoMap, CyclOSM y
  «Sin mapas».
- La atribución es obligatoria y visible en el mapa y en «Acerca de».
- El mapa es una capa opcional: si no hay red o el proveedor falla, la grabación, el
  historial, las estadísticas y la exportación siguen funcionando.
- La app no descarga mapas en bloque ni envía la ruta a ningún servidor.

## Exportación

La exportación convierte una sesión en GPX 1.1 y JSON y los escribe en la carpeta elegida
con el selector SAF de Android. El canal nativo está en `MainActivity` y el contrato en
`lib/core/servicios/exportacion.dart`. Los detalles de formato y errores están en
[`exportacion.md`](exportacion.md).

## Servicios inyectables

Para poder probar sin plugins, los servicios de plataforma se inyectan:

- `ServicioUbicacion` (geolocator, permisos y notificaciones).
- `ServicioExportacion` (selector SAF y escritura/borrado).
- `ServicioCompartir` (share sheet).
- `ServicioNotificacionRuta` (acciones de la notificación).
- `ServicioBateria` (exención de optimización).

Los fakes viven en `test/apoyo/falsos.dart`.

## Tema y estilo

`lib/app/theme/app_theme.dart` centraliza la paleta pine/ochre/moss, la tipografía Inter y
los colores de las rutas. Los widgets no usan colores literales: leen el `ThemeData` o la
extensión `ColoresRuta`. El tema sigue el sistema por defecto y se puede forzar claro u
oscuro desde Ajustes.

## Decisiones que no se cambian sin un change

- Solo Android/APK; sin escritorio, iOS, web ni Docker.
- Privacidad primero: las rutas no salen del dispositivo salvo exportación o uso explícito
  de compartir.
- Sin cuentas, telemetría ni backend.
- Los mapas son opcionales y siempre con atribución.
- La grabación en segundo plano usa el servicio en primer plano propio.
