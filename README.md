# TolochaTracks

App Android (Flutter) para registrar rutas GPS de forma rápida y sencilla: correr,
caminar, senderismo, bicicleta y otras actividades. Guarda las sesiones en el
dispositivo, permite exportarlas a GPX/JSON y resume la ruta con estadísticas, gráficos y
mapas libres opcionales. La referencia de producto es la antigua app MyTracks de Google:
abrir, pulsar grabar y olvidarse del móvil.

## Estado

En desarrollo (versión `0.x`). Se publica **solo APK** en GitHub Releases.

## Instalación

Descarga el APK desde la última release:

<https://github.com/izquierdojl/tolochatracks/releases/latest/download/tolochatracks.apk>

Al ser un APK fuera de Play Store, Android pedirá permitir la instalación desde el
navegador o el gestor de archivos. Las actualizaciones se instalan encima sin
desinstalar (misma firma de release).

## Privacidad

Las rutas se guardan únicamente en el dispositivo. No hay cuentas, telemetría ni
servidores propios. Solo se accede a la red para descargar las teselas del mapa elegido,
y los mapas se pueden desactivar en Ajustes.

## Mapas y atribución

Los mapas son opcionales y utilizan servicios libres:

- [OpenStreetMap](https://www.openstreetmap.org/copyright) — © OpenStreetMap contributors
  (ODbL).
- [OpenTopoMap](https://opentopomap.org) — © OpenTopoMap contributors, datos de
  OpenStreetMap (ODbL) y SRTM.
- [CyclOSM](https://www.cyclosm.org) — © CyclOSM contributors, datos de OpenStreetMap
  (ODbL).

No se descargan mapas en bloque ni se accede a la ubicación en segundo plano sin una
grabación activa.

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
