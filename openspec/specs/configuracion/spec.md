# configuracion Specification

## Purpose
Preferencias persistentes de la app y pantalla de ajustes.

## Requirements

### Requirement: Preferencias persistentes

La app SHALL recordar el tema (sistema, claro u oscuro), el proveedor de mapas
(OpenStreetMap, OpenTopoMap, CyclOSM o sin mapas), la carpeta de exportación, el perfil
de calidad GPS (Ahorro, Equilibrada o Máxima) y los parciales (por distancia o por tiempo
y su paso) entre arranques; los valores por defecto SHALL ser tema del sistema,
OpenStreetMap, sin carpeta, Equilibrada y parciales cada 1 km.

#### Scenario: Cambiar el tema

- **WHEN** el usuario elige Oscuro en Ajustes
- **THEN** la app cambia inmediatamente y conserva la elección al reiniciar

#### Scenario: Cambiar el proveedor de mapas

- **WHEN** el usuario elige OpenTopoMap en Ajustes
- **THEN** el mapa usa OpenTopoMap y la elección se conserva al reiniciar

#### Scenario: Cambiar el perfil GPS

- **WHEN** el usuario elige Máxima en Ajustes
- **THEN** la siguiente grabación usa el perfil Máxima y la elección se conserva al
  reiniciar

#### Scenario: Cambiar los parciales

- **WHEN** el usuario elige parciales cada 5 minutos
- **THEN** el detalle usa ese paso y la elección se conserva al reiniciar

#### Scenario: Primera apertura

- **WHEN** no hay preferencias guardadas
- **THEN** la app usa el tema del sistema, OpenStreetMap, sin carpeta, el perfil
  Equilibrada y parciales cada 1 km

#### Scenario: Valor guardado inválido

- **WHEN** la preferencia guardada no es un modo o un paso admitido
- **THEN** la app usa parciales cada 1 km sin romper el arranque

### Requirement: Pantalla de Ajustes

Ajustes SHALL permitir cambiar el tema, elegir el proveedor de mapas o desactivarlos,
elegir o quitar la carpeta de exportación, elegir el perfil de calidad GPS (Ahorro,
Equilibrada o Máxima) con una explicación del intercambio entre precisión y batería,
elegir los parciales (por distancia o por tiempo y su paso) y abrir la pantalla Acerca de,
con textos en español y sin opciones que no funcionen.

#### Scenario: Quitar la carpeta

- **WHEN** el usuario pulsa quitar la carpeta
- **THEN** la app olvida la URI y las siguientes exportaciones piden elegir una de nuevo

#### Scenario: Acerca de

- **WHEN** el usuario pulsa «Acerca de…»
- **THEN** se abre la pantalla informativa

#### Scenario: Elegir perfil GPS

- **WHEN** el usuario abre la sección GPS y elige Máxima
- **THEN** el perfil queda seleccionado y el texto explica que registra más puntos y
  puede consumir más batería

#### Scenario: Perfil por defecto

- **WHEN** el usuario abre Ajustes sin haber elegido perfil
- **THEN** aparece seleccionado Equilibrada

#### Scenario: Elegir parciales

- **WHEN** el usuario abre la sección Parciales, elige Por tiempo y 5 minutos
- **THEN** la preferencia queda guardada y el siguiente detalle usa tramos de 5 min

#### Scenario: Parciales por defecto

- **WHEN** el usuario abre Ajustes sin haber elegido parciales
- **THEN** aparece «Cada 1 km» y el detalle usa parciales por kilómetro

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
