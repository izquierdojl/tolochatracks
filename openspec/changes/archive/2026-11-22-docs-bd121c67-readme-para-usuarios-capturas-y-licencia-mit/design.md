# Design

## Context

Ver `proposal.md` para la motivación. El README actual mezcla presentación del producto,
detalles de arquitectura, gobernanza OpenSpec y publicación de releases. La app ya tiene
una identidad visual estable (pine/ochre/moss, Inter, tema claro y oscuro) y una pantalla
«Acerca de» que remite al repositorio sin nombrar licencia. El repositorio no tiene
`LICENSE`. El emulador `Medium_Phone_API_37.0` y `adb` están disponibles para obtener
capturas reales.

## Goals / Non-Goals

**Goals:**

- Separar la portada para personas usuarias (`README.md`) de la documentación técnica
  (`docs/`), sin perder información.
- Mostrar la app real con capturas obtenidas del emulador y datos de ejemplo locales.
- Declarar la licencia MIT de forma coherente en `LICENSE`, README y «Acerca de».
- Mantener el README útil como página de descarga y presentación en GitHub.

**Non-Goals:**

- Cambiar la UI, el comportamiento de grabación, la persistencia o la exportación.
- Re-licenciar dependencias, teselas o la tipografía Inter.
- Crear una web, un vídeo o un GIF de presentación.
- Documentar decisiones internas que ya cubre `AGENTS.md`.

## Decisions

### 1. README de producto y `docs/` técnico

`README.md` se organiza como una landing: propuesta de valor, galería de capturas,
funciones explicadas por tarea, instalación del APK, privacidad, preguntas frecuentes,
licencia y enlace al índice técnico. Los detalles que hoy ocupan el README se reparten en:

- `docs/README.md`: índice y para quién es cada documento.
- `docs/desarrollo.md`: entorno, comandos, estructura, tests y flujo OpenSpec.
- `docs/arquitectura.md`: capas, modelos, persistencia, grabación y servicios.
- `docs/exportacion.md`: GPX/JSON, nombres de archivo, selector SAF y errores.
- `docs/releases.md`: semver, CI/CD, firma, ramas y publicación del APK.
- `docs/privacidad-y-mapas.md`: datos, permisos, batería, teselas y atribución.

Se descarta mantener un único README con secciones plegables: sigue siendo largo para
quien solo quiere descargar la app y esconde la documentación técnica.

### 2. Capturas reales, no maquetas

Las capturas se obtienen de la app en el AVD, en tema claro para favorecer la legibilidad
en GitHub, con una resolución de 1080 px de ancho y nombres estables:

- `docs/capturas/01-grabacion.png`: pantalla de inicio de una ruta.
- `docs/capturas/02-historial.png`: historial con varias actividades y totales.
- `docs/capturas/03-detalle.png`: detalle con estadísticas y gráficos.
- `docs/capturas/04-mapa.png`: detalle con la traza sobre OpenStreetMap.
- `docs/capturas/05-ajustes.png`: ajustes con tema, mapas y calidad GPS.

Los datos de ejemplo se inyectan como archivos JSON con el formato de sesión actual
(`formato: 3`) en `app_flutter/sesiones` de una compilación debug mediante `run-as`. No se
añade código de sembrado a la app ni se commitea ningún dato del emulador. Se usan rutas
inventadas en Toledo y se eliminan los datos después de capturar.

Se descartan maquetas generadas porque pueden prometer una interfaz que la app no tiene.
Se descarta grabar con GPS simulado en tiempo real porque alarga la tarea sin aportar
realismo.

### 3. Licencia MIT coherente en todo el repositorio

`LICENSE` usa el texto estándar MIT con `Copyright (c) 2026 izquierdojl`. El README añade
un badge y una sección breve que aclara que los datos de mapas mantienen su licencia
(ODbL) y que Inter usa SIL OFL 1.1. En «Acerca de», el tile «Código público» pasa a
«Código con licencia MIT» y el subtítulo nombra la licencia y remite al archivo `LICENSE`
del repositorio. No se añade un enlace nuevo: el enlace al repositorio ya existe.

### 4. Prueba de la pantalla «Acerca de»

Se añade `test/features/acerca_de_pantalla_test.dart`, con `PackageInfo` simulado y un
`ConfiguracionController` con servicios falsos, que comprueba que se lee «MIT» y que sigue
apareciendo la licencia de Inter. No se toca el resto de pruebas.

### 5. Verificación de enlaces y tamaño

Se comprueban los enlaces relativos del README y de `docs/README.md` con una pasada manual
y `find`/`grep`; no se añade un comprobador nuevo al CI. Las capturas se optimizan con
`pngquant` u `optipng` si están disponibles, con objetivo de menos de 300 KB por imagen.

## Risks / Trade-offs

- **Teselas en blanco en el emulador** → esperar a que cargue el mapa, comprobar la red y,
  si no hay teselas, no publicar una captura vacía: se usa el detalle sin mapa o se
  pospone la captura hasta tenerlas.
- **Formato de sesión cambiado en el futuro** → las capturas se generan con el formato
  vigente y se verifica que el historial las lee antes de capturar.
- **Capturas pesadas en el repositorio** → PNG optimizado y ancho 1080; si el conjunto
  supera 1,5 MB, se reduce el número de capturas antes que la legibilidad.
- **Texto de licencia desincronizado** → LICENSE, README, spec y pantalla se actualizan en
  el mismo change y la prueba de widget falla si desaparece «MIT».
- **Documentación duplicada o divergente** → `AGENTS.md` sigue siendo la fuente de verdad
  de gobernanza; `docs/` enlaza a él y no repite la constitución completa.

## Migration Plan

No hay migración de datos. El cambio es aditivo salvo el texto de «Acerca de»; revertir el
commit restaura el README y el texto anteriores sin afectar a sesiones ni ajustes.
