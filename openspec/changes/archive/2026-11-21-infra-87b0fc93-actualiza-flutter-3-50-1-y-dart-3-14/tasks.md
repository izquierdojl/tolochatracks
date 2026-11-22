# Tasks

## 1. Versión fijada en CI y documentación

- [x] 1.1 Cambiar `flutter-version` a `3.50.1` en los dos jobs de `.github/workflows/ci.yml` y en `.github/workflows/release.yml`; verificar con `grep -rn "3.47.7" .github/` que no queda ninguna referencia
- [x] 1.2 Actualizar la versión fijada en `AGENTS.md` (§2) y `README.md`; verificar que ambos citan 3.50.1 y que `grep` no encuentra 3.47.7 fuera del historial de changes archivados

## 2. Dart y dependencias

- [x] 2.1 Subir `environment.sdk` de `pubspec.yaml` a `^3.14.0`, ejecutar `flutter pub get` y verificar en `pubspec.lock` que la restricción de Dart resuelta es `>=3.14.0 <4.0.0`
- [x] 2.2 Añadir `material_ui ^1.11.1` a `pubspec.yaml` y sustituir los 28 imports de `package:flutter/material.dart` por `package:material_ui/material_ui.dart`; verificar que no queda ningún import antiguo y que `flutter pub get` resuelve
- [x] 2.3 Resolver cualquier otra rotura que introduzca 3.50.1 (Gradle, APIs) y verificar que `flutter analyze` y `flutter test` pasan sin cambiar comportamiento

## 3. SDK local

- [x] 3.1 Restaurar el índice del checkout `~/flutter` con `git reset` y verificar que el árbol de trabajo conserva los archivos y no pierde contenido local
- [x] 3.2 Descargar el tag `3.50.1` (ampliando profundidad si el clon superficial no lo trae), hacer checkout y precargar artefactos; verificar que `flutter --version` informa Flutter 3.50.1 y Dart 3.14.0

## 4. Verificación e integración

- [x] 4.1 Ejecutar `npm run verify` completo y verificar que formato, configuración OpenSpec, analysis y tests quedan en verde
- [x] 4.2 Compilar `flutter build apk --release` y verificar que el APK existe, está firmado y arranca en el emulador o dispositivo disponible

## Workflow follow-up

- Archivar el change con `openspec archive` y comprobar que `openspec/specs` no cambia (no hay deltas).
- Commitear todo el change en `dev` con `git status` limpio y hacer push.
- Vigilar la CI de `dev`, el bump automático a 0.9.1 de `version.yml` y el release del APK de `release.yml`.
- Verificar la descarga del APK publicado y anotar la versión final.
