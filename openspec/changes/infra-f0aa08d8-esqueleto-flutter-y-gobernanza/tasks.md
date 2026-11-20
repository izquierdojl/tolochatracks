# Tasks

## 1. Proyecto y dependencias

- [x] 1.1 Crear el proyecto Flutter solo-Android `com.izquierdojl.tolochatracks`
- [x] 1.2 Añadir dependencias base y `flutter_launcher_icons` a `pubspec.yaml`
- [x] 1.3 Configurar Android: permisos, etiqueta, firma opcional y canal SAF en Kotlin
- [x] 1.4 Empaquetar Inter y crear el emblema SVG, icono legacy y adaptativo

## 2. Identidad y shell

- [x] 2.1 Tema centralizado pine/ochre/moss con extensiones de color y tipografía Inter
- [x] 2.2 Shell con menú lateral (Grabar, Historial, Ajustes) y cabecera TolochaTracks
- [x] 2.3 Pantallas provisionales de Grabación, Historial y Ajustes
- [x] 2.4 Test de widget del shell y de la navegación básica

## 3. Gobernanza OpenSpec

- [x] 3.1 Configuración personalizada de OpenSpec con marcador y reglas del proyecto
- [x] 3.2 Scripts `new_change.sh`, `check_changes.sh`, `spec_id.py` y `bump.js`
- [x] 3.3 Script `verificar.sh` y `check_openspec_config.sh`; `npm run verify`
- [x] 3.4 `AGENTS.md`, README, `.gitignore`, commitlint y reglas de todowrite

## 4. CI/CD y release

- [x] 4.1 Workflow de CI con formato, análisis, tests, commitlint y build APK
- [x] 4.2 Workflow de versionado al fusionar en dev (bump + tag)
- [x] 4.3 Workflow de release con APK firmado y checksum
- [x] 4.4 Crear repo público, keystore de release y secretos de GitHub

## 5. Verificación

- [x] 5.1 `flutter analyze` y `flutter test` en verde con `dart format` aplicado
- [x] 5.2 Build local de APK release correcto
- [ ] 5.3 Primer push a dev y comprobación del pipeline
