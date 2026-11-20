# Spec Delta

## Purpose

Preferencias de mapas y acceso a la información de la app.

## MODIFIED Requirements

### Requirement: Preferencias persistentes

La app SHALL recordar el tema (sistema, claro u oscuro), el proveedor de mapas
(OpenStreetMap, OpenTopoMap, CyclOSM o sin mapas) y la carpeta de exportación entre
arranques; los valores por defecto SHALL ser tema del sistema, OpenStreetMap y sin
carpeta.

#### Scenario: Cambiar el tema

- **WHEN** el usuario elige Oscuro en Ajustes
- **THEN** la app cambia inmediatamente y conserva la elección al reiniciar

#### Scenario: Cambiar el proveedor de mapas

- **WHEN** el usuario elige OpenTopoMap en Ajustes
- **THEN** el mapa usa OpenTopoMap y la elección se conserva al reiniciar

#### Scenario: Primera apertura

- **WHEN** no hay preferencias guardadas
- **THEN** la app usa el tema del sistema, OpenStreetMap y muestra que no hay carpeta de
  exportación

### Requirement: Pantalla de Ajustes

Ajustes SHALL permitir cambiar el tema, elegir el proveedor de mapas o desactivarlos,
elegir o quitar la carpeta de exportación, y abrir la pantalla Acerca de, con textos en
español y sin opciones que no funcionen.

#### Scenario: Quitar la carpeta

- **WHEN** el usuario pulsa quitar la carpeta
- **THEN** la app olvida la URI y las siguientes exportaciones piden elegir una de nuevo

#### Scenario: Acerca de

- **WHEN** el usuario pulsa «Acerca de…»
- **THEN** se abre la pantalla informativa

## ADDED Requirements

### Requirement: Exención de optimización de batería

Ajustes SHALL mostrar si la app está exenta de la optimización de batería del sistema y
SHALL permitir solicitar la exención. El estado SHALL actualizarse al volver a la app y
SHALL explicar que mejora la grabación con la pantalla apagada a cambio de más consumo.

#### Scenario: Sistema optimiza la app

- **WHEN** el usuario abre Ajustes y Android no tiene la app exenta
- **THEN** se muestra «Optimizado por el sistema» y un botón para permitir sin
  restricciones

#### Scenario: Exención concedida

- **WHEN** el usuario concede la exención y vuelve a la app
- **THEN** Ajustes muestra que la grabación no será limitada

#### Scenario: Plataforma sin el canal

- **WHEN** el estado de batería no está disponible
- **THEN** Ajustes lo indica sin romper la pantalla
