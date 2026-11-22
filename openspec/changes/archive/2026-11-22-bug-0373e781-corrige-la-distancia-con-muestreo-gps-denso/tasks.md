# Tasks

## 1. Detector de movimiento

- [x] 1.1 Implementar el detector por ventana en `lib/core/calculos/calculos_ruta.dart` con constantes con nombre (ventana de 10-12 s, desplazamiento neto mínimo, relación neto/recorrido y velocidad mínima reportada) y verificar con tests unitarios de paseo a 1,4 m/s, paseo lento a 0,8 m/s, parado con ruido y ruta con paradas.
- [x] 1.2 Añadir una muestra recortada de la sesión real de 1 Hz (con `prec` y `vel`) y del GPX de frecuencia baja en `test/fixtures/`, y una prueba de regresión que compare la distancia de cada muestra con su recorrido geométrico; verificar con `flutter test test/core/calculos_ruta_test.dart` y comprobar manualmente con los ficheros completos de `~/Nextcloud/temp` que `mal` queda dentro del 1 % de su recorrido bruto (8,648 km) y `bien` entre 8,3 y 8,5 km.

## 2. Integración en los dos cálculos

- [x] 2.1 Sustituir el filtro por segmento de `AcumuladorRuta.agregar` por el detector compartido y verificar que la distancia en vivo de una caminata a 1 Hz coincide con el recorrido y no pierde los segmentos de 1,4 m.
- [x] 2.2 Sustituir el filtro de `_acumular` por el mismo detector y verificar que la distancia total, el último valor de `serieDistancia` y la suma de los parciales coinciden salvo el tramo incompleto final.
- [x] 2.3 Verificar que el detector se reinicia al cambiar de segmento: una pausa no suma distancia, no crea una ventana que cruce el hueco y no altera el tiempo activo.

## 3. Actividad coherente

- [x] 3.1 Pasar `sesion.actividad` a `calcularEstadisticas` desde `HistorialController.estadisticas`, la tarjeta de última sesión y el resumen de finalización; verificar con un test que una sesión de Caminar con un salto por encima de 12 km/h da la misma distancia en historial y detalle.
- [x] 3.2 Añadir una prueba de coherencia entre la distancia del historial, el detalle y el resumen para una sesión con puntos suficientes; verificar que las tres cifras coinciden salvo redondeo de formato.

## 4. Documentación y verificación

- [x] 4.1 Actualizar `docs/arquitectura.md` para describir el detector de movimiento por ventana en el apartado de cálculos y comprobar que el texto no contradice las specs.
- [x] 4.2 Ejecutar `npm run verify` (configuración OpenSpec, formato, `flutter analyze` y `flutter test`) y comprobar que termina en verde.

## Workflow follow-up

- Al empezar la aplicación del change, inicializar `todowrite` con estas tareas y mantenerla sincronizada tras completar cada una.
- Archivar el change después de la revisión, con todo commiteado en `dev`, y verificar que `openspec validate` y `npm run verify` siguen en verde.
