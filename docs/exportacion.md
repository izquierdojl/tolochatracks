# Exportación

TolochaTracks exporta cada ruta en dos formatos abiertos: **GPX 1.1** para llevarla a
otras apps de mapas y **JSON** como copia completa de la sesión. La exportación es
manual: no se sube nada a ningún servidor.

## Elegir la carpeta

En **Ajustes → Carpeta de exportación** se abre el selector de directorios de Android
(SAF). La app solicita permiso de lectura y escritura persistente sobre el árbol elegido,
así que la carpeta sigue disponible después de reiniciar. El URI se guarda en
`shared_preferences`.

Si se intenta exportar sin carpeta configurada, la app pide elegir una antes de continuar.
Nunca escribe fuera del directorio concedido.

## Exportar una ruta o todo el historial

- Desde el detalle de una ruta: botón de exportación.
- Desde el historial: **Exportar todo**, que exporta las rutas visibles con el filtro
  activo.

Cada sesión genera dos archivos con el mismo nombre base:

```
tolochatracks_AAAAMMDD_HHmm_actividad_id.gpx
tolochatracks_AAAAMMDD_HHmm_actividad_id.json
```

- `AAAAMMDD_HHmm` es la fecha y hora local de inicio.
- `actividad` es la clave ASCII: `correr`, `caminar`, `senderismo`, `bicicleta` u `otras`.
- `id` es el identificador de la sesión, saneado para que solo tenga letras, números,
  puntos, guiones y guiones bajos.

Ejemplo:

```
tolochatracks_20261122_0813_senderismo_20261122T081355-ab12.gpx
tolochatracks_20261122_0813_senderismo_20261122T081355-ab12.json
```

## GPX 1.1

El GPX incluye:

- cabecera con `version="1.1"` y `creator="TolochaTracks"`;
- `metadata` con el nombre de la sesión y la fecha de inicio en UTC;
- un `trk` con el nombre, el tipo de actividad (`running`, `walking`, `hiking`,
  `cycling` u `other`);
- un `trkseg` por cada tramo separado por una pausa, para no unir la traza con una línea
  recta;
- un `trkpt` por punto con latitud y longitud a 7 decimales, altitud a 1 decimal si está
  disponible y tiempo en UTC.

No se añaden extensiones propietarias: el archivo debe abrirse en cualquier lector GPX
estándar.

## JSON

El JSON es una copia completa de la sesión con el formato versionado actual (`formato: 3`):
id, actividad, inicio, fin, duración activa, marca de exportada y todos los puntos con sus
segmentos. Se escribe con sangría para que sea legible y se puede volver a importar en el
futuro sin pérdida de información.

## Puntos que no se exportan

Antes de generar los archivos se descartan los puntos con precisión peor que 40 m y los
saltos incompatibles con la velocidad máxima plausible de la actividad. Es el mismo
criterio que usa la vista de la ruta, así que las estadísticas y el archivo exportado
cuentan la misma historia.

## Errores y borrado

- Si falla un archivo, la app informa de cuántos se exportaron y cuántos fallaron, sin
  borrar la sesión local ni los archivos que sí se escribieron.
- Si la carpeta ya no es accesible, se muestra un aviso y se pide volver a elegirla en
  Ajustes.
- Al eliminar una ruta desde el detalle se puede marcar «Borrar también los archivos
  exportados (GPX y JSON)». Si no se marca, los archivos se conservan.
- Si los archivos ya no están en la carpeta, la app lo indica y elimina igualmente la
  sesión local.

## Privacidad

El contenido de los archivos incluye la traza GPS y las fechas de la ruta. La exportación
solo escribe en la carpeta que el usuario ha concedido; compartir una ruta es una acción
explícita que usa el share sheet de Android. No hay subida automática ni copia en la nube.
