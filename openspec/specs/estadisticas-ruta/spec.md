# estadisticas-ruta Specification

## Purpose
Convierte los puntos GPS de una sesión en series y parciales comprensibles, sin red y
sin depender de la pantalla, para que el detalle explique cómo fue la ruta.

## Requirements

### Requirement: Series de la ruta

La app SHALL calcular, a partir de los puntos válidos de una sesión, series de distancia
acumulada frente a tiempo, velocidad frente a distancia, velocidad frente a tiempo, altitud
frente a distancia y altitud frente a tiempo. Las series SHALL estar ordenadas, sin valores
no finitos y usar unidades del SI internamente (metros, segundos y m/s). El eje de tiempo
SHALL ser tiempo activo y SHALL NOT incluir los huecos de pausa; la distancia SHALL NOT
sumar el tramo entre segmentos.

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

#### Scenario: Eje de tiempo en velocidad y altitud

- **WHEN** el usuario elige el eje X «Tiempo» para Velocidad o Altitud
- **THEN** las series usan minutos de tiempo activo y no la distancia acumulada

### Requirement: Gráficos en el detalle

La pantalla de detalle SHALL ofrecer gráficos conmutables con dos selectores: métrica
(Distancia, Velocidad, Altitud o Por minuto) y eje X (Tiempo o Distancia), sin bloquear el
resto de la pantalla. Las combinaciones SHALL ser distancia-tiempo, velocidad-tiempo,
velocidad-distancia, altitud-tiempo y altitud-distancia; «Por minuto» SHALL ocultar el eje
X y elegir Distancia SHALL fijarlo en Tiempo. El cambio SHALL ser inmediato y conservar el
resto de estadísticas.

#### Scenario: Cambiar de métrica

- **WHEN** el usuario elige Velocidad en el selector de métrica
- **THEN** se muestra el gráfico de velocidad y las demás cifras no cambian

#### Scenario: Cambiar el eje X

- **WHEN** el usuario elige Altitud y Tiempo
- **THEN** se muestra la altitud frente al tiempo activo y las demás cifras no cambian

#### Scenario: Distancia fija el tiempo

- **WHEN** el usuario elige Distancia como métrica
- **THEN** el eje X queda fijado en Tiempo y no se puede elegir Distancia

#### Scenario: Por minuto

- **WHEN** el usuario elige Por minuto
- **THEN** se dibujan barras por minuto y el selector de eje X se oculta

#### Scenario: Sin datos para una métrica

- **WHEN** la métrica o la combinación seleccionada no tiene muestras
- **THEN** se muestra un mensaje en español en el área del gráfico

### Requirement: Escalas de los gráficos

Las gráficas de distancia, velocidad y metros por minuto SHALL empezar en 0; la de altitud
SHALL incluir margen por arriba y por abajo. Ninguna SHALL mostrar marcas negativas cuando
los datos no sean negativos y las etiquetas SHALL quedar visibles.

#### Scenario: Eje de distancia

- **WHEN** se dibuja la distancia acumulada
- **THEN** el eje vertical empieza en 0 y no muestra marcas negativas

#### Scenario: Eje de altitud

- **WHEN** se dibuja la altitud
- **THEN** el eje incluye margen por arriba y por abajo para que la línea no toque el borde

#### Scenario: Etiquetas visibles

- **WHEN** se dibuja cualquier gráfico
- **THEN** las etiquetas de los ejes quedan dentro del área visible

### Requirement: Parciales por distancia

Con la configuración por distancia, la app SHALL dividir la ruta en tramos de 100 m, 200 m,
500 m, 1 km, 5 km o 10 km. Cada tramo SHALL tener distancia, duración de tiempo activo y
velocidad media. El último tramo incompleto SHALL mostrarse si supera 20 m. La distancia
SHALL NOT sumar el salto entre segmentos.

#### Scenario: Ruta de 2,5 km cada 500 m

- **WHEN** la ruta tiene 2.500 metros y el paso es de 500 m
- **THEN** se muestran cinco parciales de 500 m

#### Scenario: Ruta de 2,5 km cada 100 m

- **WHEN** la ruta tiene 2.500 metros y el paso es de 100 m
- **THEN** se muestran veinticinco parciales de 100 m

#### Scenario: Pausa dentro de un parcial

- **WHEN** una pausa ocurre dentro de un tramo
- **THEN** la duración excluye la pausa y la distancia no incluye el desplazamiento hecho
  durante ella

#### Scenario: Último tramo incompleto

- **WHEN** tras el último corte quedan 519 m
- **THEN** se muestra un tramo final de 519 m marcado como incompleto

#### Scenario: Resto demasiado corto

- **WHEN** tras el último corte quedan 20 m o menos
- **THEN** no se muestra un tramo final

#### Scenario: Ruta corta

- **WHEN** la ruta tiene menos de 20 metros
- **THEN** no se muestran parciales y se indica que no hay distancia suficiente

### Requirement: Parciales por tiempo

Con la configuración por tiempo, la app SHALL dividir la ruta en tramos de 1, 5, 10, 15,
20, 30, 45 o 60 minutos de tiempo activo. Las pausas SHALL NOT contar ni crear tramos. Cada
tramo SHALL tener distancia, duración y velocidad media. El último tramo incompleto SHALL
mostrarse si dura al menos 10 s.

