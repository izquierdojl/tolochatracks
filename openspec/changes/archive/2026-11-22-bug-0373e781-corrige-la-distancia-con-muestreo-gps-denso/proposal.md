# Proposal

## Why

La distancia de una ruta grabada con el perfil GPS **Máxima** (un punto por segundo)
puede quedar muy por debajo de la real. En la ruta del 22 de noviembre de 2026
(Calanda - Foz Calanda), el GPX contiene 8,648 km y la app calculó 5,778 km: se
perdieron 2,870 km (33,2 %). La causa es un filtro de ruido que descarta todo segmento
de menos de 1,5 m, aunque sea movimiento real; con un punto por segundo ese umbral
equivale a 5,4 km/h, justo por debajo del ritmo de una caminata normal. El mismo filtro,
a la inversa, suma kilómetros fantasma cuando se está parado con ruido GPS.

El fallo afecta a la distancia en vivo, al detalle, al historial, al ritmo medio, a los
gráficos y a los parciales. No afecta a la captura: el GPX exportado conserva la traza
completa. Al corregir el cálculo, las sesiones ya guardadas se recalculan al abrirlas,
sin migración ni necesidad de volver a grabar.

## What Changes

- Sustituir el descarte por segmento aislado (`distancia < 1,5 m` y `segundos < 10`) por
  un detector de movimiento por ventana temporal: solo cuenta el segmento si en los
  últimos 10-12 s el desplazamiento neto supera el ruido y se parece al recorrido, o si
  el GPS reporta una velocidad mínima de movimiento.
- Aplicar la misma decisión en la distancia en vivo y en el cálculo de series,
  parciales, distancia por minuto e historial, de modo que todas las cifras coincidan.
- Pasar siempre la actividad de la sesión al cálculo de estadísticas para que el
  historial, el resumen y el detalle apliquen el mismo tope de velocidad plausible.
- Añadir pruebas de regresión con trazas sintéticas (caminata a 1 Hz, parado con ruido,
  paseo lento, paradas) y con los GPX reales que motivaron el fallo.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `grabacion-rutas`: la distancia SHALL filtrar el ruido según movimiento sostenido en
  una ventana temporal, no según un umbral fijo por muestra. SHALL contar el movimiento
  lento con muestreo denso y SHALL NOT sumar ruido de una persona parada.
- `estadisticas-ruta`: la distancia total, las series, los parciales y la distancia por
  minuto SHALL usar la misma distancia válida y la actividad de la sesión; el detalle,
  el historial y los resúmenes SHALL mostrar cifras coherentes.

## Fuera de alcance

- Rediseñar el autoguardado del borrador (tamaño, frecuencia, escritura atómica y
  carrera con la finalización). Se tratará en un change aparte.
- Cambiar el aviso de «señal débil» cuando la persona está parada y no llegan posiciones.
- Corregir la altitud: la app usa altura sobre el nivel del mar y es la correcta; la
  diferencia con otras apps que exportan altura elipsoidal no es un fallo.
- Suavizar, simplificar o recortar la traza del mapa y del GPX.
- Cambiar los perfiles GPS, sus intervalos, filtros o precisiones.
- Cambiar el formato de exportación GPX/JSON o añadir extensiones de precisión/velocidad.
- Alterar la interfaz: los mismos campos y pantallas, con cifras correctas.

## Impact

- `lib/core/calculos/calculos_ruta.dart`: detector de movimiento compartido por
  `AcumuladorRuta.agregar` y `_acumular`; constantes y documentación del criterio.
- `lib/features/sesiones/ui/historial_controller.dart` y
  `lib/features/grabacion/ui/grabacion_pantalla.dart`: pasar `sesion.actividad` a
  `calcularEstadisticas`.
- `test/core/calculos_ruta_test.dart` y, si procede, `test/features/` con trazas de
  regresión; no se añaden dependencias ni permisos.
- Sin cambios de modelo, formato de sesión, exportación, mapas ni red. Las sesiones
  existentes se recalculan en memoria al abrirlas.
- Android es la única plataforma; el cambio es común a todos los perfiles, aunque el
  fallo se manifiesta sobre todo con Máxima.
