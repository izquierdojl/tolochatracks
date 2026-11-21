# Tasks

## 1. Kotlin integrado

- [x] 1.1 Poner `android.builtInKotlin=true` en `android/gradle.properties`, mantener `android.newDsl=false` y verificar que `flutter pub get` no vuelve a escribir `false`
- [x] 1.2 Quitar el plugin `org.jetbrains.kotlin.android` de `android/settings.gradle.kts` y el bloque `kotlin { compilerOptions { ... } }` de `android/app/build.gradle.kts`; verificar con `grep` que no quedan referencias a KGP ni a `JvmTarget`

## 2. Verificación

- [x] 2.1 Ejecutar `flutter clean`, `flutter pub get` y `npm run verify`; verificar que formato, configuración OpenSpec, análisis y tests quedan en verde
- [x] 2.2 Compilar `flutter build apk --release`, verificar que no aparece el aviso de deprecación de `org.jetbrains.kotlin.android` y que el APK arranca en el emulador

## Workflow follow-up

- Archivar el change con `openspec archive` y comprobar que `openspec/specs` no cambia.
- Commitear el change en `dev` con `git status` limpio y hacer push.
- Vigilar la CI de `dev`, el bump automático a 0.9.3 de `version.yml` y el release del APK.
- Verificar la descarga, el checksum y la firma del APK publicado.
