# historial-sesiones Specification

## Purpose
Permite consultar y gestionar las rutas guardadas en el dispositivo, con un resumen
agregado y una ficha detallada por sesión.

## Requirements

### Requirement: Listado del historial

La app SHALL mostrar las sesiones guardadas ordenadas de la más reciente a la más antigua,
con la actividad, la fecha, la distancia, la duración y el ritmo o velocidad media.

#### Scenario: Varias rutas

- **WHEN** existen varias sesiones guardadas
- **THEN** se listan de la más reciente a la más antigua con sus datos resumidos

#### Scenario: Sin rutas

- **WHEN** no hay sesiones guardadas
- **THEN** se muestra un estado vacío en español que invita a grabar la primera ruta

### Requirement: Totales del historial

La parte superior del historial SHALL mostrar el número de rutas, la distancia total y el
tiempo total de las sesiones visibles según el filtro activo.

#### Scenario: Totales sin filtro

- **WHEN** el historial muestra todas las rutas
- **THEN** los totales suman todas las sesiones guardadas

#### Scenario: Totales con filtro

- **WHEN** el usuario filtra por una actividad
- **THEN** los totales y la lista se recalculan solo con las sesiones de esa actividad

### Requirement: Filtro por actividad

El historial SHALL ofrecer un filtro por actividad (todas, correr, caminar, senderismo,
bicicleta, otras). El filtro SHALL conservarse mientras dure la pantalla y SHALL mostrar
un estado vacío específico si no hay sesiones de esa actividad.

#### Scenario: Filtrar por bicicleta sin rutas

- **WHEN** el usuario selecciona Bicicleta y no hay sesiones de bicicleta
- **THEN** se muestra un mensaje de vacío para ese filtro sin perder las demás rutas

### Requirement: Detalle de una sesión

Al pulsar una tarjeta, la app SHALL abrir una pantalla con la actividad, la fecha, la
duración y las estadísticas completas calculadas a partir de los puntos: distancia,
tiempo activo, tiempo total, ritmo o velocidad media, velocidad máxima, desnivel positivo
y negativo, altitud mínima y máxima y número de puntos. El detalle SHALL incluir además
una tarjeta de gráficos conmutables (Distancia, Velocidad, Altitud y Por minuto), una
tabla de parciales por kilómetro y el mapa de la ruta.

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

### Requirement: Eliminación de sesiones

La app SHALL permitir eliminar una sesión desde su detalle, pidiendo confirmación. Al
confirmar, SHALL borrar el archivo interno, volver al historial y actualizar los totales;
si no quedan sesiones, SHALL mostrar el estado vacío.

#### Scenario: Eliminar la única ruta

- **WHEN** el usuario confirma la eliminación de la única sesión
- **THEN** el archivo se borra, el historial queda vacío y se muestra el estado vacío

#### Scenario: Cancelar la eliminación

- **WHEN** el usuario abre la confirmación y pulsa Cancelar
- **THEN** la sesión sigue existiendo y el detalle permanece abierto

### Requirement: Estados y errores del historial

El historial SHALL mostrar estados de carga, error y vacío; un error de lectura SHALL
ofrecer reintento en español y no impedir volver a grabar.

#### Scenario: Error al leer

- **WHEN** el repositorio falla al listar las sesiones
- **THEN** el historial muestra un mensaje de error con un botón de reintentar
