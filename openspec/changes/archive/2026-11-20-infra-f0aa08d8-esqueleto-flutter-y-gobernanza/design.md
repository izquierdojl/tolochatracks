# Design

## Context

Proyecto nuevo, sin código previo. La referencia `izquierdojl/tolochafuel` aporta la
paleta, la tipografía Inter, la estructura `lib/app` · `lib/core` · `lib/features`, los
scripts de gobernanza OpenSpec y el pipeline de releases. TolochaTracks cambia el
producto (rutas GPS) y se limita a Android/APK.

## Goals / Non-Goals

**Goals:**

- Arrancar con una base compilable, testeable y publicable en Android.
- Reproducir el look and feel Tolocha (pine/ochre/moss, Inter, tema del sistema).
- Dejar lista la gobernanza OpenSpec sin perder la configuración personalizada.
- Automatizar versión y APK al fusionar en `dev`.

**Non-Goals:**

- Cualquier capacidad de producto (grabación, historial, mapas, estadísticas,
  exportación).
- Multiplataforma, Docker, backend o Play Store.

## Decisions

- **Flutter 3.47.7 / Dart 3.13** fijados en CI; `flutter_lints` y lints estrictos.
- **Solo Android**: `flutter create --platforms=android`; el manifest declara solo los
  permisos necesarios y el build usa `flutter.minSdkVersion`/`targetSdkVersion`.
- **provider** como gestor de estado y **shared_preferences** para ajustes; no se
  introduce un gestor más complejo.
- **Tema** en `lib/app/theme`: semilla ocre, extensiones de tema para colores de ruta
  (evita literales en widgets) y familia Inter empaquetada.
- **Shell** con `NavigationDrawer` e `IndexedStack` perezoso, como TolochaFuel; la
  sección inicial es Grabar.
- **Firma de release**: `android/key.properties` opcional; si existe se firma con el
  keystore, si no se usa la firma debug para desarrollo. En CI los secretos
  `ANDROID_KEYSTORE_*` materializan el keystore y `key.properties`.
- **OpenSpec personalizado**: `openspec/config.yaml` lleva el marcador
  `# tolochatracks:config-personalizada`; `scripts/check_openspec_config.sh` verifica
  en CI que siguen presentes las reglas clave (contexto, release en dev, exportación,
  mapas y creación de changes).
- **Release en dev**: `version.yml` se dispara al hacer push a `dev`, espera la CI del
  commit, calcula el bump por commits convencionales y ejecuta `scripts/bump.js`; luego
  llama a `release.yml`, que publica `tolochatracks.apk`.
- **Assets de marca** generados desde SVG con `sharp-cli` vía `npx`; el SVG es la
  fuente de verdad y los PNG se versionan.

## Risks / Trade-offs

- El primer arranque de CI compila Android por primera vez (Gradle/AGP): puede tardar;
  se cachea Flutter y se acepta el tiempo.
- El versionado en `dev` produce un release por fusión, incluso de docs; es la regla
  acordada por el usuario.
- El pipeline depende de secretos de firma; si faltan, el release falla de forma
  explícita en lugar de publicar un APK mal firmado.
- La configuración OpenSpec podría ser pisada por `openspec update`; el chequeo de CI
  lo detecta y obliga a restaurarla.
