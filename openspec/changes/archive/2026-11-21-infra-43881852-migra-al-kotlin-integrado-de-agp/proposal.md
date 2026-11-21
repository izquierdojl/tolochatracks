# Proposal

## Why

AGP 9 avisa de que el plugin `org.jetbrains.kotlin.android` ya no es necesario: desde
AGP 9 el soporte de Kotlin viene integrado y el opt-out desaparece en AGP 10. Migrar
ahora elimina el plugin y su versión del build, simplifica la configuración y quita la
deprecación. Flutter 3.50.1 todavía genera proyectos con el opt-out
(`android.builtInKotlin=false`), pero su plugin de Gradle ya contempla el Kotlin
integrado; se valida a fondo antes de publicar.

## What Changes

- Poner `android.builtInKotlin=true` en `android/gradle.properties` (hoy está en
  `false`) y mantener `android.newDsl=false`, que Flutter 3.50.1 aún necesita.
- Quitar el plugin `org.jetbrains.kotlin.android` de `android/settings.gradle.kts`.
- Quitar el bloque `kotlin { compilerOptions { jvmTarget = ... } }` de
  `android/app/build.gradle.kts`; el Kotlin integrado usa
  `android.compileOptions.targetCompatibility` (17).
- Verificar con `npm run verify`, compilar el APK release y arrancarlo en el emulador,
  comprobando que desaparece el aviso del plugin de Kotlin.
- Publicar: archivar el change, commit y push a `dev`; bump automático de patch
  (0.9.2 → 0.9.3) y release del APK.

## Capabilities

### New Capabilities

_(ninguna: es infraestructura de build; no cambia comportamiento observable)_

### Modified Capabilities

_(ninguna)_

## Impact

- `android/gradle.properties`, `android/settings.gradle.kts` y
  `android/app/build.gradle.kts`.
- Build Android local y en CI; el resto de la app no cambia.
- Release: nuevo tag `v0.9.3` y APK firmado con el mismo keystore.

## Fuera de alcance

- Activar `android.newDsl=true` o migrar el plugin de Gradle de Flutter al nuevo DSL;
  eso depende de Flutter.
- Actualizar el SDK de Android local (`~/Android/Sdk`); es mantenimiento del entorno y
  no afecta al APK de GitHub, que usa el SDK del runner.
- Cambios de comportamiento, UI o funcionalidades.
- Publicación en Play Store, iOS, escritorio, web o Docker.
