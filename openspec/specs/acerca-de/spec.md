# acerca-de Specification

## Purpose
Información transparente sobre la app, su versión, privacidad y las licencias de los
datos y mapas que utiliza.

## Requirements

### Requirement: Pantalla Acerca de

La app SHALL mostrar una pantalla «Acerca de» accesible desde Ajustes con el nombre y la
versión de la app, un resumen de privacidad, las atribuciones de los proveedores de mapas
y un enlace al repositorio público.

#### Scenario: Abrir Acerca de

- **WHEN** el usuario pulsa «Acerca de» en Ajustes
- **THEN** se muestra la versión instalada, la política de privacidad y las atribuciones

#### Scenario: Atribución de mapas ampliada

- **WHEN** el usuario consulta las atribuciones
- **THEN** se listan OpenStreetMap (ODbL), OpenTopoMap y CyclOSM con enlaces a sus
  páginas de licencia

### Requirement: Enlace al proyecto

La pantalla SHALL incluir un enlace al repositorio `github.com/izquierdojl/tolochatracks`
y SHALL abrirlo en el navegador sin bloquear la app si no hay navegador.

#### Scenario: Abrir el repositorio

- **WHEN** el usuario pulsa el enlace del proyecto
- **THEN** se abre el repositorio en el navegador externo

### Requirement: Licencia del código

La pantalla SHALL indicar que el código es público en el repositorio y que la tipografía
Inter se distribuye bajo SIL Open Font License 1.1.

#### Scenario: Licencia visible

- **WHEN** el usuario abre Acerca de
- **THEN** puede leer la licencia del código y de la tipografía
