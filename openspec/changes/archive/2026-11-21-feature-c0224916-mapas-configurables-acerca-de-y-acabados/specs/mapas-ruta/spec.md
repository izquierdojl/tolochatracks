# Spec Delta

## Purpose

Proveedor de teselas y preferencias de mapas.

## MODIFIED Requirements

### Requirement: Mapa de la ruta

La app SHALL dibujar la traza de una sesión sobre un mapa de teselas libres del proveedor
elegido en Ajustes: OpenStreetMap, OpenTopoMap o CyclOSM. Si el usuario elige «Sin
mapas», no se SHALL solicitar ninguna tesela y se mostrará un aviso en el área del mapa.
Los marcadores de inicio y fin y la polilínea SHALL seguir mostrándose cuando haya teselas.

#### Scenario: Ruta con varios puntos

- **WHEN** el usuario abre el detalle de una sesión con al menos dos puntos y un proveedor
  de mapas activo
- **THEN** el mapa encuadra la traza completa y muestra los marcadores de inicio y fin

#### Scenario: Ruta de un solo punto

- **WHEN** la sesión tiene un único punto
- **THEN** el mapa se centra en ese punto con un zoom cercano y muestra el marcador

#### Scenario: Sin puntos

- **WHEN** la sesión no tiene puntos
- **THEN** el área del mapa muestra un aviso en español y no intenta cargar teselas

#### Scenario: Mapas desactivados

- **WHEN** el usuario elige «Sin mapas» en Ajustes
- **THEN** el detalle y la grabación no solicitan teselas y muestran que los mapas están
  desactivados

### Requirement: Atribución de OpenStreetMap

Toda vista con teselas SHALL mostrar la atribución del proveedor elegido de forma visible
y enlazada a su página de licencia, e identificar la app con su propio
`userAgentPackageName` en las peticiones.

#### Scenario: Atribución visible

- **WHEN** se muestra un mapa con teselas
- **THEN** la atribución del proveedor está visible sobre el mapa y se puede abrir su
  página de licencia

#### Scenario: Cambiar de proveedor

- **WHEN** el usuario cambia de OpenStreetMap a OpenTopoMap
- **THEN** las teselas y la atribución cambian al nuevo proveedor sin reiniciar la app
