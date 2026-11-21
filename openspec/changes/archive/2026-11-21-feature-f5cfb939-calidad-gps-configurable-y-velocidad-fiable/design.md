# Design

## Context

Ver `proposal.md` para el problema y el JSON real que lo motivó. La captura actual usa
`LocationAccuracy.high`, `distanceFilter: 3` e intervalo de 2 s. El acumulador calcula la
velocidad máxima con `distancia / tiempo` entre puntos y no usa la velocidad reportada
por el GPS, aunque `PuntoRuta` ya la guarda. El filtro de precisión está fijado en 100 m.

Este change se aplica después del `bug` de pausas: el modelo ya tiene segmentos y el GPX
ya escribe varios `<trkseg>`. Aquí se añade la calidad configurable y la velocidad
fiable.

## Goals / Non-Goals

**Goals:**

- Un perfil GPS persistente que cambie frecuencia, filtro y consumo sin prometer que el
  chip del móvil sea mejor.
- Que la velocidad máxima y las series usen la velocidad reportada cuando exista, con la
  derivada como respaldo y un tope por actividad.
- Que la precisión se vea en pantalla y que la ruta válida sea la misma en estadísticas,
  mapa y exportación.
- Que las sesiones antiguas mejoren al abrirlas, sin reescribir su JSON.

**Non-Goals:**

- Map matching, suavizado de la traza y descarga de mapas.
- Cambiar de LocationManager a Play Services o pedir permisos nuevos.
- Perfiles personalizados o umbrales editables por el usuario.
- Reescribir sesiones antiguas.

## Decisions

### Tres perfiles con parámetros cerrados

Se crea `PerfilGps` en `lib/core/models` con tres valores:

| Perfil | Intervalo | Distancia mínima | Calidad | Precisión máxima |
|---|---:|---:|---|---:|
| Ahorro | 5 s | 10 m | medium | 40 m |
| Equilibrada | 2 s | 3 m | high | 30 m |
| Máxima | 1 s | 1 m | high | 20 m |

`forceLocationManager: true` y `useMSLAltitude: true` se mantienen. En Android 12+ el
plugin sigue usando el proveedor fusionado del sistema si existe; el perfil no cambia esa
decisión. `LocationAccuracy.best` y `bestForNavigation` se descartan para Máxima porque
en geolocator acaban en la misma calidad que `high`; el cambio real es frecuencia y
filtro.

El perfil se guarda en `shared_preferences` (`config.gps.perfil`) y se lee al empezar o
reanudar. Cambiarlo no altera una grabación en curso: se aplica a la siguiente. Ajustes
lo explica.

Alternativas descartadas:

- Un interruptor «máxima precisión»: no da la opción de ahorro y no comunica el coste.
- Cambiar solo `LocationAccuracy`: no aporta por encima de `high` y no controla el filtro.
- `bestForNavigation`: misma calidad efectiva, sin ventaja.

### El filtro se aplica en captura y en la vista válida

En captura, `GrabacionController` pasa el perfil y la actividad a la suscripción y al
acumulador. `puntoAceptable` rechaza por precisión y por velocidad máxima plausible:

- Correr 30 km/h, caminar 12, senderismo 15, bicicleta 80, otras 120.
- La precisión máxima sale del perfil.

Los puntos rechazados no se guardan en la grabación nueva. Para sesiones antiguas, y para
que mapa, estadísticas y exportación coincidan, se añade una vista de **puntos válidos**:
filtra con 40 m (el umbral más permisivo de los perfiles) y el tope de la actividad, sin
tocar el JSON. Así una sesión de Ahorro no pierde puntos al mostrarse, y una sesión
antigua pierde los de 44-64 m que contaminaban la traza. La vista conserva el `segmento`
del bug de pausas.

`calcularEstadisticas` y el detalle usan esa vista. La grabación en vivo usa el
acumulador con el perfil elegido; sus puntos ya son válidos.

### Calentamiento tras arrancar o reanudar

Se descartan para distancia y velocidad los primeros 5 s o hasta dos posiciones
consecutivas con precisión aceptable, lo que ocurra antes. El primer punto aceptado inicia
el segmento; el tiempo activo sigue contando. En la vista de sesiones antiguas, el
acumulador también ignora la velocidad de los 5 s posteriores al inicio de cada segmento;
la distancia sí puede contar desde el primer punto válido.

Razón: el primer fix tras una pausa puede reportar 33,9 km/h sin haberse movido. El
calentamiento evita que ese valor entre en el máximo o en las series.

