# grabacion-rutas Specification

## Purpose
Permite capturar una ruta GPS con la mínima interacción posible, guardarla en el
dispositivo y no perderla si la app se interrumpe. Es la base del historial y de las
estadísticas.

## Requirements

### Requirement: Inicio rápido de una grabación

La app SHALL permitir iniciar una grabación en un solo paso desde la pantalla principal,
con una actividad seleccionada (correr, caminar, senderismo, bicicleta u otras) y sin
pedir datos adicionales.

#### Scenario: Inicio con actividad por defecto

- **WHEN** el usuario abre la app y pulsa el botón de grabar
- **THEN** la grabación comienza con la actividad seleccionada (Correr por defecto) y el
  tiempo empieza a contar

#### Scenario: Cambio de actividad antes de empezar

- **WHEN** el usuario elige otra actividad con la grabación inactiva
- **THEN** la siguiente grabación usa esa actividad y el cambio se refleja en la pantalla

### Requirement: Permiso de ubicación bajo demanda

La app SHALL solicitar el permiso de ubicación solo al iniciar la primera grabación y
SHALL explicar en español el motivo. Si el permiso se deniega o el servicio de ubicación
está desactivado, SHALL mostrar un mensaje accionable y no iniciar la grabación.

#### Scenario: Permiso concedido

- **WHEN** el usuario concede el permiso de ubicación al pulsar grabar
- **THEN** la app empieza a recibir posiciones y muestra el estado «Buscando señal GPS»
  hasta la primera posición válida

#### Scenario: Permiso denegado

- **WHEN** el usuario deniega el permiso de ubicación
- **THEN** la app permanece inactiva, muestra un aviso en español y ofrece abrir los
  ajustes del sistema cuando la denegación es permanente

#### Scenario: GPS desactivado

- **WHEN** la ubicación del dispositivo está desactivada
- **THEN** la app no inicia la grabación y ofrece abrir los ajustes de ubicación

### Requirement: Grabación con pantalla apagada

Mientras hay una grabación activa, la app SHALL usar un servicio en primer plano con una
notificación persistente que indique que la ubicación se está usando, para seguir
capturando puntos con la pantalla apagada o la app en segundo plano. En Android 13 o
superior SHALL solicitar el permiso de notificaciones al iniciar la primera grabación; si
se deniega, la grabación SHALL continuar sin bloquearse y se informará de que la
notificación puede no ser visible.

#### Scenario: App en segundo plano

- **WHEN** el usuario cambia de app o apaga la pantalla durante una grabación
- **THEN** la notificación de grabación sigue visible y la captura de posiciones continúa

#### Scenario: Permiso de notificaciones denegado

- **WHEN** el usuario deniega el permiso de notificaciones
- **THEN** la grabación continúa y la app explica que la notificación del servicio puede
  no mostrarse

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

### Requirement: Pausa y reanudación

La app SHALL permitir pausar y reanudar una grabación sin perder los puntos ni la
distancia acumulada. El tiempo activo SHALL excluir los periodos en pausa. Al reanudar
SHALL comenzar un segmento nuevo: la distancia, la velocidad y la traza SHALL NO cruzar
el hueco de la pausa.

#### Scenario: Pausa

- **WHEN** el usuario pausa la grabación
- **THEN** dejan de capturarse posiciones, el tiempo activo se detiene y la distancia no
  cambia

#### Scenario: Reanudación

- **WHEN** el usuario reanuda la grabación
- **THEN** la captura continúa en un segmento nuevo, el tiempo activo vuelve a contar y no
  se suma la distancia recorrida durante la pausa

#### Scenario: Movimiento durante la pausa

- **WHEN** el usuario se desplaza mientras la grabación está en pausa y después reanuda
- **THEN** ese desplazamiento no se suma a la distancia activa, no genera velocidad y no
  aparece como una línea recta entre los extremos de la pausa

### Requirement: Finalización y guardado local

Al finalizar, la app SHALL guardar la sesión de forma atómica en el registro interno
(documentos de la app, una sesión por archivo JSON versionado) antes de confirmar el
resultado. Una sesión sin posiciones SHALL descartarse con un aviso, sin crear archivos
vacíos.

