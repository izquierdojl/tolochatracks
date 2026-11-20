# exportacion-sesiones Specification

## Purpose
Permite sacar las rutas del dispositivo en formatos abiertos y elegir una vez la carpeta
de destino, con control total del usuario.

## Requirements

### Requirement: Formatos de exportación

La app SHALL exportar cada sesión en dos archivos: GPX 1.1 válido, con metadatos y un
`trkpt` por punto con latitud, longitud, altitud (si existe) y tiempo; y JSON nativo con
la sesión completa serializada.

#### Scenario: Exportar una ruta con altitudes

- **WHEN** el usuario exporta una sesión con altitudes
- **THEN** el GPX contiene un `trkpt` por punto con `<ele>` y `<time>` y el JSON conserva
  la sesión íntegra

#### Scenario: Ruta sin altitudes

- **WHEN** la sesión no tiene altitud en sus puntos
- **THEN** el GPX omite `<ele>` en esos puntos sin dejar el archivo inválido

### Requirement: Nombres de archivo

Los nombres SHALL ser estables, sin caracteres problemáticos y distinguir sesión y
formato, con la fecha, la actividad y un identificador de la sesión.

#### Scenario: Actividad con acentos

- **WHEN** la actividad es «Senderismo» o el nombre contiene acentos
- **THEN** el nombre del archivo usa solo caracteres ASCII seguros y no se sobrescribe
  con otra sesión

### Requirement: Selección de carpeta

La app SHALL usar el selector SAF de Android para que el usuario elija la carpeta de
exportación y SHALL conservar el permiso entre arranques. La carpeta y su nombre SHALL
poder cambiarse o quitarse desde Ajustes.

#### Scenario: Elegir carpeta

- **WHEN** el usuario elige una carpeta en Ajustes
- **THEN** la app guarda su URI persistente y muestra el nombre de la carpeta

#### Scenario: Cancelar la selección

- **WHEN** el usuario cierra el selector sin elegir carpeta
- **THEN** no se exporta nada y se conserva la carpeta anterior si existía

#### Scenario: Permiso perdido

- **WHEN** la carpeta guardada ya no es accesible
- **THEN** la exportación falla con un mensaje que pide volver a elegirla

### Requirement: Exportar una sesión

El detalle SHALL ofrecer «Exportar ruta». Si no hay carpeta configurada, SHALL pedir
elegirla antes de exportar. Al terminar, SHALL informar de los archivos escritos o del
error, sin borrar la sesión local.

#### Scenario: Exportación correcta

- **WHEN** hay carpeta configurada y el usuario exporta una sesión
- **THEN** se escriben el GPX y el JSON y se muestra un mensaje de éxito

#### Scenario: Sin carpeta

- **WHEN** no hay carpeta configurada y el usuario pulsa exportar
- **THEN** se abre el selector y, si se elige una, continúa la exportación

### Requirement: Exportar el historial visible

El historial SHALL ofrecer «Exportar todo» para las sesiones visibles según el filtro
activo, con el mismo comportamiento de carpeta y el mismo informe.

#### Scenario: Exportar todas las rutas

- **WHEN** el historial muestra todas las rutas y el usuario pulsa «Exportar todo»
- **THEN** se exportan dos archivos por cada sesión visible

### Requirement: Errores parciales

Si algunos archivos fallan, la app SHALL informar de cuántos se exportaron y qué errores
hubo, sin marcar la operación como totalmente correcta.

#### Scenario: Una carpeta deja de aceptar escritura

- **WHEN** la escritura de uno de los archivos falla
- **THEN** el mensaje indica los exportados y los errores, y los archivos correctos se
  conservan
