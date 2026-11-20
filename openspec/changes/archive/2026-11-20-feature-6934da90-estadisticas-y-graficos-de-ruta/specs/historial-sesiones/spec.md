# Spec Delta

## MODIFIED Requirements

### Requirement: Detalle de una sesión

Al pulsar una tarjeta, la app SHALL abrir una pantalla con la actividad, la fecha, la
duración y las estadísticas completas calculadas a partir de los puntos: distancia,
tiempo activo, tiempo total, ritmo o velocidad media, velocidad máxima, desnivel positivo
y negativo, altitud mínima y máxima y número de puntos. El detalle SHALL incluir además
una tarjeta de gráficos conmutables (Distancia, Velocidad, Altitud y Por minuto) y una
tabla de parciales por kilómetro.

#### Scenario: Detalle de una ruta con altitudes

- **WHEN** la sesión tiene puntos con altitud
- **THEN** el detalle muestra los desniveles y las altitudes mínima y máxima

#### Scenario: Sesión sin altitudes

- **WHEN** la sesión no tiene datos de altitud
- **THEN** el detalle muestra «—» en los campos de altitud sin fallar

#### Scenario: Actividad de bicicleta

- **WHEN** la sesión es de bicicleta
- **THEN** el detalle usa velocidad en km/h en lugar de ritmo min/km

#### Scenario: Detalle con gráficos y parciales

- **WHEN** el usuario abre una sesión con puntos suficientes
- **THEN** el detalle muestra la tarjeta de gráficos y la tabla de parciales junto a las
  estadísticas existentes
