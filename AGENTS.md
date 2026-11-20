# AGENTS.md — TolochaTracks

Constitución del proyecto. Estas reglas gobiernan todo el desarrollo de este repositorio
y **prevalecen sobre costumbres externas**. Si una instrucción puntual contradice este
documento, se detiene y se consulta al usuario.

## 1. Proyecto

TolochaTracks es una app Android, en Flutter/Dart, para registrar rutas GPS de forma
rápida y sencilla: correr, caminar, senderismo, bicicleta y otras actividades. Guarda las
sesiones internamente, permite exportarlas a un directorio elegido por el usuario (GPX y
JSON), muestra la ruta sobre mapas libres y resume las estadísticas habituales con
gráficos. La referencia de producto es la antigua app MyTracks de Google: abrir, pulsar
grabar y olvidarse del móvil.

- Idioma de UI, documentación, commits y conversación: **español**.
- Referencia de estilo, estructura y lecciones aprendidas: `izquierdojl/tolochafuel`
  (paleta pine/ochre/moss, tipografía Inter, tema claro y oscuro siguiendo el sistema).
- Versión inicial en `0.x` hasta que la app sea usable; `1.0.0` lo decide el usuario.

## 2. Stack tecnológico

| Capa | Decisión |
|---|---|
| Framework | Flutter estable (versión fijada en CI: 3.47.7). |
| Lenguaje | Dart estricto con `flutter_lints`; `dart format` como formateador. |
| Plataforma | **Solo Android (APK)**. No hay build de escritorio ni iOS/web. |
| Estado | `provider` (suficiente para el alcance; sin gestores complejos). |
| Ubicación | `geolocator` con `LocationAccuracy.high` y `distanceFilter` de 3 m, `LocationManager` de Android (sin depender de Play Services), servicio en primer plano propio de tipo `location` con wake lock y acciones Pausar/Reanudar/Finalizar en la notificación. |
| Mapas | `flutter_map` + `latlong2` con teselas de OpenStreetMap, OpenTopoMap y CyclOSM. Servicio opcional y desactivable. |
| Persistencia | Archivos JSON internos en el directorio de documentos de la app (una sesión por archivo) con `path_provider`. Ajustes en `shared_preferences`. |
| Exportación | GPX 1.1 y JSON a un directorio elegido con el selector SAF de Android (permiso persistente). |
| Gráficos | `fl_chart`. |
| Fechas y números | `intl` en español. |
| Calidad | `flutter analyze` + `flutter test` + `dart format`; tests de cálculos, repositorio, exportación y widgets clave. |
| Entorno | Linux (Debian Stable, KDE Plasma). Código en `~/soft/tolochatracks`. Flutter, JDK 21 y Android SDK en rutas de usuario. |
| Distribución | GitHub Releases: **solo APK**; Play Store aplazada. **Sin Docker ni backend**. |

Stack cerrado: **no se cambia de framework, librerías base ni gestor de paquetes** sin
decisión explícita del usuario y actualización de este documento.

## 3. Arquitectura

- **Estructura**: `lib/app` (arranque, tema, shell) · `lib/core` (modelos, cálculos,
  servicios, widgets compartidos) · `lib/features/<feature>/` (`data/` repositorio +
  `ui/` pantallas, controladores y widgets).
- **Sin lógica de negocio en widgets**: las pantallas llaman a controladores,
  repositorios o servicios; los cálculos de ruta son funciones puras y testeables.
- **Tema centralizado** en `lib/app/theme` con la paleta de TolochaFuel; nunca colores
  literales en widgets.
- Modelos inmutables con serialización JSON versionada y parseo tolerante (sesiones
  antiguas o archivos corruptos no deben tumbar la app).
- Los servicios de plataforma (ubicación, selector de directorios) se inyectan para poder
  testear sin plugins.
- **Grabación fiable**: la sesión activa se autoguarda en un borrador; al abrir la app se
  ofrece recuperarla si el proceso murió.
- Los mapas son una capa opcional: la grabación, el historial y las estadísticas deben
  funcionar sin conexión y sin teselas.

## 4. Datos, privacidad y mapas

- Las rutas son datos personales: **se quedan en el dispositivo** salvo que el usuario
  exporte una sesión. No hay cuentas, telemetría ni subida a servidores propios.
- Un único punto habla con servicios externos: el proveedor de teselas del mapa elegido.
  La app no descarga mapas en bloque ni hace peticiones en segundo plano.
- Atribución obligatoria y visible en el mapa y en Acerca de: «© OpenStreetMap
  contributors» (ODbL) y el proveedor de teselas correspondiente. OpenTopoMap y CyclOSM
  se atribuyen igualmente.
