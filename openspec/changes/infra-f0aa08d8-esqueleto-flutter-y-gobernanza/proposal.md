# Proposal

## Why

TolochaTracks necesita una base técnica y de gobernanza antes de implementar la
grabación: proyecto Flutter solo-Android, identidad visual Tolocha, estructura de
código, verificación automatizada y un pipeline que publique APK. Sin esta base, cada
funcionalidad posterior duplicaría decisiones y no habría red de seguridad en CI.

## What Changes

- Proyecto Flutter Android (`com.izquierdojl.tolochatracks`) con Dart estricto y
  dependencias base: `provider`, `geolocator`, `flutter_map`, `latlong2`, `fl_chart`,
  `shared_preferences`, `path_provider`, `intl`, `flutter_svg`, `url_launcher`.
- Tema centralizado pine/ochre/moss con Inter, claro/oscuro/sistema, y shell de
  navegación (Grabar, Historial, Ajustes) con la marca TolochaTracks.
- Configuración Android: permisos de ubicación, servicio en primer plano,
  notificaciones e INTERNET; firma de release opcional desde `key.properties`.
- Gobernanza OpenSpec: scripts `new_change.sh`, `check_changes.sh`, `spec_id.py`,
  `bump.js`, `verificar.sh` y `check_openspec_config.sh`; configuración personalizada
  protegida con marcador.
- CI (calidad + build APK), versionado automático al fusionar en `dev` y release de
  APK firmado en GitHub Releases.
- Marca: emblema SVG, icono legacy/adaptativo generado con `flutter_launcher_icons`,
  tipografía Inter empaquetada.

## Capabilities

### New Capabilities

_(ninguna: es infraestructura; no cambia comportamiento observable del producto)_

### Modified Capabilities

_(ninguna)_

## Impact

- Repo nuevo `izquierdojl/tolochatracks` con ramas `main` y `dev`.
- Código: `lib/app`, `lib/core`, `lib/features` (esqueletos), `android/`.
- Dependencias de build y workflows de GitHub Actions.
- Secretos de firma Android en GitHub (`ANDROID_KEYSTORE_*`), keystore local en
  `~/keystores/tolochatracks/`.

## Fuera de alcance

- Grabación GPS real, almacenamiento de sesiones, mapas, gráficos y exportación
  (tienen sus propios changes).
- Publicación en Play Store, iOS, escritorio o web.
- Cuentas de usuario, backend o sincronización.
