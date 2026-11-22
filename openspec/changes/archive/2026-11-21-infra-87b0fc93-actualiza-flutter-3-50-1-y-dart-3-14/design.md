# Design

## Context

Ver `proposal.md`. El proyecto fija la versión de Flutter en tres sitios que deben
moverse juntos: los workflows `ci.yml` y `release.yml`, la tabla de stack de `AGENTS.md`
y los requisitos del `README.md`. El SDK local es un checkout git de Flutter en
`~/flutter` con clon parcial (`blob:none`) y superficial; su índice tiene todos los
archivos marcados como borrados, aunque el contenido sigue en disco.

La versión stable vigente es Flutter 3.50.1, que empaqueta Dart 3.14.0. El proyecto
declara `environment.sdk: ^3.13.5` en `pubspec.yaml`, una restricción mínima que ya
admite Dart 3.14 pero que conviene alinear con la versión real de compilación.

## Goals / Non-Goals

**Goals:**

- Que SDK local, CI y APK de release usen exactamente Flutter 3.50.1 / Dart 3.14.0.
- Dejar el rango de Dart de `pubspec.yaml` coherente con el SDK que compila.
- Publicar el APK con la stable nueva mediante el flujo automático de `dev`.

**Non-Goals:**

- Actualizar dependencias por gusto o cambiar comportamiento de la app.
- Alterar la estrategia de release, los secretos de firma o las ramas.
- Migrar a otro canal de Flutter (beta/master) ni a FVM.

## Decisions

### 1. Una sola cifra de versión, replicada en CI y documentación

Se cambia `flutter-version: '3.47.7'` por `'3.50.1'` en `ci.yml` (dos jobs) y
`release.yml`, y se actualizan `AGENTS.md` y `README.md`. Alternativa considerada:
usar `channel: stable` sin versión; se descarta porque rompe la reproducibilidad y la
regla del proyecto de fijar la versión en CI.

### 2. Dart no se instala aparte: viene con Flutter

`subosito/flutter-action` descarga el SDK de Flutter, que incluye su Dart. No hay que
fijar Dart en CI ni instalar un Dart independiente. La restricción `sdk:` de
`pubspec.yaml` es un mínimo de compatibilidad, no la versión de compilación; se sube a
`^3.14.0` para documentar el mínimo real y se regenera `pubspec.lock` con `flutter pub
get`. Alternativa considerada: dejar `^3.13.5`; funciona, pero permite compilar con un
Dart anterior al que usa CI y oculta la dependencia real.

### 3. Actualizar el SDK local con git, no reinstalando

El checkout `~/flutter` conserva los archivos; solo el índice está vacío. Se restaura
con `git reset` (sin tocar el árbol de trabajo), se hace `git fetch` del tag `3.50.1`
(ampliando profundidad si el clon superficial no lo trae), se hace checkout del tag y se
deja que Flutter descargue artefactos con `flutter precache`/`flutter --version`.
Alternativa considerada: reemplazar `~/flutter` por el tarball oficial; se descarta
porque cambia la disposición de la instalación y obliga a rehacer enlaces y caché.

### 4. Compatibilidad: verificar y corregir solo lo que falle

Tras actualizar se ejecutan `flutter pub get`, `npm run verify` y `flutter build apk
--release`. Si aparecen avisos de análisis, tests rotos o incompatibilidades de Gradle,
se corrigen de forma mínima dentro de este change. Flutter 3.50.1 exige como mínimo AGP
9.1.1, así que se sube el plugin de 9.1.0 a 9.1.1. Si el problema exigiera cambios
grandes (por ejemplo, reescribir código), se detiene y se consulta.

### 5. Sustituir Material de Flutter por `material_ui`

Flutter 3.50.1 depreca `package:flutter/material.dart` y `flutter analyze` sale con
código 1 por 28 avisos. Se añade el paquete oficial `material_ui ^1.11.1` y se sustituye
el import en `lib/` y `test/`. `material_ui` reexporta `package:flutter/widgets.dart` y
los mismos widgets, así que el cambio es mecánico y no altera comportamiento.
Alternativa considerada: silenciar `deprecated_member_use` en `analysis_options.yaml`;
se descarta porque oculta deprecaciones futuras y va contra la dirección de Flutter.
Decisión consultada y aprobada por el usuario por afectar a una librería base.

### 6. Release automático, sin bump manual

El change es `infra`, así que `version.yml` aplicará un bump de patch al fusionar en
`dev`: 0.9.0 → 0.9.1. No se edita la versión a mano ni se crea el tag localmente; el
flujo existente espera la CI verde, hace el commit `chore(release)` y dispara
`release.yml`. El APK se publica con el nombre estable de siempre.

## Risks / Trade-offs

- **El clon superficial no trae el tag 3.50.1** → `git fetch origin tag 3.50.1
  --depth=1` o `git fetch --unshallow`; el checkout parcial soporta ambos.
- **El `git reset` en `~/flutter` pisa cambios locales reales** → antes se revisa que
  las 16.076 entradas sean solo borrados de índice y 25 archivos sin seguimiento
  generados; no se borra nada del árbol de trabajo.
- **Flutter 3.50.1 rompe el build Android** (AGP, Gradle, lints nuevos) → se corrige lo
  mínimo y, si el alcance crece, se para y se propone un change aparte.
- **La caché de `subosito/flutter-action` reutiliza artefactos de 3.47.7** → la acción
  incluye la versión en la clave de caché; aun así se comprueba `flutter --version` en
  el log de CI.
- **El APK publicado no arranca en el dispositivo** → se prueba el APK local antes de
  publicar y, si falla, se revierte el commit y se vuelve a fijar 3.47.7.
- **Rollback**: revertir el commit de actualización y el tag `v0.9.1` si el release
  saliera mal; la versión anterior sigue disponible en GitHub Releases.

## Migration Plan

1. Actualizar versiones y documentación; subir la restricción de Dart.
2. Actualizar el SDK local y ejecutar la verificación completa y el APK release.
3. Archivar el change y commitear todo en `dev`.
4. Push a `dev`: CI → `version.yml` (bump 0.9.1) → `release.yml` (APK).
5. Comprobar el release y el APK publicado.

## Open Questions

_(ninguna)_