### Velocidad: reportada, derivada y mínimo

`PuntoGps.velocidad` se llena con `posicion.hasSpeed ? posicion.speed : null`. Así un 0
es una velocidad válida (parado) y `null` significa que el GPS no la entrega. El JSON
guarda `vel` solo cuando no es null.

Para cada punto aceptado:

```text
derivada = distancia / tiempo
reportada = punto.velocidad
velocidad = reportada != null ? min(reportada, derivada) : derivada
```

El mínimo evita los dos tipos de pico:

- El punto 104: derivada 52,5 km/h, reportada 3,8 → 3,8.
- El punto 84: derivada 18,4, reportada 5,9 → 5,9.
- El punto 244: derivada 0,26, reportada 33,9 → 0,26.

Si no hay velocidad reportada, se usa una ventana temporal de 10-15 s para el máximo y
para la serie; nunca un único segmento de 2 s. El tope por actividad se aplica después,
como última defensa. El primer punto de un segmento y el calentamiento no generan
velocidad.

`velocidadActual` usa la velocidad reportada cuando existe, incluido 0 (parado); si es
`null`, cae en la derivada. La diferencia es que ahora `null` y 0 no se confunden.

Alternativa descartada: usar solo la derivada con ventana. El JSON real demuestra que la
reportada es mejor en los saltos de posición; la ventana sola también suaviza picos
pequeños, pero no distingue una aceleración real de un salto.

### Precisión visible y aviso de señal débil

`GrabacionController` expone la precisión de la última posición recibida. La pantalla
muestra `±N m` junto al estado. Se considera señal débil si la precisión supera el umbral
del perfil o si pasan más de 5 s sin un punto válido. El aviso desaparece al llegar uno
válido. «Buscando señal GPS» sigue reservado para los 15 s sin posición de la
especificación de estados.

### Ajustes y constitución

La sección GPS se coloca antes de Batería, con un `SegmentedButton<PerfilGps>` como el
tema. Cada opción lleva una descripción breve y una nota común: el GPS del móvil no
cambia; la app ajusta frecuencia y filtro; la precisión real depende del entorno.

`AGENTS.md` §2 sustituye la fila de ubicación fija por los tres perfiles y mantiene el
servicio en primer plano, el wake lock y la ausencia de `ACCESS_BACKGROUND_LOCATION`.

## Risks / Trade-offs

- **Dispositivos sin velocidad reportada** → `hasSpeed` queda en false, `velocidad` es
  null y se usa la ventana derivada; el máximo puede ser algo menos fino, pero no rompe.
- **El GPS reporta 0 mientras se mueve** → se respeta el 0 si `hasSpeed` es true; es una
  lectura válida. Si el chip miente, la velocidad se subestima, no se dispara.
- **Máxima con 20 m en un cañón urbano** → se rechazan más puntos y puede haber huecos;
  el perfil lo advierte y el usuario puede volver a Equilibrada.
- **Ahorro con `medium` no ahorra tanto como promete** → el servicio y la pantalla pesan
  más que el intervalo; el texto dice «puede consumir menos», no una cifra.
- **La vista de 40 m puede dejar kinks de 15-25 m en sesiones antiguas** → el máximo y
  las series los corrigen con la velocidad reportada; el mapa no puede inventar el dato
  que falta. La limpieza total necesitaría suavizado, que está fuera de alcance.
- **Cambiar el perfil a mitad de grabación** → no se aplica hasta la siguiente; el texto
  de Ajustes lo indica.
- **Dependencia del bug de pausas** → el perfil y la vista válida usan `segmento`; si el
  bug no está aplicado, el modelo no compila. El orden de aplicación es obligatorio.

## Migration Plan

- No hay migración de datos: las sesiones nuevas se guardan con los puntos ya filtrados y
  el formato del bug de pausas.
- Las sesiones antiguas se leen igual y se recalculan en memoria con la vista de 40 m; su
  archivo no se toca.
- La preferencia nueva tiene valor por defecto Equilibrada si no existe.
- `AGENTS.md` se actualiza en el mismo change. Rollback: volver al perfil fijo anterior y
  al filtro de 100 m; los datos guardados siguen siendo válidos.

## Open Questions

Ninguna que cambie el alcance. Los valores exactos de los topes por actividad y el umbral
de 40 m de la vista se pueden ajustar con pruebas sobre GPX reales sin cambiar la
arquitectura.
