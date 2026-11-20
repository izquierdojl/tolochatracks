# Spec Delta

## MODIFIED Requirements

### Requirement: Estadísticas en vivo

Durante la grabación, la pantalla SHALL mostrar tiempo activo, distancia, ritmo medio
(min/km) o velocidad media (km/h) según la actividad, velocidad instantánea y desnivel
positivo, actualizados al menos una vez por segundo. Cuando exista al menos una posición,
SHALL mostrar también el mapa de la traza sin que impida pausar o finalizar.

#### Scenario: Grabación de carrera

- **WHEN** hay una grabación de «Correr» en curso
- **THEN** la pantalla muestra el ritmo en min/km y la distancia en kilómetros

#### Scenario: Grabación de bicicleta

- **WHEN** hay una grabación de «Bicicleta» en curso
- **THEN** la pantalla muestra la velocidad en km/h

#### Scenario: Grabación con mapa

- **WHEN** hay una grabación con posiciones
- **THEN** se ven el mapa y las estadísticas en vivo, y los controles siguen disponibles
