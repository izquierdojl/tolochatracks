# Design

## Context

Ver `proposal.md` para el problema y los GPX que lo motivaron. El cálculo actual vive en
`lib/core/calculos/calculos_ruta.dart` y tiene dos rutas que aplican el mismo filtro de
ruido por separado:

- `AcumuladorRuta.agregar`: distancia en vivo y distancia total de las estadísticas.
- `_acumular`: distancia acumulada de las series, los parciales y la distancia por
  minuto.

Ambas descartan un segmento cuando mide menos de 1,5 m y dura menos de 10 s. Con el
perfil Máxima (1 punto/s, `lib/core/models/perfil_gps.dart`), 1,5 m equivalen a 5,4 km/h;
una caminata normal queda por debajo o justo en el umbral. El GPX de Calanda - Foz
Calanda contiene 8,648 km y el cálculo actual da 5,778 km. Además, el filtro no protege
parado: los saltos de ruido mayores de 1,5 m sí se suman.

El cambio de perfiles GPS del 21 de noviembre no introdujo el filtro, pero bajó el
intervalo de 2 s a 1 s y el `distanceFilter` de 3 m a 1 m, y dejó el umbral fijo en el
peor punto. Las sesiones guardadas no almacenan la distancia: se recalcula desde los
puntos, así que el arreglo corrige también las rutas antiguas sin migración.

## Goals / Non-Goals

**Goals:**

- Distinguir movimiento real de ruido usando una ventana temporal, no un umbral fijo por
  muestra.
- Que la distancia total, las series, los parciales, la distancia por minuto, el
  historial y los resúmenes salgan del mismo cálculo.
- Que el criterio funcione con los tres perfiles y con puntos sin velocidad reportada.
- Cubrirlo con pruebas de regresión sintéticas y con los GPX reales.

**Non-Goals:**

- Suavizar, simplificar o recortar la traza del mapa ni el GPX.
- Cambiar los perfiles GPS, el formato de sesión o la exportación.
- Rediseñar el autoguardado, el aviso de señal o la altitud; van en changes aparte.
- Hacer map matching ni usar servicios externos.

## Decisions

### 1. Detector de movimiento por ventana

Se sustituye la regla `distancia < 1,5 m && segundos < 10` por una decisión sobre una
ventana de los últimos 10-12 s del mismo segmento:

```text
neto      = distancia entre el primer punto de la ventana y el actual
recorrido = suma de las distancias entre puntos consecutivos de la ventana
hay_movimiento = (neto >= 2,5-3 m  y  neto / recorrido >= 0,6)
                 o  velocidad_reportada >= 0,6 m/s
```

Si hay movimiento se suma el segmento actual; si no, no. La ventana se reinicia al
cambiar de segmento, de modo que nunca cruza una pausa. Los umbrales son puntos de
partida; los tests con trazas reales y sintéticas fijan los valores definitivos.

Por qué funciona:

```text
Parado con ruido                     Caminando a 1,4 m/s
  *   *      *   *                    *----*----*----*----*
   \ /  \   /  \ /                    neto ~ recorrido
    neto << recorrido                 neto/recorrido ~ 1
```

Un paseo lento de 1,4 m/s con un punto por segundo produce segmentos de 1,4 m, por
debajo del umbral viejo; la ventana ve que en 10 s el desplazamiento neto es de 14 m y
que coincide con el recorrido, así que cuenta el movimiento. Una persona parada con
ruido de 3 m produce un recorrido grande pero un desplazamiento neto pequeño; la ventana
lo descarta.

Alternativas descartadas:

- **Bajar o subir el umbral fijo.** No distingue ruido de movimiento y vuelve a fallar al
  cambiar el intervalo o el perfil.
- **Ancla con histéresis.** Sumar cuando el punto se aleja 3 m del ancla conserva el
  movimiento lento, pero el paseo aleatorio de una persona parada también supera el
  ancla; en la simulación con ruido de 3 m sumaba 10-18 km por hora parado.
- **Usar solo la velocidad reportada.** Es buena cuando existe, pero no todos los
  dispositivos la entregan y un 0 falso perdería distancia. Se usa como atajo, no como
  única fuente.
- **Kalman o suavizado de la traza.** Mejoraría la geometría, pero es más complejo,
  cambia la traza y queda fuera del alcance de un bug de distancia.

### 2. La velocidad reportada como atajo

`PuntoRuta.velocidad` ya guarda la velocidad del GPS cuando existe. Si es mayor o igual
que 0,6 m/s, el segmento se cuenta aunque la ventana todavía no haya madurado. Esto evita
perder los primeros metros y los giros cerrados. Si es nula, manda la ventana; si es 0
pero la ventana confirma movimiento sostenido, se cuenta. Así el criterio no depende de
que el chip reporte velocidad.

