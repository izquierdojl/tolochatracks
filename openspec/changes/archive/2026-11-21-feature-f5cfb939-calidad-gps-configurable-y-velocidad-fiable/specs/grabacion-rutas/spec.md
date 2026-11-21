# Spec Delta

## MODIFIED Requirements

### Requirement: Calidad de los puntos y distancia

La app SHALL descartar las posiciones cuya precisión supere el umbral del perfil GPS
seleccionado (40, 30 o 20 m), ignorar los saltos incompatibles con la velocidad máxima
plausible de la actividad y calcular la distancia con Haversine. La distancia y el
desnivel SHALL acumularse en el SI y filtrar el ruido con umbrales razonables. Los puntos
descartados SHALL NOT formar parte de la ruta, el mapa ni la exportación.

#### Scenario: Punto con mala precisión

- **WHEN** llega una posición con precisión superior al umbral del perfil
- **THEN** no se añade a la ruta ni suma distancia y no aparece en el mapa ni en el GPX

#### Scenario: Salto imposible de GPS

- **WHEN** dos posiciones consecutivas implican una velocidad superior a la máxima
  plausible de la actividad (30 km/h al correr, 12 al caminar, 80 en bicicleta)
- **THEN** ese segmento no suma distancia

#### Scenario: Precisión aceptable

- **WHEN** el perfil es Equilibrada y llega una posición de 25 m de precisión
- **THEN** se acepta y suma distancia

#### Scenario: Perfil de ahorro

- **WHEN** el perfil es Ahorro y llega una posición de 35 m de precisión
- **THEN** se acepta, porque su umbral es 40 m

### Requirement: Estadísticas en vivo

Durante la grabación, la pantalla SHALL mostrar tiempo activo, distancia, ritmo medio
(min/km) o velocidad media (km/h) según la actividad, velocidad instantánea y desnivel
positivo, actualizados al menos una vez por segundo. La velocidad instantánea SHALL usar
la velocidad reportada por el GPS cuando exista y la derivada como respaldo. Cuando
exista al menos una posición, SHALL mostrar también el mapa de la traza sin que impida
pausar o finalizar.

#### Scenario: Grabación de carrera

- **WHEN** hay una grabación de «Correr» en curso
- **THEN** la pantalla muestra el ritmo en min/km y la distancia en kilómetros

#### Scenario: Grabación de bicicleta

- **WHEN** hay una grabación de «Bicicleta» en curso
- **THEN** la pantalla muestra la velocidad en km/h

#### Scenario: Grabación con mapa

- **WHEN** hay una grabación con posiciones
- **THEN** se ven el mapa y las estadísticas en vivo, y los controles siguen disponibles

#### Scenario: Velocidad reportada

- **WHEN** el GPS reporta 3,8 km/h y la distancia entre dos posiciones implicaría 52,5
  km/h
- **THEN** la velocidad instantánea usa el valor reportado y no el salto de posición

#### Scenario: Sin velocidad reportada

- **WHEN** el GPS no entrega velocidad
- **THEN** la velocidad instantánea usa la velocidad derivada de las posiciones

## ADDED Requirements

### Requirement: Calentamiento de la señal

Al iniciar una grabación y al reanudar tras una pausa, la app SHALL descartar para
distancia y velocidad las posiciones de los primeros 5 segundos o hasta disponer de dos
posiciones consecutivas con precisión aceptable, lo que ocurra antes. El primer punto
aceptado SHALL marcar el inicio del segmento; el tiempo activo SHALL seguir contando.

#### Scenario: Arranque con posiciones imprecisas

- **WHEN** las primeras posiciones tienen 25 m de precisión con el perfil Equilibrada
- **THEN** se descartan, la distancia sigue en cero y la ruta empieza en la primera
  posición aceptada

#### Scenario: Reanudación tras pausa

- **WHEN** la primera posición tras una pausa reporta 33,9 km/h y la siguiente 21,4 km/h
- **THEN** no se usan para la velocidad y el segmento empieza en la primera posición
  aceptada después del calentamiento

#### Scenario: Señal buena desde el principio

- **WHEN** las dos primeras posiciones tienen precisión aceptable
- **THEN** el calentamiento termina en la segunda y la ruta empieza sin esperar los 5 s

### Requirement: Indicador de precisión

La pantalla de grabación SHALL mostrar la precisión del último punto válido en metros y
SHALL avisar de señal débil cuando esa precisión supere el umbral del perfil o pasen más
de 5 segundos sin un punto válido. El aviso SHALL desaparecer en cuanto llegue un punto
válido.

#### Scenario: Precisión buena

- **WHEN** el último punto válido tiene 8 m de precisión
- **THEN** la pantalla muestra «±8 m» sin el aviso de señal débil

#### Scenario: Precisión débil

- **WHEN** el último punto válido tiene 35 m de precisión con el perfil Equilibrada
- **THEN** la pantalla muestra el aviso de señal débil

#### Scenario: Sin puntos recientes

- **WHEN** pasan más de 5 segundos sin un punto válido
- **THEN** la pantalla muestra el aviso de señal débil y lo retira al llegar el siguiente
  punto válido
