# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
