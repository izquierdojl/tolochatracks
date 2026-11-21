# compartir-rutas Specification

## Purpose

Permite enviar una ruta concreta a otras apps mediante el selector de Android, sin subirla
a ningún servidor y sin depender de la carpeta de exportación.

## Requirements

### Requirement: Compartir una ruta como GPX

La app SHALL permitir compartir una sesión concreta generando un GPX 1.1 temporal y
abriendo el selector de Android. La acción SHALL funcionar sin conexión y sin carpeta de
exportación configurada, y no SHALL modificar la sesión guardada.

#### Scenario: Compartir desde el detalle

- **WHEN** el usuario abre una sesión y pulsa «Compartir ruta» en la barra superior
- **THEN** se genera el GPX de esa sesión y se abre el selector de Android para elegir la
  app de destino

#### Scenario: Compartir desde el historial

- **WHEN** el usuario pulsa compartir en la tarjeta de una sesión del historial
- **THEN** se comparte esa sesión sin abrir el detalle y sin cambiar el filtro activo

#### Scenario: Sin carpeta de exportación

- **WHEN** no hay carpeta de exportación configurada
- **THEN** la app comparte igualmente y no pide elegir una carpeta

#### Scenario: Sin conexión

- **WHEN** el dispositivo no tiene conexión a Internet
- **THEN** el GPX se genera y el selector se abre; la app no intenta ninguna subida

### Requirement: Contenido del GPX compartido

El GPX SHALL ser válido, con metadatos y un `trkpt` por punto con latitud, longitud,
altitud cuando exista y tiempo. SHALL usar el mismo generador que la exportación y un
nombre estable basado en la sesión, sin incluir datos de otras rutas.

#### Scenario: Ruta con altitudes

- **WHEN** la sesión tiene puntos con altitud
- **THEN** el GPX compartido incluye `<ele>` y `<time>` en esos puntos

#### Scenario: Ruta sin altitudes

- **WHEN** la sesión no tiene datos de altitud
- **THEN** el GPX omite `<ele>` y sigue siendo un GPX 1.1 válido

#### Scenario: Ruta sin puntos

- **WHEN** la sesión no tiene ningún punto válido
- **THEN** la app muestra un mensaje en español, no abre el selector y conserva la ruta

### Requirement: Puntos de acceso y estados

El detalle SHALL ofrecer «Compartir ruta» en su barra superior y cada tarjeta del historial
SHALL ofrecer compartir esa sesión. Mientras se prepara el archivo, la app SHALL mostrar
progreso y evitar envíos duplicados; cancelar el selector no SHALL mostrar un error.

#### Scenario: Progreso en el detalle

- **WHEN** el usuario pulsa compartir y el GPX todavía se está preparando
- **THEN** el botón muestra progreso y no se puede volver a pulsar hasta terminar

#### Scenario: Progreso en el historial

- **WHEN** el usuario comparte desde una tarjeta y la preparación está en curso
- **THEN** solo esa acción muestra progreso y las demás tarjetas siguen visibles

#### Scenario: Cancelar el selector

- **WHEN** el usuario cierra el selector de Android sin elegir una app
- **THEN** no se muestra un error y la ruta sigue intacta

#### Scenario: Error al preparar el archivo

- **WHEN** falla la generación o escritura del GPX temporal
- **THEN** la app muestra un mensaje en español y la ruta permanece en el historial

#### Scenario: Fallo al abrir el selector

- **WHEN** el sistema no puede abrir el selector de compartir
- **THEN** la app informa de que no se pudo compartir y no pierde la ruta

### Requirement: Privacidad y archivos temporales

Compartir SHALL ser siempre una acción explícita del usuario. La app no SHALL subir la
ruta a servidores propios, generar enlaces públicos ni compartirla sin que el usuario
elija un destino. El GPX SHALL escribirse en la caché temporal de la app y no en la
carpeta de exportación.

#### Scenario: Acción explícita

- **WHEN** el usuario no ha pulsado compartir
- **THEN** la app no envía la ruta a ninguna app ni servicio

#### Scenario: Archivo temporal

- **WHEN** el usuario comparte una ruta
- **THEN** el GPX se crea en la caché temporal y no se añade a la carpeta de exportación

#### Scenario: La ruta permanece en el historial

- **WHEN** el usuario termina de compartir o cancela el selector
- **THEN** la sesión sigue guardada y disponible en el historial
