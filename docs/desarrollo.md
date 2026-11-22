# Desarrollo

Guía para preparar el entorno, ejecutar la app y trabajar en TolochaTracks sin romper
las reglas del proyecto.

## Requisitos

- Flutter estable **3.50.1** (versión fijada en CI) y el Dart incluido.
- Node.js **22 o superior** para commitlint y los scripts de versión, con la CLI de
  OpenSpec instalada.
- JDK 21 y Android SDK para compilar el APK.
- Un dispositivo Android o el AVD `Medium_Phone_API_37.0`.

La constitución completa del proyecto está en [`AGENTS.md`](../AGENTS.md). Si una
instrucción de esta guía entra en conflicto con ella, prevalece `AGENTS.md`.

## Puesta en marcha

```bash
flutter pub get
npm install
flutter run -d <dispositivo>
```

Para compilar un APK de pruebas:

```bash
flutter build apk --debug
```

Para compilar el APK de release firmado, configura antes
`android/key.properties` y el keystore; el proceso completo está en
[`releases.md`](releases.md).

## Verificación antes de terminar

```bash
npm run verify
```

El comando ejecuta, en este orden:

1. `scripts/check_openspec_config.sh`: comprueba que la configuración personalizada de
   OpenSpec conserva el marcador y las reglas del proyecto.
2. `scripts/check_changes.sh`: valida el nombre y el `meta.yaml` de todos los changes.
3. `dart format --output=none --set-exit-if-changed lib test`.
4. `flutter analyze`.
5. `flutter test`.

Comandos sueltos habituales:

```bash
dart format lib test
flutter analyze
flutter test
bash scripts/check_changes.sh
bash scripts/check_openspec_config.sh
```

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `lib/app/` | Arranque, tema, shell y navegación. |
| `lib/core/` | Modelos, cálculos, repositorios, servicios, exportación y widgets compartidos. |
| `lib/features/` | `configuracion`, `grabacion`, `sesiones`, `exportacion` y `compartir`, con `data/` y `ui/`. |
| `test/` | Pruebas unitarias y de widgets, con fakes en `test/apoyo/falsos.dart`. |
| `android/` | Proyecto Android, manifiesto, servicio en primer plano y canales nativos. |
| `assets/` | Iconos, fuentes Inter y recursos de marca. |
| `openspec/` | Specs, changes activos y archivados, y configuración del flujo. |
| `scripts/` | Gobernanza, validación, IDs de changes y bump de versión. |
| `docs/` | Esta documentación técnica y las capturas de ejemplo. |

Los detalles de diseño están en [`arquitectura.md`](arquitectura.md).

## Flujo de trabajo con OpenSpec

Toda funcionalidad o corrección empieza como change:

```bash
scripts/new_change.sh <tipo> "<título>" [dev|feature]
```

- Tipos: `feature`, `bug`, `docs`, `infra`, `refactor`, `test` y `chore`.
- El script genera un nombre `<tipo>-<id8>-<slug>` y escribe `meta.yaml` con tipo, ID,
  título, autor, fecha y rama.
- `dev` es el valor por defecto y el destino de todos los PR. `feature` crea la rama
  `feature/<tipo>-<id8>-<slug>`.
- Los artefactos del change viven en `openspec/changes/<nombre>/`.
- Al archivar, se commitea todo (código y specs) en la rama de trabajo.

El esquema por defecto es `spec-driven` y está configurado en
[`openspec/config.yaml`](../openspec/config.yaml). La configuración personalizada no debe
regenerarse ni perderse: `scripts/check_openspec_config.sh` falla en CI si desaparece.

## Pruebas

- Los cálculos de distancia, ritmo, velocidad, desnivel y parciales son funciones puras
  en `lib/core/calculos/` y se prueban sin plugins.
- Los repositorios y servicios se inyectan; en tests se usan los fakes de
  `test/apoyo/falsos.dart`.
- `PackageInfo` se simula con `PackageInfo.setMockInitialValues`.
- Las pruebas de widgets cubren estados vacíos, grabación, pausa, GPS sin señal, mapas y
  exportación.
- Los tests no deben depender de red ni de un dispositivo real.

## Depuración de mapas

`flutter_map` avisa en consola del uso de teselas públicas de OpenStreetMap. Es un aviso
informativo: la app es un cliente pequeño y no descarga mapas en bloque. Si no hay red, la
grabación, el historial, las estadísticas y la exportación deben seguir funcionando; el
mapa se muestra vacío o con el estado «Sin mapas».

## Capturas para la documentación

Las capturas de `docs/capturas/` se obtienen del emulador con datos de ejemplo locales, no
con datos personales. El procedimiento es:

1. Arrancar el AVD y fijar el tema claro.
2. Instalar una compilación debug.
3. Crear sesiones de ejemplo con el formato JSON actual en
   `app_flutter/sesiones` mediante `adb shell run-as`.
4. Capturar con `adb exec-out screencap -p`.
5. Optimizar el PNG y borrar los datos de ejemplo del emulador.

No se commitean los JSON de ejemplo ni se añade código de sembrado a la app.