- La app avisa de que los mapas necesitan conexión y de que el GPS consume batería.

## 5. Plataformas y permisos

- **Android** es la única plataforma. Permisos: ubicación precisa (`ACCESS_FINE_LOCATION`
  y `ACCESS_COARSE_LOCATION`), servicio en primer plano de ubicación
  (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`), notificaciones
  (`POST_NOTIFICATIONS`), `WAKE_LOCK` para el servicio en primer plano, exención de
  optimización de batería (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, solo para pedirla desde
  Ajustes) e INTERNET para las teselas. Nada más. No se pide ubicación en segundo plano:
  el servicio en primer plano de tipo `location` mantiene la captura.
- El permiso de ubicación se pide **solo al iniciar la primera grabación**; si se deniega,
  se explica en español y se ofrece abrir los ajustes.
- La grabación usa un servicio en primer plano con notificación persistente; no se
  promete funcionamiento tras reiniciar el teléfono.
- `targetSdk` y `minSdk` siguen los valores de Flutter (mínimo 23).

## 6. Reglas de código

- Dart estricto; errores de análisis = tarea no terminada.
- Commits **convencionales** en español (`feat:`, `fix:`, `docs:`, `infra:`, `refactor:`,
  `test:`, `chore:`; `BREAKING CHANGE` o `!` para major). Commitlint en CI.
- Antes de dar una tarea por terminada: `flutter analyze && flutter test` en verde (y
  `dart format` aplicado). El comando único es `npm run verify`.
- **Nunca** se commitean secretos: keystores y tokens viven en GitHub Secrets o fuera del
  repo; existe `.gitignore` para artefactos de build.
- Textos de UI, documentación y mensajes de error para el usuario: español.
- Sin comentarios en el código salvo que se pidan explícitamente.
- Las cantidades se guardan en unidades del SI (metros, segundos, m/s) y se formatean en
  la capa de UI (km, ritmo min/km, km/h).

## 7. Flujo de trabajo OpenSpec

- Toda funcionalidad empieza como change en `openspec/changes/` creado con
  `scripts/new_change.sh <tipo> "<título>" [rama]`. El flujo de `/opsx-propose` lo hace
  él mismo: pregunta tipo, título y rama si faltan (al inicio o tras explorar) y ejecuta
  el script; no hace falta correrlo antes de proponer.
- **Tipos** (clasificación del change): `feature | bug | docs | infra | refactor | test | chore`.
- **Nombre del change**: `<tipo>-<id8>-<slug>`, p. ej. `feature-a3f9c21b-alta-empresas`.
  El `id8` son 8 hex únicos estilo git, generados por `scripts/spec_id.py`.
- **Metadata obligatoria** en `meta.yaml` dentro del change: `tipo`, `id`, `titulo`,
  `autor` (git user), `fecha` (ISO 8601 con zona horaria), `branch`. La valida
  `scripts/check_changes.sh` (se ejecuta en CI).
- **Ramas**: `main` = producción; `dev` = integración y **destino de todos los PR**.
  Cada change declara `branch: dev` (trabajo directo sobre `dev`) o `branch: feature`
  (rama `feature/<tipo>-<id8>-<slug>` con PR a `dev`). El usuario lo define por change;
  el defecto es `dev` y se configura en `scripts/new_change.sh` (`DEFAULT_BRANCH`).
  Cada fusión en `dev` dispara versión y release APK (§8).
- Archivar un change = commitear TODO (código + specs) en la rama de trabajo antes del
  merge. Verificar con `git status` que no queda nada sin commitear.
- **Sincronizar `todowrite` con el plan**: el panel lateral "Todo" solo refleja la
  herramienta `todowrite` y no se actualiza solo. Al aplicar un change, inicializar
  `todowrite` con las tareas del `tasks.md` y actualizarla tras completar cada tarea
  (mismo estado que el checkbox `- [ ]` → `- [x]`; la tarea en curso como
  `in_progress`). Nunca dejar la lista en el estado de llamadas anteriores.
- Los cambios pequeños se archivan pronto: un change = una capacidad.

## 8. Versionado y releases

- Formato semver `X.Y.Z` (+ número de build `+N` en `pubspec.yaml`). **Automático con
  cada PR fusionado en `dev`**:
  - `feat` o tipo `feature` → **minor**; `fix`/`bug` → **patch**; `BREAKING CHANGE`/`!` → **major**.
  - `infra`/`docs`/`refactor`/`test`/`chore` → **patch** salvo `BREAKING`.
- Flujo: merge a `dev` → `version.yml` espera la CI verde del commit → analiza commits
  desde el último tag → `node scripts/bump.js <bump>` (sincroniza `pubspec.yaml` +
  `package.json`, commit `chore(release): vX.Y.Z`, tag `vX.Y.Z`) → `release.yml` construye
  y publica el **APK** en GitHub Releases.
- Los assets usan nombres estables para permitir enlaces de descarga directa:
  `https://github.com/izquierdojl/tolochatracks/releases/latest/download/tolochatracks.apk`.
- `main` es la rama de producción y se actualiza con un PR `dev → main` cuando se quiera
  congelar una versión; los releases salen de `dev` según lo acordado.
- Los skills de OpenSpec se regeneran con `openspec update`: **las reglas de release y la
  configuración personalizada viven aquí y en `openspec/config.yaml`**, y se re-aplican
  si un update las altera. `scripts/check_openspec_config.sh` falla en CI si se pierde la
  configuración personalizada (marcador `tolochatracks:config-personalizada`).

## 9. CI/CD y distribución

- `ci.yml`: `check_changes.sh` + `check_openspec_config.sh` + `dart format` +
  `flutter analyze` + `flutter test` + commitlint en PRs, y build APK de comprobación.
  Corre en PRs a `dev`/`main` y en push a `dev` (no en push a `main`).
- `version.yml` (push a `dev`) → comprueba que la CI de la punta de `dev` está en verde →
  bump + tag + llama a `release.yml`. Sin CI verde no hay tag ni release.
- `release.yml`: job Android (`flutter build apk --release`) y publicador de GitHub
  Releases. El APK se firma con el keystore de release, materializado desde los secretos
  `ANDROID_KEYSTORE_*` (nunca en el repo; copia de seguridad local en
  `~/keystores/tolochatracks/`), de modo que las actualizaciones se instalan encima sin
  desinstalar.
- **Sin Docker**: la app no tiene servidor.

## 10. Entorno de desarrollo

- **Linux (Debian Stable) con KDE Plasma**. Código en `~/soft/tolochatracks`.
- SDKs en rutas de usuario: Flutter (`~/flutter`), JDK 21 y Android SDK (`~/Android/Sdk`).
- Comandos habituales: `flutter pub get`, `flutter run -d <dispositivo>`,
  `flutter analyze`, `flutter test`, `dart format .`, `bash scripts/check_changes.sh`,
  `npm run verify` y `npm run release:patch|minor|major` (manual y excepcional).
- Emulador Android local (AVD `Medium_Phone_API_37.0`) y `adb` en
  `~/Android/Sdk/platform-tools`; dispositivos físicos por USB con `adb`.

## 11. Advisories (acuerdos que no se renegocian)

1. Solo Android/APK: nada de escritorio, iOS, web ni Docker.
2. Privacidad primero: las rutas no salen del dispositivo salvo exportación manual; sin
   cuentas, sin telemetría, sin backend.
3. Mapas libres opcionales con atribución; la app debe seguir siendo útil sin conexión.
4. Un change = una capacidad; changes pequeños y archivados pronto.
5. La gobernanza (`scripts/`, `AGENTS.md`, `openspec/config.yaml`) prevalece sobre los
   skills regenerados por `openspec update`; si un update pisa una regla, se re-aplica.
6. Versión `0.x` hasta que el usuario decida `1.0.0`.
7. La configuración personalizada de OpenSpec no puede perderse: el marcador y el script
   de comprobación son parte de la CI.
8. La grabación en segundo plano usa un foreground service propio de tipo `location` y
   wake lock; no se pide `ACCESS_BACKGROUND_LOCATION`. Ajustes ofrece la exención de
   batería; los fabricantes agresivos pueden requerir además permitir el inicio automático.
9. Flutter se actualiza solo con un change `infra` que fije la nueva versión en CI y en
   el SDK local, ejecute `npm run verify` y compile el APK. Los avisos de `pub` sobre
   dependencias transitivas no justifican cambiar el SDK: se revisan con
   `flutter pub outdated` y se actualizan solo las que permitan las restricciones.

## 12. Estado y siguientes pasos

Capacidades entregadas: grabación GPS con borrador, historial y detalle, estadísticas con
gráficos y parciales, mapas libres configurables, exportación GPX/JSON, tema y ajustes,
Acerca de, CI/CD y releases APK.

Siguientes pasos posibles (cada uno como change nuevo): importar GPX, compartir con el
share sheet, mapas offline, pausa automática, solicitud de ubicación en segundo plano si
un dispositivo concreto la exige, y publicación en Play Store si el usuario lo decide.
