# Design

## Context

Ver `proposal.md` para el problema y la captura que lo motivó. El estado actual:

- `TablaParciales` usa una fila con círculo de 34 dp, nombre largo y dos columnas fijas de
  64 y 78 dp; `formatearRitmo` devuelve `11:23 /km` y `formatearVelocidad` `11,2 km/h`,
  así que la unidad se repite en cada fila y la celda de ritmo queda sin aire.
- `ParcialKm` y `_parciales()` en `calculos_ruta.dart` están fijados a cortes de 1.000 m.
- `EstadisticasRuta` guarda `serieDistancia` (km frente a minutos), `serieVelocidad` y
  `serieAltitud` (ambas frente a km); no hay series frente a tiempo.
- `GraficoSesion` usa cuatro `ChoiceChip` y una sola escala implícita; la gráfica de
  distancia resta el margen al mínimo y puede arrancar en negativo.
- `Ajustes` persiste tema, mapa, perfil GPS y carpeta; no hay preferencia de parciales.
- El detalle calcula `_estadisticas` una vez en `initState` con un campo `late final`.

## Goals / Non-Goals

**Goals:**

- Que la tabla se lea en 360 dp y 411 dp, en tema claro y oscuro, con y sin altitud.
- Que el cálculo de parciales sea una función pura y testeable para distancia y tiempo.
- Que la preferencia de parciales sea tolerante a valores corruptos y no toque el JSON de
  sesión ni el GPX.
- Que el detalle siga funcionando sin conexión y sin mapas, como el resto de la app.

**Non-Goals:**

- Guardar parciales por sesión o exportarlos.
- Un panel de detalle interno de un parcial o una segunda tabla de barras.
- Ritmo como eje Y invertido.
- Valores libres de paso o pasos por actividad.
- Cambiar la grabación, los permisos o la capa de mapas.

## Decisions

### 1. Un solo change, con la tabla primero

El change es autocontenido: la primera fase rediseña la tabla y arregla la legibilidad; la
segunda añade la configuración y las gráficas. Así, si la implementación se interrumpe
después de la primera fase, la app ya no muestra la tabla amontonada. Se descarta partir
en un `bug` y una `feature` porque la tabla se reescribe una sola vez y la feature debe
resolver el problema por sí sola.

### 2. `ConfiguracionParciales` y `ParcialRuta`

`ConfiguracionParciales` es inmutable y guarda el modo y un único `int` en unidades del SI:

| Modo | `valor` | Opciones |
|---|---|---|
| `distancia` | metros | 100, 200, 500, 1.000, 5.000, 10.000 |
| `tiempo` | segundos | 60, 300, 600, 900, 1.200, 1.800, 2.700, 3.600 |

El valor por defecto es `distancia(1000)`. La clase expone las listas de opciones, la
descripción corta (`Cada 1 km`, `Cada 5 min`), la etiqueta de cada paso y una validación
que rechaza valores fuera de la lista. Un único entero evita campos nulos, simplifica la
igualdad y la serialización, y deja la unidad determinada por el modo.

`ParcialKm` pasa a `ParcialRuta` porque deja de ser solo kilómetros:

| Campo | Tipo | Nota |
|---|---|---|
| `numero` | `int` | orden, no se muestra |
| `distanciaMetros` | `double` | distancia real del tramo |
| `duracion` | `Duration` | tiempo activo |
| `velocidadMedia` | `double` | m/s |
| `altitudMedia` | `double?` | `null` si el tramo no tiene altitudes |
| `completo` | `bool` | depende del paso configurado |
| `destacado` | `DestacadoParcial` | `ninguno`, `masRapido` o `masLento` |

`DestacadoParcial` evita dos booleanos que podrían contradecirse. El modelo no se
serializa: las estadísticas se recalculan al abrir el detalle, así que no hay migración de
datos.

### 3. Cortes por distancia y por tiempo

