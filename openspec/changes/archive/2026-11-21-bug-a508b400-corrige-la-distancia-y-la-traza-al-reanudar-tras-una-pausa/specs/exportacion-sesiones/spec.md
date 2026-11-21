# Spec Delta

## MODIFIED Requirements

### Requirement: Formatos de exportación

La app SHALL exportar cada sesión en dos archivos: GPX 1.1 válido, con metadatos y un
`<trkseg>` por segmento, con un `trkpt` por punto con latitud, longitud, altitud (si
existe) y tiempo; y JSON nativo con la sesión completa serializada, incluidos los cortes
de segmento. Las sesiones antiguas con huecos superiores a 60 segundos SHALL exportarse
con un `<trkseg>` por hueco, sin modificar el JSON interno.

#### Scenario: Exportar una ruta con altitudes

- **WHEN** el usuario exporta una sesión con altitudes
- **THEN** el GPX contiene un `trkpt` por punto con `<ele>` y `<time>` y el JSON conserva
  la sesión íntegra

#### Scenario: Ruta sin altitudes

- **WHEN** la sesión no tiene altitud en sus puntos
- **THEN** el GPX omite `<ele>` en esos puntos sin dejar el archivo inválido

#### Scenario: Ruta con pausas

- **WHEN** la sesión tiene dos pausas
- **THEN** el GPX contiene tres `<trkseg>` y ningún segmento contiene el tramo recto entre
  los extremos de una pausa

#### Scenario: Sesión antigua con un hueco

- **WHEN** se exporta una sesión guardada antes de existir los segmentos y tiene un hueco
  de más de 60 segundos
- **THEN** el GPX separa el hueco en dos `<trkseg>` y el JSON exportado conserva la
  información sin alterar el archivo interno
