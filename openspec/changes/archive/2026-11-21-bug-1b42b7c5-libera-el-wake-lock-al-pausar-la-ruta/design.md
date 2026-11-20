# Design

## Context

El servicio `RutaForegroundService` adquiere un `PARTIAL_WAKE_LOCK` al iniciar la
grabación para que el GPS siga recibiendo con la pantalla apagada. Al pausar se cancela la
suscripción de ubicación y el cronómetro, pero el wake lock seguía activo.

## Decision

- Extraer `actualizarWakeLock()`: adquiere si `!pausado`, libera si `pausado`.
- Llamarlo en `INICIAR`, `ACTUALIZAR`, `PAUSAR`, `REANUDAR` y `DETENER`.
- Liberarlo siempre en `onDestroy`.
- Mantener el timeout de 12 h al adquirir para evitar fugas si el sistema mata el
  servicio de forma anómala.
- Añadir una nota al README: quitar la app de Recientes detiene el servicio (el borrador
  se conserva); para rutas largas, dejar la app en segundo plano y permitir la exención
  de batería.

## Risks / Trade-offs

- Si el usuario reanuda, el wake lock debe volver a adquirirse antes de que el stream
  entregue posiciones; se hace en la acción `REANUDAR` y en la actualización desde Flutter.
- No hay cambio de API ni de datos.
