# TolochaTracks

[![CI](https://github.com/izquierdojl/tolochatracks/actions/workflows/ci.yml/badge.svg)](https://github.com/izquierdojl/tolochatracks/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/izquierdojl/tolochatracks)](https://github.com/izquierdojl/tolochatracks/releases)

App Android (Flutter) para registrar rutas GPS de forma rápida y sencilla: correr,
caminar, senderismo, bicicleta y otras actividades. Graba con la pantalla apagada, guarda
las sesiones en el dispositivo, las muestra sobre mapas libres, calcula estadísticas y
permite exportarlas a GPX/JSON. La referencia de producto es la antigua app MyTracks de
Google: abrir, pulsar grabar y olvidarse del móvil.

## Estado

En desarrollo (versión `0.x`). Se publica **solo APK** en GitHub Releases.

## Funciones

- **Grabación GPS**: actividades, inicio con un toque, pausa/reanudación, estadísticas en
  vivo y servicio en primer plano para seguir con la pantalla apagada. La notificación
  permite Pausar/Reanudar y Finalizar sin abrir la app.
- **Borrador recuperable**: si la app se interrumpe, ofrece recuperar la sesión al volver.
- **Historial**: rutas ordenadas por fecha, filtro por actividad y totales de distancia y
  tiempo.
- **Detalle**: distancia, duración, ritmo/velocidad, desnivel, altitudes, velocidad
  máxima, gráficos de distancia, velocidad, altitud y metros por minuto, y parciales por
  kilómetro.
- **Mapas libres**: OpenStreetMap, OpenTopoMap, CyclOSM o sin mapas. Atribución visible y
  aviso de que las teselas necesitan conexión.
- **Exportación**: GPX 1.1 y JSON a la carpeta que elijas con el selector de Android; una
  ruta o todo el historial visible.
- **Ajustes**: tema sistema/claro/oscuro, proveedor de mapas, carpeta de exportación y
  exención de optimización de batería. Todo se guarda en el dispositivo.

## Instalación

Descarga el APK desde la última release:

<https://github.com/izquierdojl/tolochatracks/releases/latest/download/tolochatracks.apk>

Al ser un APK fuera de Play Store, Android pedirá permitir la instalación desde el
navegador o el gestor de archivos. Las actualizaciones se instalan encima sin
desinstalar (misma firma de release).

## Privacidad

Las rutas se guardan únicamente en el dispositivo. No hay cuentas, telemetría ni
servidores propios. La única red son las teselas del mapa libre elegido; puedes elegir
«Sin mapas» y la grabación, el historial, las estadísticas y la exportación siguen
funcionando. La exportación escribe solo en la carpeta que concedas con el selector del
sistema.

## Batería y segundo plano

La grabación usa un servicio en primer plano de tipo `location`, una notificación
persistente con acciones y un wake lock parcial mientras dura la ruta. En Ajustes puedes
permitir que Android no optimice la batería de la app; mejora la fiabilidad con la
pantalla apagada a cambio de un consumo mayor. En fabricantes que cierran apps en segundo
plano (Xiaomi, Huawei, Samsung…) también conviene permitir el inicio automático en los
ajustes del sistema.

No se solicita el permiso de ubicación en segundo plano: el servicio en primer plano es
el que mantiene la captura. Se pide el permiso de notificaciones en Android 13+ para que
la notificación sea visible.

## Mapas y atribución

Los mapas son opcionales y utilizan servicios libres:

- [OpenStreetMap](https://www.openstreetmap.org/copyright) — © OpenStreetMap contributors
  (ODbL).
- [OpenTopoMap](https://opentopomap.org/about) — © OpenTopoMap contributors, datos de
  OpenStreetMap (ODbL) y SRTM.
- [CyclOSM](https://www.cyclosm.org) — © CyclOSM contributors, datos de OpenStreetMap
  (ODbL).

No se descargan mapas en bloque ni se envía la ruta a ningún servidor. Las peticiones de
teselas se identifican con el paquete `com.izquierdojl.tolochatracks`.

## Exportación

En Ajustes elige una carpeta (por ejemplo `Download/TolochaTracks`). Después puedes
exportar desde el detalle de una ruta o con «Exportar todo» en el historial. Cada sesión
genera:

- `tolochatracks_AAAAMMDD_HHmm_actividad_id.gpx` — GPX 1.1 con metadatos y puntos.
- `tolochatracks_AAAAMMDD_HHmm_actividad_id.json` — copia completa de la sesión.

Si un archivo falla, la app informa de los exportados y de los errores sin borrar la
sesión local.

## Desarrollo

Requisitos: Flutter estable (3.47.7 en CI), Dart y Node.js 22+ para la gobernanza.

```bash
flutter pub get
npm install
npm run verify                 # formato, análisis, tests y checks de OpenSpec
flutter run -d <dispositivo>
flutter build apk --release
```

Firma de release: `android/key.properties` + keystore (en local o vía secretos
`ANDROID_KEYSTORE_*` en CI). Nunca se commitean.

## OpenSpec y releases

Todo cambio de comportamiento empieza como change en `openspec/changes/` creado con
`scripts/new_change.sh <tipo> "<título>" [dev|feature]`. La configuración personalizada
vive en `openspec/config.yaml` y está protegida por
`scripts/check_openspec_config.sh`. Ver `AGENTS.md` para la constitución completa.

Cada fusión en `dev` espera la CI del commit, calcula el bump semver según los commits
convencionales y publica un APK firmado en GitHub Releases. `main` es la rama de
producción y se actualiza con un PR `dev → main`.
