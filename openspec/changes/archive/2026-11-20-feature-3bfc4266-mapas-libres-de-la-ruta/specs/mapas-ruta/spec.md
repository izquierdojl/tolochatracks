# Spec Delta

## Purpose

Muestra la ruta sobre teselas libres de OpenStreetMap sin comprometer la privacidad ni la
grabación cuando no hay conexión.

## ADDED Requirements

### Requirement: Mapa de la ruta

La app SHALL dibujar la traza de una sesión sobre un mapa de teselas libres de
OpenStreetMap, con marcadores de inicio y fin y una polilínea que respete el orden de los
puntos.

#### Scenario: Ruta con varios puntos

- **WHEN** el usuario abre el detalle de una sesión con al menos dos puntos
- **THEN** el mapa encuadra la traza completa y muestra los marcadores de inicio y fin

#### Scenario: Ruta de un solo punto

- **WHEN** la sesión tiene un único punto
- **THEN** el mapa se centra en ese punto con un zoom cercano y muestra el marcador

#### Scenario: Sin puntos

- **WHEN** la sesión no tiene puntos
- **THEN** el área del mapa muestra un aviso en español y no intenta cargar teselas

### Requirement: Mapa durante la grabación

La pantalla de grabación SHALL mostrar el mapa con los puntos capturados en cuanto exista
al menos una posición; mientras se graba, SHALL seguir el último punto.

#### Scenario: Primer punto capturado

- **WHEN** llega la primera posición válida durante una grabación
- **THEN** aparece el mapa centrado en esa posición y se añade el marcador actual

#### Scenario: Nuevos puntos

- **WHEN** la grabación recibe puntos nuevos
- **THEN** la polilínea se actualiza y el mapa sigue el punto actual sin bloquear los
  controles de pausa y finalización

### Requirement: Atribución de OpenStreetMap

Toda vista con teselas SHALL mostrar la atribución «© OpenStreetMap contributors» de
forma visible y enlazada a la página de copyright, y SHALL identificar la app con su
propio `userAgentPackageName` en las peticiones de teselas.

#### Scenario: Atribución visible

- **WHEN** se muestra un mapa con teselas
- **THEN** la atribución de OpenStreetMap está visible sobre el mapa y se puede abrir su
  página de copyright

### Requirement: Funcionamiento sin conexión

El mapa SHALL ser una capa opcional: si las teselas no cargan, la polilínea y el resto de
la app SHALL seguir funcionando. No se SHALL descargar mapas en bloque ni enviar la ruta
a ningún servidor propio.

#### Scenario: Sin red

- **WHEN** el dispositivo no tiene conexión y se abre el detalle
- **THEN** la pantalla sigue mostrando estadísticas y parciales, con la traza disponible y
  un aviso de que el mapa necesita conexión