`calcularEstadisticas` recibe `ConfiguracionParciales parciales` con valor por defecto y
sigue usando `_puntosValidos` y `_acumular`, que ya resuelven pausas, segmentos y jitter.
El acumulador guarda distancia y tiempo activo por punto.

**Distancia.** Se recorre cada pareja de puntos acumulados y, mientras
`actual.distancia >= numero * paso`, se interpola el tiempo en el límite:

```text
fraccion = (limite - anterior.distancia) / (actual.distancia - anterior.distancia)
tiempo   = anterior.tiempo + (actual.tiempo - anterior.tiempo) * fraccion
```

El parcial completo mide exactamente el paso; su duración es `tiempo - inicioTiempo`.
Después del último corte, si quedan más de 20 m, se añade el tramo `Final` con la distancia
y el tiempo restantes.

**Tiempo.** Se recorre igual, pero el límite es `numero * paso` de tiempo activo y se
interpola la distancia:

```text
fraccion  = (limite - anterior.tiempo) / (actual.tiempo - anterior.tiempo)
distancia = anterior.distancia + (actual.distancia - anterior.distancia) * fraccion
```

La duración del completo es el paso. Al final, si quedan al menos 10 s, se añade el tramo
`Final`. Un `while` (no un `if`) permite que una pareja de puntos con un hueco de GPS cruce
varios límites.

**Pausas.** `_acumular` no suma el tiempo entre segmentos y añade distancia cero en el
cambio de segmento. Un límite que cae justo en una reanudación se corta en el punto de
reanudación; no se inventa un tramo dentro de la pausa. Se cubre con tests de pausa en
ambos modos.

**Invariantes.** La suma de distancias de los parciales es la distancia total (salvo
redondeos de milisegundos) y la suma de duraciones es el tiempo activo del acumulador. Se
verifican en los tests.

### 4. Altitud media y destacados

La altitud media se calcula en una pasada con un puntero sobre los puntos acumulados: cada
punto pertenece al tramo cuyo intervalo `[inicio, fin)` lo contiene, el primero incluye el
punto inicial y el último incluye el final. Se ignoran los puntos sin altitud; si el tramo
no tiene ninguno, `altitudMedia` es `null`. La media de los puntos válidos es más estable
que la altitud instantánea del GPS.

Los destacados se calculan después de construir la lista:

- Solo compiten los tramos `completo`.
- Hacen falta al menos tres; con dos, uno siempre sería el rápido y el otro el lento.
- Si la diferencia entre la velocidad máxima y la mínima es menor que `1e-6` m/s, no se
  marca nada.
- Se marcan todos los tramos empatados en el máximo y en el mínimo.
- El tramo `Final` nunca compite.

En pasos de 100 m o 1 min el GPS puede hacer que el trofeo sea ruidoso; es una ayuda
visual, no una clasificación oficial, y el usuario puede volver a 1 km.

### 5. Persistencia y estado

`Ajustes` gana `parciales` con valor por defecto `distancia(1000)`. Se guarda en
`shared_preferences` con dos claves:

- `config.parciales.modo`: `distancia` o `tiempo`.
- `config.parciales.valor`: entero en metros o segundos.

La carga valida el modo y que el valor esté en la lista; si algo falla, usa el valor por
defecto sin romper el arranque. `ConfiguracionController` expone `parciales` y
`cambiarParciales`, que actualiza la memoria, notifica y guarda.

El detalle lee la preferencia en `initState` y guarda `_parciales` y `_estadisticas` (ya no
`late final`). Al cambiar desde el detalle:

1. La hoja devuelve la nueva configuración.
2. `setState` actualiza `_parciales` y recalcula `_estadisticas`.
3. Se persiste con `cambiarParciales`.

Si la persistencia falla, la vista mantiene el valor nuevo durante la sesión y el siguiente
arranque vuelve al último guardado. La preferencia es global y se aplica al abrir cada
detalle; no se guarda por sesión ni se escribe en el JSON/GPX.

