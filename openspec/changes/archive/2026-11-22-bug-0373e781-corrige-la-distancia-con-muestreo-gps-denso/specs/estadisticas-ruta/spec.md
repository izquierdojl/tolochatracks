# Spec Delta

## ADDED Requirements

### Requirement: Distancia coherente entre vistas

La app SHALL usar la misma distancia válida en la distancia total, las series, los
parciales, la distancia por minuto, el historial y los resúmenes de una sesión. El
cálculo SHALL recibir la actividad de la sesión para aplicar su tope de velocidad
plausible. Todas las vistas de una misma sesión SHALL mostrar la misma distancia y el
mismo ritmo o velocidad media, salvo diferencias de redondeo al formatear.

#### Scenario: Historial y detalle coinciden

- **WHEN** una sesión aparece en el historial y se abre su detalle
- **THEN** ambos muestran la misma distancia y el mismo ritmo o velocidad media

#### Scenario: Total y series coinciden

- **WHEN** una sesión tiene puntos suficientes para dibujar gráficos
- **THEN** el último valor de la serie de distancia coincide con la distancia total y los
  parciales suman la misma distancia, salvo el tramo incompleto final

#### Scenario: Actividad de la sesión

- **WHEN** una sesión de Caminar contiene un salto que supera su velocidad máxima
  plausible pero no la de «Otras»
- **THEN** el historial, el detalle y el resumen descartan ese salto y muestran la misma
  distancia

#### Scenario: Sesión ya guardada

- **WHEN** se abre una sesión guardada antes de este cambio
- **THEN** la distancia se recalcula en memoria con el criterio vigente sin modificar su
  archivo JSON
