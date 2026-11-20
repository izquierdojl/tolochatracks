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
capturando puntos con la pantalla apagada o la app en segundo plano.

#### Scenario: App en segundo plano

- **WHEN** el usuario cambia de app o apaga la pantalla durante una grabación
- **THEN** la notificación de grabación sigue visible y la captura de posiciones continúa

### Requirement: Calidad de los puntos y distancia

La app SHALL descartar posiciones con precisión peor que 100 metros, ignorar saltos
incompatibles con la velocidad humana y calcular la distancia con la fórmula de
Haversine. La distancia y el desnivel SHALL acumularse en unidades del SI y filtrar el
ruido con umbrales razonables.

#### Scenario: Punto con mala precisión

- **WHEN** llega una posición con precisión superior a 100 metros
- **THEN** no se añade a la ruta ni suma distancia

#### Scenario: Salto imposible de GPS

- **WHEN** dos posiciones consecutivas implican una velocidad superior a 200 km/h
- **THEN** ese segmento no suma distancia

### Requirement: Estadísticas en vivo

Durante la grabación, la pantalla SHALL mostrar tiempo activo, distancia, ritmo medio
(min/km) o velocidad media (km/h) según la actividad, velocidad instantánea y desnivel
positivo, actualizados al menos una vez por segundo.

#### Scenario: Grabación de carrera

- **WHEN** hay una grabación de «Correr» en curso
- **THEN** la pantalla muestra el ritmo en min/km y la distancia en kilómetros

#### Scenario: Grabación de bicicleta

- **WHEN** hay una grabación de «Bicicleta» en curso
- **THEN** la pantalla muestra la velocidad en km/h

### Requirement: Pausa y reanudación

La app SHALL permitir pausar y reanudar una grabación sin perder los puntos ni la
distancia acumulada. El tiempo activo SHALL excluir los periodos en pausa.

#### Scenario: Pausa

- **WHEN** el usuario pausa la grabación
- **THEN** dejan de capturarse posiciones, el tiempo activo se detiene y la distancia no
  cambia

#### Scenario: Reanudación

- **WHEN** el usuario reanuda la grabación
- **THEN** la captura continúa desde la última posición y el tiempo activo vuelve a contar

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
