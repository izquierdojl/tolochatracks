# Spec Delta

## ADDED Requirements

### Requirement: Exportación de la ruta válida

La exportación SHALL usar los mismos puntos válidos que las estadísticas y el mapa. Los
puntos descartados por precisión o por salto SHALL NOT aparecer en el GPX ni en el JSON
exportado, aunque la sesión interna los conserve. El GPX y el JSON exportados SHALL
contener la misma ruta y los mismos segmentos.

#### Scenario: Punto descartado

- **WHEN** una sesión tiene un punto descartado por precisión
- **THEN** no aparece en el GPX ni en el JSON exportado y la ruta coincide con el mapa y
  las estadísticas

#### Scenario: Sesión antigua con puntos descartados

- **WHEN** se exporta una sesión antigua que contiene un punto de 54,7 m de precisión
- **THEN** se omite y el resto de la ruta se exporta con sus segmentos
