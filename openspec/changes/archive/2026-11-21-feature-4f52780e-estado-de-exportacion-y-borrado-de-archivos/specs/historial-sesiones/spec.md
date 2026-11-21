# Spec Delta

## MODIFIED Requirements

### Requirement: Listado del historial

La app SHALL mostrar las sesiones guardadas ordenadas de la más reciente a la más antigua,
con la actividad, la fecha, la distancia, la duración y el ritmo o velocidad media. Las
sesiones marcadas como exportadas SHALL mostrar un check visible y accesible.

#### Scenario: Varias rutas

- **WHEN** existen varias sesiones guardadas
- **THEN** se listan de la más reciente a la más antigua con sus datos resumidos

#### Scenario: Sin rutas

- **WHEN** no hay sesiones guardadas
- **THEN** se muestra un estado vacío en español que invita a grabar la primera ruta

#### Scenario: Ruta exportada

- **WHEN** una sesión está marcada como exportada
- **THEN** su tarjeta muestra un check con una etiqueta accesible que indica que tiene
  copia en disco

#### Scenario: Ruta no exportada

- **WHEN** una sesión no está marcada como exportada
- **THEN** su tarjeta no muestra el check

### Requirement: Detalle de una sesión

Al pulsar una tarjeta, la app SHALL abrir una pantalla con la actividad, la fecha, la
duración y las estadísticas completas calculadas a partir de los puntos: distancia,
tiempo activo, tiempo total, ritmo o velocidad media, velocidad máxima, desnivel positivo
y negativo, altitud mínima y máxima y número de puntos. El detalle SHALL incluir además
una tarjeta de gráficos conmutables (Distancia, Velocidad, Altitud y Por minuto), una
tabla de parciales por kilómetro y el mapa de la ruta. Si la sesión está marcada como
exportada, el detalle SHALL mostrar el check «Exportada a disco».

#### Scenario: Detalle de una ruta con altitudes

- **WHEN** la sesión tiene puntos con altitud
- **THEN** el detalle muestra los desniveles y las altitudes mínima y máxima

#### Scenario: Sesión sin altitudes

- **WHEN** la sesión no tiene datos de altitud
- **THEN** el detalle muestra «—» en los campos de altitud sin fallar

#### Scenario: Actividad de bicicleta

- **WHEN** la sesión es de bicicleta
- **THEN** el detalle usa velocidad en km/h en lugar de ritmo min/km

#### Scenario: Detalle con gráficos y parciales

- **WHEN** el usuario abre una sesión con puntos suficientes
- **THEN** el detalle muestra la tarjeta de gráficos y la tabla de parciales junto a las
  estadísticas existentes

#### Scenario: Detalle con mapa

- **WHEN** el usuario abre una sesión con puntos
- **THEN** el detalle muestra el mapa de la ruta junto a las estadísticas y los gráficos

#### Scenario: Sesión exportada

- **WHEN** el usuario abre una sesión marcada como exportada
- **THEN** el detalle muestra el check «Exportada a disco»

#### Scenario: Sesión no exportada

- **WHEN** el usuario abre una sesión sin marcar como exportada
- **THEN** el detalle no muestra el check

### Requirement: Eliminación de sesiones

La app SHALL permitir eliminar una sesión desde su detalle, pidiendo confirmación. Al
confirmar, SHALL borrar el archivo interno, volver al historial y actualizar los totales;
si no quedan sesiones, SHALL mostrar el estado vacío. Si la sesión está marcada como
exportada, el diálogo SHALL ofrecer, desmarcada por defecto, la opción de borrar también
su GPX y su JSON de la carpeta de exportación actual, e indicará la carpeta. La
eliminación local SHALL completarse aunque falle el borrado de los archivos externos,
informando del resultado.

#### Scenario: Eliminar la única ruta

- **WHEN** el usuario confirma la eliminación de la única sesión
- **THEN** el archivo se borra, el historial queda vacío y se muestra el estado vacío

#### Scenario: Cancelar la eliminación

- **WHEN** el usuario abre la confirmación y pulsa Cancelar
- **THEN** la sesión sigue existiendo y el detalle permanece abierto

#### Scenario: Eliminar ruta y archivos exportados

- **WHEN** el usuario marca la opción de borrar los archivos y confirma
- **THEN** se borran la sesión local, el GPX y el JSON de la carpeta indicada, y se
  informa de que la ruta y sus archivos se eliminaron

#### Scenario: Conservar los archivos exportados

- **WHEN** el usuario no marca la opción de borrar los archivos y confirma
- **THEN** se borra solo la sesión local y los archivos exportados permanecen en la
  carpeta

#### Scenario: Ruta no exportada

- **WHEN** la sesión no está marcada como exportada
- **THEN** el diálogo no ofrece borrar archivos y se elimina solo la sesión local

#### Scenario: Sin carpeta configurada

- **WHEN** la sesión está marcada pero no hay carpeta de exportación configurada
- **THEN** el diálogo explica que los archivos no se pueden borrar y permite eliminar
  solo la sesión local

#### Scenario: Error al borrar los archivos

- **WHEN** la sesión local se elimina pero el borrado de los archivos falla
- **THEN** se informa de los archivos que no se pudieron borrar sin deshacer la
  eliminación de la ruta
