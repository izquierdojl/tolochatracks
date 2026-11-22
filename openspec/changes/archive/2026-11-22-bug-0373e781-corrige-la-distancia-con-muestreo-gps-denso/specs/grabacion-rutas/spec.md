# Spec Delta

## MODIFIED Requirements

### Requirement: Calidad de los puntos y distancia

La app SHALL descartar las posiciones cuya precisión supere el umbral del perfil GPS
seleccionado (40, 30 o 20 m), ignorar los saltos incompatibles con la velocidad máxima
plausible de la actividad y calcular la distancia con Haversine. La distancia SHALL
contar el movimiento sostenido aunque cada muestra avance menos de 1,5 m y SHALL NOT
sumar el ruido de una persona parada; para ello SHALL evaluar una ventana temporal y la
velocidad reportada cuando exista, no un umbral fijo por muestra. El desnivel SHALL
acumularse en el SI. Los puntos descartados SHALL NOT formar parte de la ruta, el mapa ni
la exportación.

#### Scenario: Punto con mala precisión

- **WHEN** llega una posición con precisión superior al umbral del perfil
- **THEN** no se añade a la ruta ni suma distancia y no aparece en el mapa ni en el GPX

#### Scenario: Salto imposible de GPS

- **WHEN** dos posiciones consecutivas implican una velocidad superior a la máxima
  plausible de la actividad (30 km/h al correr, 12 al caminar, 80 en bicicleta)
- **THEN** ese segmento no suma distancia

#### Scenario: Precisión aceptable

- **WHEN** el perfil es Equilibrada y llega una posición de 25 m de precisión
- **THEN** se acepta y suma distancia

#### Scenario: Perfil de ahorro

- **WHEN** el perfil es Ahorro y llega una posición de 35 m de precisión
- **THEN** se acepta, porque su umbral es 40 m

#### Scenario: Muestreo denso a ritmo de caminata

- **WHEN** el perfil es Máxima y una persona camina a 1,4 m/s con una posición por segundo
- **THEN** la distancia suma el movimiento sostenido y no lo confunde con ruido, aunque
  cada segmento mida 1,4 m

#### Scenario: Velocidad reportada en muestreo denso

- **WHEN** el GPS reporta 1,4 m/s en cada posición de una caminata con una posición por
  segundo
- **THEN** la distancia suma todos los segmentos, incluido el primero de cada tramo

#### Scenario: Parado con ruido GPS

- **WHEN** la persona está parada y las posiciones oscilan varios metros por el ruido
- **THEN** la distancia no aumenta por esas oscilaciones

#### Scenario: Movimiento lento

- **WHEN** la persona avanza a 0,8 m/s con una posición por segundo
- **THEN** la distancia suma el movimiento sostenido y no lo confunde con ruido

#### Scenario: Cambio de segmento

- **WHEN** una pausa abre un segmento nuevo
- **THEN** la ventana de movimiento se reinicia y la distancia no cruza el hueco
