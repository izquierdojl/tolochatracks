# Proposal

## Why

La CI y el APK se compilan con Flutter 3.47.7 (Dart 3.13.5), una versión de octubre.
La stable actual es Flutter 3.50.1 (Dart 3.14.0, publicada el 20 de noviembre de 2026),
con correcciones y mejoras del toolchain. Mantener el SDK local, la CI y el APK en la
misma versión evita diferencias entre lo que se prueba en el equipo y lo que se publica,
y deja el proyecto listo para seguir desarrollando sobre la stable vigente.

## What Changes

- Fijar **Flutter 3.50.1** (canal stable, Dart 3.14.0) en `.github/workflows/ci.yml`
  y `.github/workflows/release.yml` (sustituye a 3.47.7).
- Actualizar el SDK local `~/flutter` a la misma versión, restaurando antes el índice
  del checkout (tiene los archivos marcados como borrados en el índice, sin pérdida de
  contenido) y descargando el tag `3.50.1`.
- Actualizar la restricción de Dart en `pubspec.yaml` a `^3.14.0`, regenerar
  `pubspec.lock` y ajustar el código o las dependencias solo si el nuevo análisis o
  los tests lo exigen.
- Migrar los imports de Material al paquete oficial `material_ui` (decisión del
  usuario): Flutter 3.50.1 marca `package:flutter/material.dart` como obsoleto y
  `flutter analyze` falla mientras no se sustituya.
- Subir el Android Gradle Plugin de 9.1.0 a 9.1.1, mínimo que exige Flutter 3.50.1
  para compilar el APK.
- Actualizar las referencias documentales a la versión fijada (`AGENTS.md`, `README.md`).
- Verificar con `npm run verify` y compilar el APK release en local.
- Publicar: archivar el change, commit y push a `dev`; la CI valida, `version.yml`
  aplica el bump automático de patch (0.9.1) y `release.yml` publica el APK compilado
  con Flutter 3.50.1.

## Capabilities

### New Capabilities

_(ninguna: es infraestructura; no cambia comportamiento observable del producto)_

### Modified Capabilities

_(ninguna)_

## Impact

- Workflows de GitHub Actions (`ci.yml`, `release.yml`) y documentación de gobernanza.
- `pubspec.yaml` y `pubspec.lock` (restricción de Dart y resolución de dependencias).
- SDK local `~/flutter` (checkout stable y caché de artefactos).
- Posibles ajustes puntuales en `lib/`, `test/` o `android/` si Flutter 3.50.1 introduce
  avisos o requisitos de build incompatibles.
- Release: nuevo tag `v0.9.1` y APK publicado con la stable nueva.

## Fuera de alcance

- Actualizar dependencias a versiones mayores por iniciativa propia; solo lo que exija
  la compatibilidad con Flutter 3.50.1.
- Cambios de comportamiento, UI o funcionalidades de la app.
- Subir la versión a `1.0.0` (lo decide el usuario) o tocar `main`.
- Publicación en Play Store, iOS, escritorio, web o Docker.
