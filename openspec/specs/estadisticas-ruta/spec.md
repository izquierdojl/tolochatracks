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
