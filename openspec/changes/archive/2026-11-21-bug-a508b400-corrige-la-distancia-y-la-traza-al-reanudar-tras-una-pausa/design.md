# Design

## Context

Ver `proposal.md` para el problema. Hoy `PuntoRuta` es una lista plana: el acumulador,
el mapa y el GPX unen siempre puntos consecutivos. La pausa solo detiene el cronómetro y
la suscripción de ubicación; no deja ninguna marca en los datos. Por eso el primer punto
posterior a la pausa se compara con el último anterior y su desplazamiento se suma.

## Goals / Non-Goals

**Goals:**

- Que una pausa sea un corte real de la ruta en captura, estadísticas, mapa y GPX.
- Que el tiempo de los gráficos sea activo, sin los huecos de pausa.
- Que las sesiones antiguas se sigan abriendo y se puedan mostrar/exportar con cortes
  inferidos, sin migrarlas ni reescribir su archivo interno.
- Mantener el formato JSON tolerante y versionado.

**Non-Goals:**

- Filtro de precisión GPS, velocidad reportada y perfiles de Ajustes: change `feature`.
- Pausa automática.
- Map matching o suavizado de la traza.
- Reescribir las sesiones antiguas al abrirlas.

## Decisions

### El segmento vive en el punto

Se añade `segmento` (entero, por defecto 0) a `PuntoRuta`. El primer punto de una
grabación es el segmento 0; cada reanudación incrementa el contador y los puntos nuevos
llevan el nuevo valor. Se serializa como `seg` solo cuando es mayor que 0, para que los
archivos de una sola tirada no cambien.

Alternativas descartadas:

- Una lista de índices en `Sesion`: obliga a traducir índices al filtrar puntos y
  complica el borrador y la exportación.
- Inferir siempre por huecos: no distingue una pausa de una pérdida de señal y no sirve
  para las sesiones nuevas.

### Formato 3 y lectura tolerante

`formatoSesionActual` pasa a 3. Al leer:

- Formato 3: se respeta el `seg` de cada punto.
- Formato 2 o anterior: se infieren los cortes en huecos de más de 60 s y se asignan
  segmentos en memoria. El archivo original no se toca.
- Si faltan puntos o el `seg` es inválido, se usa 0.

`Sesion.copiaCon` sigue escribiendo el formato actual, así que una sesión antigua que se
vuelve a guardar (por ejemplo, al marcarla exportada) se normaliza a formato 3 con sus
segmentos inferidos. Es una escritura nueva, no una migración silenciosa al abrir.

### El acumulador corta al cambiar de segmento

`AcumuladorRuta.agregar` comprueba si el segmento del punto cambia respecto al último
válido. Si cambia, pone `_ultimo = null` antes de procesar: el punto marca el inicio del
segmento, no suma distancia ni velocidad y no se compara con el punto anterior a la
pausa. `puntoAceptable` se llama con `anterior = null` para el primer punto de cada
segmento.

`_puntosValidos` y `_acumular` hacen lo mismo:

- Al cambiar de segmento, `_puntosValidos` no filtra el primer punto contra el anterior.
- `_acumular` no suma la distancia del salto y no suma el delta de tiempo de la pausa;
  el tiempo activo continúa donde se quedó.
- Las series, parciales y el gráfico por minuto usan ese tiempo activo.
- El primer punto de un segmento no genera muestra de velocidad (distancia 0); el
  siguiente punto del segmento sí.

### Captura y borrador

`GrabacionController` mantiene `_segmentoActual`. Al pausar cierra el tramo; al reanudar
incrementa el segmento antes de volver a suscribirse. El primer punto que llegue se
guarda con el nuevo segmento y arranca el acumulador sin distancia. La recuperación del
borrador restaura `_segmentoActual` desde el último punto guardado. La notificación usa
los mismos métodos, así que Pausar/Reanudar desde ella también corta el segmento.

Si se pausa y se reanuda sin recibir ningún punto, no se crea un segmento vacío: el
siguiente punto usará el contador incrementado y los segmentos presentes serán los que
tengan puntos.

### GPX, mapa y gráfico

- GPX: se agrupan los puntos por `segmento` y se escribe un `<trkseg>` por grupo. No se
  escribe ningún punto de unión. Las sesiones antiguas ya llegan con segmentos inferidos
  desde el parser.
- Mapa: `MapaRuta` construye una polilínea por segmento; los marcadores de inicio y fin
  siguen siendo el primer y el último punto. La vista en vivo usa el mismo widget y los
  puntos del controlador.
- Gráfico: no cambia el widget; cambia la serie de tiempo, que ya no incluye las pausas.
  El gráfico por minuto usa minutos activos.

### Inferencia para sesiones antiguas

Un hueco de más de 60 s se interpreta como pausa. Es una heurística solo para datos
antiguos; las sesiones nuevas llevan el corte explícito. El umbral es una constante
documentada y testeada. Una pérdida de señal larga en una sesión antigua se tratará como
pausa; es preferible a dibujar una línea recta de kilómetros entre dos puntos.

## Risks / Trade-offs

- **Hueco largo de señal en sesión antigua** → se corta la distancia; se acepta porque no
  hay forma fiable de distinguirlo de una pausa y el dato entre ambos puntos es dudoso.
- **Duración activa del resumen frente al eje del gráfico** → el resumen usa la duración
  guardada y el gráfico la suma de segmentos; pueden diferir unos segundos. Se documenta
  y se testea que la diferencia no sea negativa ni infinita.
- **Sesión antigua reescrita al marcarla exportada** → `copiaCon` la pasa a formato 3;
  conserva los puntos y los segmentos inferidos. No se pierde información.
- **GPX con muchos `<trkseg>`** → solo se crea uno por pausa; el número es pequeño y los
  consumidores GPX estándar lo soportan.

## Migration Plan

No hay migración de archivos. El parser normaliza en memoria las sesiones de formato 2.
Las sesiones nuevas se guardan en formato 3. Si se detecta un problema, basta con volver
a leer: el archivo original de una sesión antigua sigue intacto hasta que la app lo
reescriba por una acción explícita (exportar/marcar).