Alternativa descartada: recalcular solo los parciales con una función aparte. Ahorraría
recalcular las series, pero obligaría a duplicar o exponer el acumulador. El coste de
`calcularEstadisticas` es O(n) y solo se paga cuando el usuario cambia la configuración.

### 6. Tabla

Se sustituye la fila actual por una tabla propia con `Row`, sin `DataTable` (que añade
padding y es difícil de ajustar). Cabecera y filas comparten los mismos anchos:

```text
+---------------------------------------------------------+
| Parciales                                  [ ajustes ]  |
| Cada 1 km · 3 tramos                                    |
|                                                         |
| TRAMO      BARRA       TIEMPO  RITMO   ALT.   +         |
| ------------------------------------------------------- |
| Km 1       ##########  11:23   11:23   124    T         |
| Km 2       #######      4:46    9:13   131    L         |
| Final      ###          3:42    9:05   128    -         |
| 519 m                                                   |
|                                                         |
| T mas rapido   L mas lento                              |
+---------------------------------------------------------+
```

- **Tramo** (`Expanded`, flex 3): etiqueta compacta. Para distancia, `Km 1` si el paso es
  múltiplo de 1 km; `100 m` si el extremo es menor de 1 km; `Km 1,5` si no. Para tiempo,
  `5 min`, `45 min`, `1 h` o `1 h 30`. El tramo incompleto se llama `Final` y lleva debajo
  su distancia o duración real en `labelSmall`.
- **Barra** (`Expanded`, flex 2): ver decisión 7.
- **Tiempo** (ancho fijo 46 dp): `formatearDuracion`, sin unidad.
- **Ritmo/Velocidad** (ancho fijo 52 dp): `formatearRitmoCorto` o
  `formatearVelocidadCorta`, sin unidad; la cabecera dice `RITMO` y `(min/km)` en dos
  líneas, o `VEL.` y `(km/h)`.
- **Altitud** (ancho fijo 34 dp): entero en metros o `—`; la cabecera dice `ALT.` y `(m)`.
  Se omite si ningún parcial tiene altitud.
- **Destacado** (ancho fijo 22 dp): icono del trofeo o de bajada, o vacío.

Tipografía: cabeceras en `labelSmall` (11 sp) con `letterSpacing: 0.4`; valores en
`labelMedium` (12 sp) con `FontFeature.tabularFigures()` y `FontWeight.w500`; el subtítulo
del `Final` en `labelSmall`. El título y el subtítulo de la tarjeta mantienen el estilo
actual. Los divisores usan `outlineVariant` con alfa 0,3.

En el contenido de la tarjeta:

| Ancho | Tramo | Barra | Tiempo | Ritmo | Alt. | Dest. | Huecos |
|---|---:|---:|---:|---:|---:|---:|---:|
| 347 dp | 94 | 63 | 46 | 52 | 34 | 22 | 5 x 8 |
| 296 dp | 89 | 59 | 46 | 52 | — | 22 | 4 x 8 |
| 256 dp | 74 | 50 | 46 | 52 | — | 22 | 4 x 4 |

Un `LayoutBuilder` decide si la columna de altitud cabe (umbral 340 dp de contenido). Si no
cabe, la altitud pasa a una segunda línea bajo el tramo (`Km 1` / `124 m`) y la tabla
mantiene el resto de columnas. No se usa desplazamiento horizontal. Se prueba a 360 dp y
411 dp, en claro y oscuro.

La cabecera de la tarjeta muestra `Cada 1 km · N tramos` y un `IconButton` de ajustes con
tooltip «Configurar parciales». El estado vacío depende del modo:

- Distancia: «No hay distancia suficiente para calcular parciales (mínimo 20 m).»
- Tiempo: «No hay tiempo activo suficiente para calcular parciales (mínimo 10 s).»

### 7. Barras por fila

Cada fila lleva una barra horizontal en su propia celda, alineada 1:1 con la fila:

