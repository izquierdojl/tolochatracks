# estadisticas-ruta Specification

## Purpose
Convierte los puntos GPS de una sesión en series y parciales comprensibles, sin red y
sin depender de la pantalla, para que el detalle explique cómo fue la ruta.

## Requirements

### Requirement: Series de la ruta

La app SHALL calcular, a partir de los puntos válidos de una sesión, series de distancia
acumulada frente a tiempo, velocidad frente a distancia y altitud frente a distancia.
Las series SHALL estar ordenadas, sin valores no finitos y usar unidades del SI
internamente (metros, segundos y m/s). El eje de tiempo SHALL ser tiempo activo y SHALL
NOT incluir los huecos de pausa; la distancia SHALL NOT sumar el tramo entre segmentos.

#### Scenario: Ruta con puntos suficientes

- **WHEN** una sesión tiene al menos dos puntos válidos
- **THEN** las series de distancia y velocidad contienen muestras ordenadas y el detalle
  puede dibujarlas

#### Scenario: Ruta sin altitudes

- **WHEN** los puntos no tienen altitud
- **THEN** la serie de altitud queda vacía y el gráfico muestra un aviso en lugar de
  fallar

#### Scenario: Ruta con pausas

- **WHEN** una sesión tiene una pausa y la persona se movió durante ella
- **THEN** la serie de tiempo continúa sin la duración de la pausa y la distancia no da un
  salto entre los extremos

### Requirement: Gráficos en el detalle

La pantalla de detalle SHALL ofrecer gráficos conmutables de Distancia, Velocidad,
Altitud y Por minuto, renderizados sin bloquear el resto de la pantalla. El cambio de
métrica SHALL ser inmediato y conservar el resto de estadísticas.

#### Scenario: Cambiar de métrica

- **WHEN** el usuario pulsa la pestaña Velocidad en el detalle
- **THEN** se muestra el gráfico de velocidad frente a distancia y las demás cifras no
  cambian

#### Scenario: Sin datos para una métrica

- **WHEN** la métrica seleccionada no tiene muestras
- **THEN** se muestra un mensaje en español en el área del gráfico

### Requirement: Parciales por kilómetro

El detalle SHALL mostrar una tabla de parciales calculada por cada kilómetro recorrido,
con el tiempo empleado y el ritmo (min/km) o la velocidad media (km/h) según la
actividad. El tiempo empleado SHALL ser tiempo activo y SHALL NOT incluir las pausas. El
último tramo incompleto SHALL mostrarse si supera los 20 metros.

#### Scenario: Ruta de 2,5 km

- **WHEN** la ruta tiene 2.500 metros
- **THEN** se muestran tres parciales: km 1, km 2 y el tramo final de 500 metros

#### Scenario: Ruta corta

- **WHEN** la ruta tiene menos de 20 metros
- **THEN** no se muestran parciales y se indica que no hay distancia suficiente

#### Scenario: Pausa dentro de un parcial

- **WHEN** una pausa ocurre dentro de un kilómetro
- **THEN** el tiempo de ese parcial excluye la pausa y la distancia no incluye el
  desplazamiento hecho durante ella

### Requirement: Distancia por minuto

La app SHALL calcular los metros recorridos en cada minuto activo de la sesión y SHALL
mostrarlos como un gráfico de barras. Los minutos sin movimiento SHALL aparecer con valor
cero entre el primero y el último minuto con actividad. Los periodos en pausa SHALL NOT
crear minutos ni desplazar la escala.

#### Scenario: Distribución por minutos

- **WHEN** una ruta dura varios minutos
- **THEN** se muestra un minuto por barra, incluidos los minutos intermedios sin
  movimiento

#### Scenario: Pausa intermedia

- **WHEN** la sesión tiene una pausa
- **THEN** la pausa no aparece como minutos con cero metros y los minutos posteriores son
  contiguos a los anteriores

### Requirement: Rendimiento y muestreo

Las series SHALL limitarse a un número máximo de muestras para dibujar rutas largas sin
pérdida perceptible de forma, y los cálculos SHALL realizarse una sola vez por sesión y
quedar disponibles en el detalle.

#### Scenario: Ruta de miles de puntos

- **WHEN** una sesión tiene miles de puntos
- **THEN** el detalle sigue siendo fluido y los gráficos conservan la forma general de
  la ruta

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
