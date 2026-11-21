# Design

## Context

Ver `proposal.md`. Las versiones actuales del build Android son Gradle 9.3.1, AGP 9.1.1
y KGP 2.4.0. Flutter 3.50.1 mantiene en
`packages/flutter_tools/lib/src/android/gradle_utils.dart` las versiones de plantilla
Gradle 9.5.0, AGP 9.3.1 y KGP 2.4.20, y considera 9.3.1 la máxima versión de AGP con
soporte completo de Kotlin. El proyecto declara `android.newDsl=false` y
`android.builtInKotlin=false`, tal como genera la plantilla.

## Goals / Non-Goals

**Goals:**

- Alinear Gradle, AGP y Kotlin con la plantilla oficial de Flutter 3.50.1.
- Eliminar los avisos de "soporte que se dejará de dar pronto" del build.
- Mantener el APK funcionando y el pipeline de release intacto.

**Non-Goals:**

- Migrar al Kotlin integrado de AGP o cambiar la estructura del build.
- Tocar código de la app, dependencias o la versión de Flutter.

## Decisions

### 1. Usar exactamente las versiones de plantilla de Flutter 3.50.1

Gradle 9.5.0, AGP 9.3.1 y KGP 2.4.20 son las cifras que Flutter usa en su plantilla y
las que su validador considera soportadas. Alternativa considerada: subir a AGP 9.4 (el
máximo que el tooling conoce); se descarta porque 9.3.1 es la última con soporte completo
de Kotlin y no aporta nada para esta app.

### 2. No migrar todavía al Kotlin integrado de AGP

AGP 9 avisa de que `org.jetbrains.kotlin.android` ya no es necesario, pero la plantilla
de Flutter 3.50.1 sigue usando el plugin y los flags `newDsl`/`builtInKotlin`. Migrar
implica cambiar la configuración de Kotlin y queda fuera del alcance de una actualización
de versiones. Se deja como posible change futuro.

### 3. Verificación equivalente a la actualización de Flutter

Se ejecutan `npm run verify`, `flutter build apk --release` y una prueba de arranque en
el emulador. El build debe terminar sin los avisos de Gradle/AGP/Kotlin obsoletos; si
aparecen otros avisos no bloqueantes, se documentan y no se abordan aquí.

### 4. Release automático

El change es `infra`, así que el push a `dev` dispara la CI, el bump de patch a 0.9.2 y
el release del APK con el keystore de siempre. No se edita la versión a mano.

## Risks / Trade-offs

- **Gradle 9.5.0 cambia el comportamiento del build** → se compila y se prueba el APK
  antes de publicar; revertir el commit devuelve el build a 9.3.1.
- **AGP 9.3.1 exige una versión de Java o de SDK distinta** → el proyecto ya usa JDK 21
  y compileSdk 36; se valida en local y en CI.
- **Kotlin 2.4.20 rompe algún plugin** (geolocator, flutter_map) → los tests y el build
  lo detectan; si ocurre, se vuelve a 2.4.0 y se replantea.
- **El primer build descarga Gradle 9.5.0 y tarda más** → es coste puntual; después
  queda en la caché de Gradle.
- **El aviso del Kotlin integrado sigue apareciendo** → es una deprecación de AGP 9
  independiente de las versiones; se acepta y se deja para un change específico.
- **Rollback**: revertir el commit `infra` en `dev`; el tag y el release 0.9.2 se pueden
  borrar si el APK saliera mal.

## Migration Plan

1. Actualizar wrapper y plugins de Gradle.
2. Ejecutar verificación, build release y prueba en emulador.
3. Archivar el change y commitear en `dev`.
4. Push: CI → bump 0.9.2 → release del APK.
5. Comprobar el release y el APK publicado.

## Open Questions

_(ninguna)_