- Pista de 6 dp de alto con `surfaceContainerHigh` y radio 3.
- Relleno con `ColoresRuta.velocidad`, `FractionallySizedBox` y `fraccionBarra`.
- `fraccionBarra(velocidad, maximo)` es una función pura: 0 si no hay velocidad o máximo;
  si no, `clamp(velocidad / maximo, 0.06, 1.0)`. El mínimo del 6 % mantiene visible el
  tramo más lento.
- La escala se normaliza con el máximo de los tramos completos; si no hay ninguno, con el
  máximo de todos. El `Final` usa la misma escala y se recorta a 1 si la supera.
- La barra es decorativa: `ExcludeSemantics`, sin tooltip ni interacción. El valor
  numérico de ritmo o velocidad sigue en su celda.

No hay selección de fila, panel desplegable ni gráfico aparte. La comparación es la propia
tabla, como pidió el usuario.

### 8. Destacados en la última columna

El icono del más rápido es `Icons.emoji_events` con `colorScheme.tertiary`; el del más
lento es `Icons.trending_down` con `colorScheme.onSurfaceVariant`. Ambos llevan
`Semantics(label: 'Parcial más rápido')` o `'Parcial más lento'`; nunca se distingue solo
por color. Debajo de la tabla, y solo si hay algún destacado, aparece una leyenda con los
dos iconos y sus textos. La cabecera de la columna queda vacía para no sugerir que solo
hay trofeo.

### 9. Muchos parciales

La tabla es un `StatefulWidget` con `_mostrarTodos = false`. Muestra los 10 primeros y un
`TextButton.icon` con «Ver los N restantes»; al pulsarlo muestra todos y cambia a «Ver
menos». El estado se reinicia cuando cambia la configuración (`didUpdateWidget`). El
subtítulo indica el total de tramos.

Se descarta un área con scroll anidado de altura fija: en un detalle que ya es un
`ListView`, el scroll anidado se pelea con el gesto principal. Con 210 filas expandidas la
página es larga, pero son `Row` de texto y no hay coste perceptible.

### 10. Selector compartido

`lib/core/widgets/selector_parciales.dart` expone
`mostrarSelectorParciales(context, {required actual})` y devuelve
`Future<ConfiguracionParciales?>`. Es una hoja inferior con:

- `SegmentedButton<ModoParciales>` con «Por distancia» y «Por tiempo».
- Un `Wrap` de `ChoiceChip` con las opciones del modo.
- Botones «Cancelar» y «Listo».

El borrador vive en la hoja; cambiar de modo selecciona el valor por defecto de ese modo
(1 km o 5 min). «Listo» devuelve el borrador; cerrar sin pulsar no cambia nada. La hoja no
persiste ni conoce controladores, así que la reutilizan el detalle y Ajustes sin duplicar
lógica. En Ajustes se abre desde una tarjeta «Parciales» con el valor actual como subtítulo.

Se descartan dos desplegables en la cabecera de la tabla: roban ancho al título, no caben
bien a 360 dp y no permiten explicar la diferencia entre modo y paso.

### 11. Gráficas

`MetricaGrafico` mantiene las cuatro métricas actuales y se añade `EjeX { tiempo,
distancia }`. La tarjeta muestra dos `DropdownButtonFormField` apilados, con claves
`grafico-metrica` y `grafico-eje-x`:

| Métrica | Eje X | Resultado |
|---|---|---|
| Distancia | Tiempo (fijo) | km frente a minutos |
| Velocidad | Tiempo o Distancia | km/h frente a minutos o km |
| Altitud | Tiempo o Distancia | m frente a minutos o km |
| Por minuto | — | barras de metros por minuto |

Al elegir Distancia, el eje X se fija en Tiempo y el desplegable se deshabilita; al elegir
Por minuto, el eje X se oculta. La descripción en español cambia con la combinación. Los
cambios son inmediatos y no tocan el resto de estadísticas.

