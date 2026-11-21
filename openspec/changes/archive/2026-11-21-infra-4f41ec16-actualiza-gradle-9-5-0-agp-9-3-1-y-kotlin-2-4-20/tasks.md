# Tasks

## 1. Versiones del build Android

- [x] 1.1 Cambiar la distribución de Gradle de 9.3.1 a 9.5.0 en `android/gradle/wrapper/gradle-wrapper.properties`; verificar con `cd android && ./gradlew --version` que informa Gradle 9.5.0
- [x] 1.2 Cambiar AGP a 9.3.1 y Kotlin a 2.4.20 en `android/settings.gradle.kts`; verificar con `grep` que no quedan 9.1.1 ni 2.4.0 en la configuración del build

## 2. Verificación

- [x] 2.1 Ejecutar `npm run verify` y verificar que formato, configuración OpenSpec, análisis y tests quedan en verde
- [x] 2.2 Compilar `flutter build apk --release`, verificar que no aparecen avisos de Gradle/AGP/Kotlin "a punto de dejar de soportarse" y que el APK arranca en el emulador

## Workflow follow-up

- Archivar el change con `openspec archive` y comprobar que `openspec/specs` no cambia.
- Commitear el change en `dev` con `git status` limpio y hacer push.
- Vigilar la CI de `dev`, el bump automático a 0.9.2 de `version.yml` y el release del APK.
- Verificar la descarga, el checksum y la firma del APK publicado.
