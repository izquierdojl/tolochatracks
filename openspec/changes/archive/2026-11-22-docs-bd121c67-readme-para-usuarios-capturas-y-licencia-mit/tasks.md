# Tasks

## 1. Licencia MIT y pantalla «Acerca de»

- [x] 1.1 Crear `LICENSE` con el texto estándar MIT y `Copyright (c) 2026 izquierdojl`;
  verificar que el archivo existe, que contiene «MIT License» y que `git diff --check` no
  marca problemas.
- [x] 1.2 Actualizar el tile «Código público» de `acerca_de_pantalla.dart` a «Código con
  licencia MIT», con un subtítulo que nombre MIT y remita al archivo `LICENSE`; verificar
  con `flutter analyze` que no hay errores.
- [x] 1.3 Añadir `test/features/acerca_de_pantalla_test.dart` con `PackageInfo` simulado y
  un `ConfiguracionController` con servicios falsos, comprobando que se lee «MIT» y que
  sigue visible la licencia SIL OFL de Inter; verificar con
  `flutter test test/features/acerca_de_pantalla_test.dart`.
- [x] 1.4 Ejecutar `flutter test` completo y confirmar que ninguna prueba existente de
  configuración o shell se rompe por el cambio de texto.

## 2. Documentación técnica en `docs/`

- [x] 2.1 Crear `docs/desarrollo.md` con requisitos, comandos (`pub get`, `verify`,
  `run`, `build apk`), estructura de carpetas y flujo OpenSpec; verificar que cada comando
  documentado existe en `package.json`/`scripts/` y que los enlaces a `AGENTS.md` y
  `openspec/config.yaml` resuelven.
- [x] 2.2 Crear `docs/arquitectura.md` con las capas `lib/app`, `lib/core` y
  `lib/features`, el formato de sesión, el borrador recuperable y la inyección de
  servicios; verificar que las rutas citadas existen con `test -d` y que no contradice
  `AGENTS.md`.
- [x] 2.3 Crear `docs/exportacion.md` con GPX 1.1, JSON, nombres de archivo, selector SAF,
  permisos persistentes y comportamiento ante errores; verificar que los nombres y
  mensajes coinciden con `lib/core/exportacion/` y las specs de exportación.
- [x] 2.4 Crear `docs/releases.md` con semver, ramas `main`/`dev`, workflows `ci.yml`,
  `version.yml` y `release.yml`, firma con secretos y enlaces de descarga estables;
  verificar que los nombres de workflow y secretos coinciden con `.github/workflows/` y
  `AGENTS.md`.
- [x] 2.5 Crear `docs/privacidad-y-mapas.md` con datos locales, permisos Android, batería,
  servicio en primer plano, proveedores de teselas y atribución ODbL; verificar que las
  atribuciones coinciden con `lib/core/models/proveedor_mapas.dart` y que el documento
  indica que la app funciona sin mapas.
- [x] 2.6 Crear `docs/README.md` como índice de los documentos anteriores, indicando para
  quién es cada uno y enlazando a `AGENTS.md`; verificar con `find docs -name '*.md'` que
  todos los documentos citados existen.

## 3. README para personas usuarias

- [x] 3.1 Reescribir `README.md` con introducción breve, badge de licencia, galería de
  capturas, funciones por tarea, instalación del APK, privacidad resumida, preguntas
  frecuentes, licencia y enlaces a `docs/README.md`; verificar que conserva la atribución
  de OpenStreetMap/OpenTopoMap/CyclOSM y el enlace estable de descarga.
- [x] 3.2 Añadir la sección de licencia MIT, la nota de que los datos de mapas son ODbL y
  que Inter usa SIL OFL 1.1; verificar que `LICENSE` y el texto del README coinciden y que
  no se afirma otra licencia para el código.
- [x] 3.3 Revisar que ningún detalle técnico útil se ha perdido: comparar las secciones del
  README anterior con `docs/` y confirmar que desarrollo, releases, exportación, batería y
  mapas tienen su documento de destino.

## 4. Capturas reales de la app

- [x] 4.1 Arrancar el AVD `Medium_Phone_API_37.0`, instalar una compilación debug y fijar
  el tema claro; verificar que la app abre en «Grabar» y que `adb shell pm list packages`
  muestra `com.izquierdojl.tolochatracks`.
- [x] 4.2 Generar tres sesiones de ejemplo en formato 3 (correr, senderismo y bicicleta)
  con rutas inventadas en Toledo, inyectarlas en `app_flutter/sesiones` con `run-as` y
  verificar en el historial que aparecen las tres con sus totales.
- [x] 4.3 Capturar `01-grabacion.png`, `02-historial.png`, `03-detalle.png`, `04-mapa.png`
  y `05-ajustes.png` en `docs/capturas/`; verificar que cada archivo mide 1080 px de ancho,
  que no muestra datos personales y que la captura del mapa tiene teselas visibles.
- [x] 4.4 Optimizar las capturas (PNG sin pérdida o `pngquant` si está disponible) y
  comprobar que el conjunto no supera 1,5 MB con `du -ch docs/capturas/*.png`.
- [x] 4.5 Limpiar los datos de ejemplo del emulador y los temporales; verificar con
  `git status` que solo se añaden las capturas y que no se commitea ningún JSON de sesión.

## 5. Integración y validación

- [x] 5.1 Insertar la galería en el README con rutas relativas y texto alternativo;
  verificar que cada ruta de imagen existe y que GitHub renderiza el Markdown (revisión
  local de enlaces relativos).
- [x] 5.2 Ejecutar `openspec validate docs-bd121c67-readme-para-usuarios-capturas-y-licencia-mit --strict`
  y corregir cualquier aviso de requisitos o escenarios.
- [x] 5.3 Ejecutar `npm run verify` y confirmar formato, análisis, tests y checks de
  OpenSpec en verde.
- [x] 5.4 Revisar el diff completo (`git diff --stat`, `git diff --check`) y confirmar que
  no hay secretos, archivos de build ni capturas de más.

## Workflow follow-up

- Commitear en `dev` con un mensaje convencional `docs:` cuando la revisión esté aprobada.
- Archivar el change y comprobar con `git status` que no queda nada sin commitear.