#### Scenario: Ruta de 15 minutos cada 5 minutos

- **WHEN** la ruta dura 15 minutos activos y el paso es de 5 min
- **THEN** se muestran tres parciales de 5 min

#### Scenario: Pausa dentro de un parcial

- **WHEN** una pausa ocurre dentro de un tramo de tiempo
- **THEN** la pausa no cuenta para el tramo ni crea uno nuevo

#### Scenario: Último tramo incompleto

- **WHEN** tras el último corte quedan 4 minutos
- **THEN** se muestra un tramo final de 4 min marcado como incompleto

#### Scenario: Resto demasiado corto

- **WHEN** tras el último corte quedan menos de 10 s
- **THEN** no se muestra un tramo final

#### Scenario: Ruta corta

- **WHEN** la ruta tiene menos de 10 segundos activos
- **THEN** no se muestran parciales y se indica que no hay tiempo suficiente

### Requirement: Altitud de los parciales

Cada parcial SHALL incluir la altitud media de los puntos válidos con altitud que caen
dentro del tramo. Si el tramo no tiene ninguno, la altitud SHALL ser nula y la tabla SHALL
mostrar «—». Si ningún parcial tiene altitud, la columna SHALL omitirse.

#### Scenario: Ruta con altitudes

- **WHEN** los puntos del tramo tienen altitud
- **THEN** el parcial muestra la media de esas altitudes en metros

#### Scenario: Ruta sin altitudes

- **WHEN** ningún punto de la ruta tiene altitud
- **THEN** la tabla no muestra la columna de altitud

#### Scenario: Tramo sin altitud

- **WHEN** un tramo concreto no tiene puntos con altitud
- **THEN** su celda de altitud muestra «—» y el resto de la tabla sigue funcionando

### Requirement: Tabla de parciales

La tabla SHALL mostrar las columnas Tramo, Tiempo, Ritmo o Velocidad, Altitud y Destacado,
con la unidad en la cabecera. Las etiquetas SHALL ser compactas: «Km 1», «100 m», «5 min» y
«Final». El último tramo SHALL mostrar su distancia o duración real. La tabla SHALL NOT
desbordar a 360 dp y, con más de diez parciales, SHALL mostrar diez y un control para ver
el resto.

#### Scenario: Etiquetas compactas

- **WHEN** el paso es de 1 km, 100 m o 5 min
- **THEN** las filas usan «Km 1», «100 m» o «5 min» en lugar de «Kilómetro 1» y similares

#### Scenario: Unidades en la cabecera

- **WHEN** se muestra la tabla
- **THEN** las cabeceras indican la unidad y las celdas no repiten «/km» ni «km/h»

#### Scenario: Último tramo

- **WHEN** el último tramo es incompleto
- **THEN** se identifica como «Final» y muestra debajo su distancia o duración real

#### Scenario: Pantalla estrecha

- **WHEN** la tabla se muestra en un ancho de 360 dp
- **THEN** no hay desbordamiento y la altitud sigue visible

#### Scenario: Ruta con muchos parciales

- **WHEN** la configuración produce más de diez parciales
- **THEN** se muestran diez y un control «Ver los N restantes»

#### Scenario: Sin parciales

- **WHEN** la ruta no alcanza el mínimo de distancia o de tiempo
- **THEN** la tabla lo explica en español sin mostrar filas vacías

### Requirement: Comparación visual de parciales

Cada fila SHALL incluir una barra horizontal proporcional a la velocidad media del tramo,
con la misma escala y alineada con la fila; el valor numérico SHALL seguir visible y la
barra SHALL ser decorativa. La app SHALL marcar el más rápido y el más lento solo entre
tramos completos, con al menos tres, combinando icono y texto accesible.

#### Scenario: Una barra por fila

- **WHEN** se muestra la tabla
- **THEN** cada parcial tiene su barra, con la misma escala que las demás

#### Scenario: Más rápido y más lento

- **WHEN** hay al menos tres tramos completos con velocidades distintas
- **THEN** el de mayor velocidad y el de menor se marcan con icono y descripción accesible

#### Scenario: El último tramo no compite

- **WHEN** el último tramo es incompleto
- **THEN** nunca recibe la marca de más rápido ni la de más lento

#### Scenario: Menos de tres tramos

- **WHEN** hay menos de tres tramos completos
- **THEN** no se marca ninguno

#### Scenario: Empate

- **WHEN** dos o más tramos comparten la velocidad máxima o la mínima
- **THEN** se marcan todos los empatados en esa posición

#### Scenario: Sin movimiento

- **WHEN** ningún tramo tiene velocidad positiva
- **THEN** las barras quedan vacías y no se marca ningún destacado

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
configuración de parciales y quedar disponibles en el detalle.

#### Scenario: Ruta de miles de puntos

- **WHEN** una sesión tiene miles de puntos
- **THEN** el detalle sigue siendo fluido y los gráficos conservan la forma general de
  la ruta

#### Scenario: Cambiar la configuración de parciales

- **WHEN** el usuario cambia los parciales de 1 km a 5 min
- **THEN** la tabla y los destacados se recalculan sin salir del detalle

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
