# Spec Delta

## MODIFIED Requirements

### Requirement: Exportar una sesión

El detalle SHALL ofrecer «Exportar ruta». Si no hay carpeta configurada, SHALL pedir
elegirla antes de exportar. Al terminar, SHALL informar de los archivos escritos o del
error, sin borrar la sesión local, y SHALL actualizar el estado de exportación de la
sesión según el resultado.

#### Scenario: Exportación correcta

- **WHEN** hay carpeta configurada y el usuario exporta una sesión
- **THEN** se escriben el GPX y el JSON, se muestra un mensaje de éxito y la sesión queda
  marcada como exportada

#### Scenario: Sin carpeta

- **WHEN** no hay carpeta configurada y el usuario pulsa exportar
- **THEN** se abre el selector y, si se elige una, continúa la exportación

#### Scenario: Exportación incompleta

- **WHEN** solo uno de los dos archivos se escribe correctamente
- **THEN** se informa del error y la sesión no queda marcada como exportada

### Requirement: Exportar el historial visible

El historial SHALL ofrecer «Exportar todo» para las sesiones visibles según el filtro
activo, con el mismo comportamiento de carpeta y el mismo informe. Al terminar, SHALL
actualizar el estado de exportación solo de las sesiones cuyos dos archivos se escribieron
correctamente.

#### Scenario: Exportar todas las rutas

- **WHEN** el historial muestra todas las rutas y el usuario pulsa «Exportar todo»
- **THEN** se exportan dos archivos por cada sesión visible y todas quedan marcadas

#### Scenario: Error parcial en una sesión

- **WHEN** una sesión falla al exportar y las demás terminan correctamente
- **THEN** las correctas quedan marcadas y la fallida no, y el mensaje informa del error

## ADDED Requirements

### Requirement: Estado de exportación de una sesión

La app SHALL recordar si la última exportación intentada de cada sesión completó su GPX y
su JSON. El estado SHALL persistir entre arranques y SHALL mostrarse con un check en el
historial y en el detalle. Una exportación fallida o incompleta SHALL desmarcar la
sesión; una exportación correcta posterior SHALL marcarla.

#### Scenario: Primera exportación correcta

- **WHEN** el usuario exporta una sesión y se escriben los dos archivos
- **THEN** la sesión queda marcada y el check sigue visible tras reiniciar la app

#### Scenario: Reexportación fallida

- **WHEN** una sesión ya marcada se vuelve a exportar y falla
- **THEN** la sesión deja de mostrarse como exportada, porque la última exportación no
  completó los dos archivos

#### Scenario: Sesión antigua sin estado

- **WHEN** la app abre una sesión guardada antes de existir este estado
- **THEN** se trata como no exportada y se puede exportar con normalidad

#### Scenario: Cambiar de carpeta

- **WHEN** el usuario cambia la carpeta de exportación
- **THEN** las marcas existentes se conservan y las nuevas exportaciones usan la carpeta
  actual

### Requirement: Borrado de los archivos exportados

Al eliminar una sesión marcada como exportada, la app SHALL ofrecer borrar también su GPX
y su JSON de la carpeta de exportación actual. La opción SHALL estar desmarcada por
defecto y SHALL indicar la carpeta. Si no hay carpeta o el permiso se perdió, la app SHALL
explicarlo y SHALL permitir eliminar solo la sesión local.

#### Scenario: Borrar ruta y archivos

- **WHEN** el usuario confirma la eliminación con la opción de borrar archivos marcada
- **THEN** se borran la sesión local, el GPX y el JSON de la carpeta actual

#### Scenario: Conservar los archivos

- **WHEN** el usuario confirma la eliminación sin marcar la opción
- **THEN** se borra solo la sesión local y los archivos exportados permanecen

#### Scenario: Sin carpeta configurada

- **WHEN** la sesión está marcada pero no hay carpeta de exportación configurada
- **THEN** la app explica que no puede borrar los archivos y permite eliminar solo la
  sesión

#### Scenario: Permiso perdido

- **WHEN** la carpeta ya no es accesible al borrar los archivos
- **THEN** la sesión local se elimina y la app informa de que los archivos no se pudieron
  borrar

#### Scenario: Archivos ya ausentes

- **WHEN** los archivos ya no están en la carpeta actual
- **THEN** la sesión local se elimina y la app informa de que no se encontraron los
  archivos
