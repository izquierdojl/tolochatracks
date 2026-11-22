# Proposal

## Why

Flutter 3.50.1 avisa de que Gradle 9.3.1, AGP 9.1.1 y Kotlin 2.4.x dejarán de ser
soportados pronto. Su propia plantilla ya usa **Gradle 9.5.0, AGP 9.3.1 y Kotlin
2.4.20**, y el proyecto se quedó un escalón por detrás al actualizar Flutter. Alinear
ahora las versiones evita que el próximo salto de Flutter rompa el build y elimina los
avisos de soporte obsoleto.

## What Changes

- Subir Gradle de 9.3.1 a **9.5.0** en `android/gradle/wrapper/gradle-wrapper.properties`.
- Subir Android Gradle Plugin de 9.1.1 a **9.3.1** y Kotlin Gradle Plugin de 2.4.0 a
  **2.4.20** en `android/settings.gradle.kts`.
- Mantener `android.newDsl=false` y `android.builtInKotlin=false` tal como los genera
  la plantilla de Flutter 3.50.1.
- Verificar con `npm run verify`, compilar el APK release y arrancarlo en el emulador,
  comprobando que desaparecen los avisos de versiones a punto de dejar de soportarse.
- Publicar: archivar el change, commit y push a `dev`; bump automático de patch
  (0.9.1 → 0.9.2) y release del APK.

## Capabilities

### New Capabilities

_(ninguna: es infraestructura de build; no cambia comportamiento observable)_

### Modified Capabilities

_(ninguna)_

## Impact

- `android/gradle/wrapper/gradle-wrapper.properties` y `android/settings.gradle.kts`.
- Tiempo de build local y de CI (descarga de Gradle 9.5.0 y artefactos nuevos).
- Release: nuevo tag `v0.9.2` y APK firmado con el mismo keystore.

## Fuera de alcance

- Migrar al Kotlin integrado de AGP (`android.builtInKotlin=true`); la plantilla de
  Flutter 3.50.1 todavía usa el plugin `org.jetbrains.kotlin.android`.
- Actualizar Flutter, Dart o dependencias de la app.
- Cambios de comportamiento, UI o funcionalidades.
- Publicación en Play Store, iOS, escritorio, web o Docker.
