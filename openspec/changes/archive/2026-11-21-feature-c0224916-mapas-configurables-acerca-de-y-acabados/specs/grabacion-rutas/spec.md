# Spec Delta

## Purpose

Permiso de notificaciones del servicio de grabación.

## MODIFIED Requirements

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

## ADDED Requirements

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
