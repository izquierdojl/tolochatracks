# configuracion Specification

## Purpose
Preferencias persistentes de la app y pantalla de ajustes.

## Requirements

### Requirement: Preferencias persistentes

La app SHALL recordar el tema (sistema, claro u oscuro) y la carpeta de exportación entre
arranques; los valores por defecto SHALL ser tema del sistema y sin carpeta.

#### Scenario: Cambiar el tema

- **WHEN** el usuario elige Oscuro en Ajustes
- **THEN** la app cambia inmediatamente y conserva la elección al reiniciar

#### Scenario: Primera apertura

- **WHEN** no hay preferencias guardadas
- **THEN** la app usa el tema del sistema y muestra que no hay carpeta de exportación

### Requirement: Pantalla de Ajustes

Ajustes SHALL permitir cambiar el tema, elegir o quitar la carpeta de exportación y
mostrar su nombre, con textos en español y sin opciones que no funcionen.

#### Scenario: Quitar la carpeta

- **WHEN** el usuario pulsa quitar la carpeta
- **THEN** la app olvida la URI y las siguientes exportaciones piden elegir una de nuevo