Para el eje X de tiempo se añaden `serieVelocidadTiempo` y `serieAltitudTiempo` a
`EstadisticasRuta`. Se construyen en el mismo recorrido que las series por distancia, con
`x = minutos activos`; se muestrean con el mismo límite que las actuales. No se duplica el
suavizado ni se cambia el cálculo de la velocidad.

Rangos verticales:

- Distancia, velocidad y minutos: mínimo 0; máximo con un 10–18 % de aire.
- Altitud: mínimo y máximo con un margen del 10 % del rango (o 5 m si el rango es 0).
- Nunca se resta margen al mínimo cuando el dato no es negativo.

Se mantiene km/h en las gráficas; el ritmo (min/km) vive en la tabla. Un eje de ritmo
exigiría invertir el eje y formatear `mm:ss`, y no aporta sobre la velocidad para comparar
la forma de la ruta.

Alternativa descartada: dibujar todas las combinaciones apiladas hacia abajo. Con cinco
combinaciones y 220 dp cada una, el detalle se vuelve interminable; los desplegables
mantienen una sola gráfica grande y el usuario elige.

### 12. Rendimiento

- Cambiar la configuración recalcula `calcularEstadisticas` completo: O(n) sobre los puntos
  válidos, una vez por acción del usuario. Las series se vuelven a muestrear, pero el
  límite de muestras no cambia.
- La tabla se pliega a 10 filas por defecto; expandir 210 filas de texto es aceptable.
- Las dos series nuevas añaden como máximo el mismo número de muestras que las actuales;
  no hay impacto perceptible.
- No hay red, ni almacenamiento nuevo salvo las dos claves de preferencia.

## Risks / Trade-offs

- **Ruido del GPS en pasos cortos** → el trofeo a 100 m o 1 min puede cambiar entre
  grabaciones. Se limita a tramos completos y tres mínimos, y el usuario puede elegir 1 km.
- **Límite en una reanudación** → un corte de tiempo puede caer justo al reanudar. Se
  cubre con tests de pausa en ambos modos y no se inventan tramos dentro de la pausa.
- **Altitud ruidosa** → la media por tramo suaviza; si no hay altitudes, la columna
  desaparece y no se muestra una columna vacía.
- **Muchas filas** → 100 m en 21 km son 210 filas. El plegado a 10 evita la lista
  interminable; expandir sigue siendo una acción explícita.
- **Pantallas estrechas y texto grande** → a 360 dp se mueve la altitud bajo el tramo y la
  barra se encoge. Se prueba a 360/411 dp y con escala de texto alta; si el texto no cabe,
  se prioriza no perder dígitos antes que mantener todas las columnas.
- **Preferencia global** → cambiarla en un detalle afecta a los siguientes. Es el
  comportamiento pedido (configurable, no por sesión) y Ajustes lo muestra como valor por
  defecto.
- **Gráfica de velocidad desde 0** → la línea queda más plana que con el mínimo actual. Es
  el precio de no mostrar un eje negativo ni exagerar la forma.
- **Renombrar `ParcialKm`** → toca tests y la tabla, pero no hay serialización ni datos
  guardados que migrar.

## Migration Plan

- No hay migración de sesiones: los parciales se derivan de los puntos y se recalculan al
  abrir el detalle.
- La primera vez no existen las claves `config.parciales.*`: se usa 1 km. Un valor
  inválido o un modo desconocido cae al mismo valor por defecto.
- El JSON de sesión y el GPX/JSON exportado no cambian; no hay versión de esquema nueva.
- Revertir el change no requiere limpiar datos: las claves nuevas quedan ignoradas por una
  versión anterior y las sesiones siguen abriéndose.

## Open Questions

Ninguna que cambie el alcance, el enfoque o el desglose de tareas. El empate de destacados
se resuelve marcando a todos los empatados; el paso por defecto en modo tiempo es 5 min.