### 3. Una sola decisión para las dos rutas de cálculo

Se extrae la lógica a una pieza compartida dentro de `lib/core/calculos` (una clase
privada `DetectorMovimiento` o una función pura con estado, según quede más legible).
`AcumuladorRuta.agregar` y `_acumular` la usan con su propio estado, pero con las mismas
constantes y el mismo orden de comprobaciones. La prueba de integración debe comprobar
que:

- `estadisticas.distanciaMetros` coincide con el último valor de `serieDistancia`.
- La suma de los parciales coincide con la distancia total, salvo el tramo incompleto.
- El historial y el detalle muestran la misma distancia.

Si solo se cambiara `AcumuladorRuta`, la cifra grande diría 8,5 km pero el gráfico y los
parciales seguirían terminando en 5,8 km.

### 4. Actividad en todos los consumidores

`calcularEstadisticas` recibe `actividad` y aplica su velocidad máxima plausible. El
detalle ya la pasa; el historial, la tarjeta de última sesión y el resumen de
finalización no. Se pasan siempre desde `sesion.actividad`. Para que no vuelva a ocurrir,
se añade una prueba que compare la distancia del historial con la del detalle en una
sesión con un salto por encima del tope de la actividad.

### 5. Validación con los datos reales

El JSON de la sesión de Calanda confirma que no había ruido que justificara el descarte:
5.431 puntos, precisión mediana de 3,08 m (máxima 19,4 m) y velocidad reportada en todos
los puntos, con mediana de 1,454 m/s y percentil 95 de 1,66 m/s. Solo 34 puntos bajan de
0,6 m/s. Con ese dato, el atajo por velocidad es fiable y la ventana queda como respaldo
para dispositivos que no reporten velocidad.

La ventana con 10-12 s, neto de 2,5-3 m y relación 0,6 da:

| Caso | Filtro actual | Ventana |
|---|---:|---:|
| `mal` (Calanda, 1 Hz, JSON real) | 5,78 km | 8,63 km con velocidad; 8,49 km solo ventana |
| `bien` (Geo Tracker) | 8,45 km | 8,38 km |
| Paseo a 1,4 m/s, 1 Hz, 1 h | 0 km | ~100 % |
| Paseo lento a 0,8 m/s, 1 Hz | 0 km | 99,9 % |
| Parado 1 h con ruido de 3 m | 19 km | ~0 km |
| Ruta con paradas | 0 km | 99,7 % |

Los tests definitivos usarán una traza sintética para cada caso y una muestra recortada
de la sesión real de 1 Hz, con velocidad y precisión, más una muestra del GPX de
frecuencia baja. No hace falta guardar la sesión completa de 1,2 MB en el repositorio.

## Risks / Trade-offs

- **Primeros metros de un segmento** -> la ventana tarda 2-3 s en confirmar el
  movimiento si no hay velocidad reportada; se pierden unos metros al arrancar y tras
  cada pausa. La velocidad reportada lo evita cuando existe. Es preferible a perder un
  tercio de la ruta.
- **Giros muy cerrados o zigzag** -> la relación neto/recorrido baja y se pueden perder
  algunos metros en el giro. La ventana de 10-12 s y el atajo por velocidad limitan la
  pérdida; el GPX real conserva la traza.
- **Ruido correlacionado parado** -> la ventana puede sumar unos metros por hora, no
  kilómetros. Es aceptable frente al comportamiento actual.
- **Cambio visible en sesiones antiguas** -> al recalcular, algunas rutas mostrarán más
  distancia y mejor ritmo. Es el resultado esperado; el archivo JSON no se toca.
- **Dos acumuladores con estados distintos** -> si se separan las constantes o el orden
  de comprobaciones, vuelven a divergir. Se mitiga con la pieza compartida y la prueba
  total/serie/parciales.
- **Dependencia de `PuntoRuta.velocidad`** -> si el GPS miente con 0, la ventana sigue
  funcionando; si miente con un valor alto parado, el atajo podría sumar ruido. Se acota
  con la velocidad máxima plausible de la actividad y la precisión del perfil.

## Migration Plan

- No hay migración de datos ni cambio de formato.
- Al abrir una sesión guardada, `calcularEstadisticas` la recalcula en memoria con el
  criterio nuevo; el JSON existente no se reescribe.
- La distancia en vivo usa el mismo detector desde el primer punto; no hay bandera de
  compatibilidad.
- Rollback: revertir el change. Los JSON guardados siguen siendo válidos y se
  recalcularán con el criterio anterior si se vuelve a esa versión.
- El GPX y el JSON exportados no cambian de formato; el GPX conserva todos los puntos y
  su longitud geométrica puede seguir siendo ligeramente mayor que la distancia filtrada
  de la app.
