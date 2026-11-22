# Design

## Context

Ver `proposal.md`. El proyecto usa AGP 9.3.1, Gradle 9.5.0 y el plugin KGP 2.4.20 en
`android/settings.gradle.kts`. `android/gradle.properties` conserva el opt-out
`android.builtInKotlin=false` y `android.newDsl=false` que genera Flutter 3.50.1.

AGP 9.3.1 implementa Kotlin integrado y lo activa por defecto; el plugin KGP ya no es
necesario. Flutter 3.50.1 sigue desactivándolo en su plantilla, pero su plugin de Gradle
tiene soporte explícito: `FlutterPluginUtils.isBuiltInKotlinEnabled` y
`VersionFetcher.getKGPVersion` tratan la ausencia de KGP como un caso válido.

## Goals / Non-Goals

**Goals:**

- Compilar Kotlin con el soporte integrado de AGP, sin KGP.
- Eliminar el aviso de deprecación y dejar el build listo para AGP 10.
- Mantener el APK y la app funcionando igual.

**Non-Goals:**

- Activar `android.newDsl=true`; el plugin de Flutter aún usa el DSL antiguo.
- Migrar a AGP 10 o cambiar la versión de Flutter.
- Tocar código Dart, dependencias o comportamiento.

## Decisions

### 1. Fijar `android.builtInKotlin=true` explícitamente

No basta con borrar la línea: el migrador de Flutter (`DisableBuiltInKotlinMigration`)
añade `android.builtInKotlin=false` cuando no encuentra el flag, y AGP 9 lo activa por
defecto. Dejarlo en `true` documenta la decisión y evita que `flutter pub get` lo vuelva
a desactivar. Alternativa considerada: borrar la línea y confiar en el valor por defecto
de AGP; se descarta por el migrador.

### 2. Mantener `android.newDsl=false`

El plugin de Gradle de Flutter 3.50.1 todavía usa APIs del DSL antiguo; su propia
documentación interna planifica el cambio a `newDsl=true` en una fase posterior. Con
KGP fuera del build, el motivo original del opt-out (incompatibilidad KGP/newDsl)
desaparece, pero Flutter sigue necesitando el DSL antiguo.

### 3. Quitar el bloque `kotlin { compilerOptions { ... } }`

El Kotlin integrado toma `jvmTarget` de `android.compileOptions.targetCompatibility`, que
el proyecto ya fija en Java 17. Mantener el bloque no aporta nada y arrastra el tipo
`org.jetbrains.kotlin.gradle.dsl.JvmTarget`, que pertenece a KGP.

### 4. Validación reforzada antes de publicar

Al no ser el camino por defecto de Flutter, se ejecutan `flutter clean`, `flutter pub
get`, `npm run verify`, `flutter build apk --release` y una prueba de arranque en el
emulador. Si el build falla por incompatibilidad del tooling de Flutter, se revierte el
change y se reporta; no se fuerza una solución fuera de alcance.

## Risks / Trade-offs

- **Flutter 3.50.1 no valida oficialmente el Kotlin integrado** (su plantilla lo
  desactiva) → se prueba el APK completo; ante cualquier fallo, rollback al commit
  anterior.
- **Algún plugin Android aplica KGP y choca con el Kotlin integrado** → el build lo
  detecta con el error de extensión `kotlin` duplicada; si ocurre, se revierte y se
  documenta el plugin culpable.
- **El bloque `kotlin` de la app deja de existir** → se elimina y se confía en
  `targetCompatibility = 17`, verificado en el APK.
- **El migrador de Flutter vuelve a poner `builtInKotlin=false`** → se comprueba tras
  `flutter pub get` que sigue en `true`.
- **Rollback**: revertir el commit `infra` en `dev`; el tag y el release 0.9.3 se pueden
  borrar si el APK saliera mal.

## Migration Plan

1. Activar Kotlin integrado y quitar KGP del build.
2. Limpiar, verificar, compilar y probar en emulador.
3. Archivar el change y commitear en `dev`.
4. Push: CI → bump 0.9.3 → release del APK.
5. Comprobar el release y el APK publicado.

## Open Questions

_(ninguna)_
