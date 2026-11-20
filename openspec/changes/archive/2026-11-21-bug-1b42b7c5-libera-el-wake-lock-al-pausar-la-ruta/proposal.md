# Proposal

## Why

El wake lock del servicio de grabación se mantenía adquirido también durante las pausas.
La captura de ubicación y el cronómetro están detenidos en pausa, así que mantener el CPU
despierto solo consume batería sin aportar nada. Es una regresión de eficiencia detectada
al revisar el comportamiento en segundo plano.

## What Changes

- Liberar el `PARTIAL_WAKE_LOCK` al pausar y al preparar el guardado desde la notificación.
- Volver a adquirirlo al reanudar o al iniciar el servicio.
- No cambiar el comportamiento visible ni el formato de las sesiones.
- Documentar en el README que no se debe cerrar la app desde Recientes mientras graba.

## Capabilities

### New Capabilities

_(ninguna: corrección de eficiencia sin cambio de requisitos)_

### Modified Capabilities

_(ninguna)_

## Impact

- `RutaForegroundService.kt`.
- README (nota de uso).
- Sin dependencias ni cambios de permisos.

## Fuera de alcance

- Cambiar la precisión o el intervalo del GPS (ya ajustados en el change anterior).
- Servicios nativos de ubicación independientes de Flutter.
