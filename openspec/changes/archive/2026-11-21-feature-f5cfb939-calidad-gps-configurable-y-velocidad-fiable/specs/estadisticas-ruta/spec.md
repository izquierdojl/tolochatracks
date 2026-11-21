# Spec Delta

## ADDED Requirements

### Requirement: Velocidad en las series

La serie de velocidad SHALL usar la velocidad reportada por el GPS cuando exista y la
derivada como respaldo, sin dibujar un pico derivado de un solo punto. Si no hay
velocidad reportada, SHALL usar una ventana temporal de 10 a 15 segundos. La serie SHALL
NOT incluir el primer punto de un segmento, los 5 segundos posteriores a su inicio ni los
puntos descartados.

#### Scenario: Velocidad reportada frente a salto de posición

- **WHEN** un punto reporta 3,8 km/h y la distancia entre posiciones implicaría 52,5 km/h
- **THEN** la serie usa el valor reportado y no el pico derivado

#### Scenario: Sin velocidad reportada

- **WHEN** los puntos no tienen velocidad del GPS
- **THEN** la serie usa una ventana temporal, no un salto de un solo punto

#### Scenario: Primeros segundos de un segmento

- **WHEN** una pausa abre un segmento nuevo
- **THEN** la serie no genera una muestra de velocidad con el salto entre segmentos ni con
  los primeros 5 segundos del segmento

### Requirement: Velocidad máxima fiable

La app SHALL calcular la velocidad máxima con la velocidad reportada por el GPS cuando
exista, combinada con la derivada sin superar la menor de ambas, y acotada por la
velocidad máxima plausible de la actividad. Si no hay velocidad reportada, SHALL usar una
ventana temporal de 10 a 15 segundos. La velocidad máxima SHALL NOT incluir el primer
punto de un segmento, los 5 segundos posteriores a su inicio ni los puntos descartados.

#### Scenario: Pico de posición con velocidad reportada baja

- **WHEN** la velocidad derivada es 52,5 km/h y la reportada es 3,8 km/h
- **THEN** la velocidad máxima no supera el valor reportado

#### Scenario: Sin velocidad reportada

- **WHEN** la sesión no tiene velocidad del GPS
- **THEN** la velocidad máxima se calcula con una ventana y no con un único salto

#### Scenario: Primeros segundos tras una pausa

- **WHEN** el primer punto de un segmento reporta 33,9 km/h y el siguiente 21,4 km/h
- **THEN** esas velocidades no se tienen en cuenta para el máximo

#### Scenario: Salto por encima de la actividad

- **WHEN** una sesión de «Correr» implica más de 30 km/h o una de «Bicicleta» más de 80
  km/h
- **THEN** ese segmento no se usa para la velocidad máxima

#### Scenario: Punto descartado

- **WHEN** un punto se descarta por precisión o por salto
- **THEN** no influye en la velocidad máxima