#### Scenario: Finalización correcta

- **WHEN** el usuario finaliza una grabación con al menos una posición válida
- **THEN** se escribe el archivo JSON de la sesión y se muestra un resumen con distancia,
  tiempo y actividad

#### Scenario: Grabación sin señal

- **WHEN** el usuario finaliza sin ninguna posición válida
- **THEN** la app avisa de que no hay ruta que guardar y no crea una sesión

#### Scenario: Fallo al guardar

- **WHEN** el guardado local falla
- **THEN** la app muestra un error, conserva el borrador y permite reintentar

### Requirement: Borrador recuperable

Mientras hay una grabación activa, la app SHALL autoguardar un borrador periódicamente.
Al abrir la app, si existe un borrador, SHALL ofrecer recuperar la sesión o descartarla.

#### Scenario: Cierre inesperado

- **WHEN** la app se cierra durante una grabación y se vuelve a abrir
- **THEN** se muestra un aviso con la fecha y la actividad del borrador y las opciones
  Recuperar y Descartar

#### Scenario: Recuperar

- **WHEN** el usuario pulsa Recuperar
- **THEN** la sesión vuelve en estado pausado, con sus puntos, distancia y tiempo activo,
  y puede reanudarse o finalizarse

### Requirement: Estados de señal y errores

La pantalla SHALL indicar «Buscando señal GPS» cuando no hay posiciones recientes
(>15 segundos) y SHALL permitir finalizar o pausar sin bloquearse. Los errores del
servicio de ubicación SHALL mostrarse en español con acción de reintento o ajustes.

#### Scenario: Pérdida de señal

- **WHEN** pasan más de 15 segundos sin una posición válida durante la grabación
- **THEN** se muestra el aviso de búsqueda de señal y la grabación sigue activa

#### Scenario: Error del servicio

- **WHEN** el flujo de posiciones emite un error
- **THEN** la app muestra un mensaje en español y permite reintentar sin perder los puntos

### Requirement: Controles desde la notificación

La notificación del servicio en primer plano SHALL mostrar acciones para pausar o
reanudar la grabación y para finalizarla. Las acciones SHALL afectar al mismo estado que
los botones de la app y, al finalizar, SHALL guardar la sesión antes de retirar la
notificación. Tocar la notificación SHALL abrir la app.

#### Scenario: Pausar desde la notificación

- **WHEN** la grabación está activa y el usuario pulsa Pausar en la notificación
- **THEN** la captura se pausa, el tiempo activo se detiene y la notificación cambia a
  Reanudar

#### Scenario: Reanudar desde la notificación

- **WHEN** la grabación está en pausa y el usuario pulsa Reanudar
- **THEN** la captura continúa y la notificación vuelve a mostrar Pausar

#### Scenario: Finalizar desde la notificación

- **WHEN** el usuario pulsa Finalizar en la notificación
- **THEN** la sesión se guarda en el registro interno y la notificación se retira

#### Scenario: Abrir la app desde la notificación

- **WHEN** el usuario toca el cuerpo de la notificación
- **THEN** se abre TolochaTracks en la pantalla de grabación

### Requirement: Segmentos de la ruta

La sesión SHALL guardar los cortes entre segmentos de grabación. El primer punto de un
segmento SHALL marcar su inicio sin sumar distancia ni velocidad desde el segmento
anterior. Las sesiones antiguas sin cortes guardados SHALL interpretarse con un corte en
cada hueco superior a 60 segundos, sin modificar el archivo original.

#### Scenario: Sesión con dos pausas

- **WHEN** una sesión se guarda después de dos pausas
- **THEN** conserva tres segmentos y la distancia de cada segmento empieza en cero
  respecto al anterior

#### Scenario: Sesión antigua con un hueco

- **WHEN** se abre una sesión guardada antes de existir los segmentos y tiene un hueco de
  más de 60 segundos
- **THEN** la app la muestra y la exporta con un corte en ese hueco, sin reescribir el
  archivo interno

#### Scenario: Borrador con segmentos

- **WHEN** la app recupera un borrador que tenía pausas
- **THEN** conserva los segmentos y no une los extremos de la pausa

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
