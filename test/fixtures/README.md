# Fixtures de rutas

Muestras anonimizadas de rutas reales para las pruebas de distancia y movimiento. No
contienen la ubicación ni la fecha reales y no se suben a ningún sitio.

- `muestra_1hz.json`: 180 puntos de una sesión real de TolochaTracks con perfil Máxima,
  un punto por segundo. Se conservan la geometría, el muestreo, la precisión y la
  velocidad; las coordenadas y la fecha se han desplazado y rotado. Recorrido
  geométrico: 282,968 m. Incluye `prec` y `vel` reales.
- `muestra_6s.json`: 40 puntos de una ruta real exportada con Geo Tracker, con un punto
  cada ~6 s y filtro de 10 m. También está anonimizada. Recorrido geométrico: 424,479 m.
  No incluye velocidad ni precisión.

Los ficheros completos originales están fuera del repositorio; estas muestras solo
sirven para reproducir el muestreo denso y el de frecuencia baja sin añadir cientos de
kilobytes ni datos personales.
