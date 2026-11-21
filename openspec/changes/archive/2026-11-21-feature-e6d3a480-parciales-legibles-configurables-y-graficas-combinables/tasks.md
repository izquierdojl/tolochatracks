# Tasks

## 1. Modelo y series

- [x] 1.1 Crear `lib/core/models/configuracion_parciales.dart` con `ModoParciales`, `ConfiguracionParciales`, las listas de pasos, el valor por defecto `distancia(1000)`, la validación y las etiquetas (`Cada 1 km`, `Cada 5 min`); verificar con tests de opciones, igualdad, `copyWith` y valores inválidos, y `flutter test` + `flutter analyze` en verde.
- [x] 1.2 Renombrar `ParcialKm` a `ParcialRuta` y añadir `altitudMedia` y `DestacadoParcial`; actualizar `EstadisticasRuta`, el cálculo y las referencias sin romper la tabla actual; verificar con `flutter test` + `flutter analyze` en verde.
- [x] 1.3 Añadir `serieVelocidadTiempo` y `serieAltitudTiempo` a `EstadisticasRuta` y construirlas en el mismo recorrido que las series por distancia, con el mismo suavizado y muestreo; verificar con tests de series por tiempo y pausas, y `flutter test` + `flutter analyze` en verde.

## 2. Cálculo de parciales

- [x] 2.1 Parametrizar `_parciales` por distancia y añadir la altitud media por tramo con los puntos válidos; verificar con tests de 500 m, 100 m, tramo final, ruta corta y altitud media, y `flutter test` + `flutter analyze` en verde.
- [x] 2.2 Añadir el modo tiempo con cortes por tiempo activo, interpolación de distancia y umbral de 10 s para el tramo final; verificar con tests de 5 min, pausa dentro del tramo y tramo final, y `flutter test` + `flutter analyze` en verde.
- [x] 2.3 Calcular los destacados entre tramos completos (mínimo tres, empates y sin movimiento) y exponerlos en `ParcialRuta`; verificar con tests de más rápido, más lento, incompleto excluido, menos de tres y empate, y `flutter test` + `flutter analyze` en verde.
- [x] 2.4 Hacer que `calcularEstadisticas` reciba `ConfiguracionParciales` y lo propague a los cortes; verificar con tests de que el valor por defecto sigue dando 1 km y de que 500 m y 5 min cambian la lista, y `flutter test` + `flutter analyze` en verde.

## 3. Persistencia

- [x] 3.1 Añadir `parciales` a `Ajustes` con el valor por defecto, las claves `config.parciales.modo` y `config.parciales.valor`, la carga tolerante y el guardado; verificar con tests de guardado, carga, clave ausente y valor inválido, y `flutter test` + `flutter analyze` en verde.
- [x] 3.2 Exponer `parciales` y `cambiarParciales` en `ConfiguracionController`, actualizando memoria, notificando y guardando; verificar con un test de persistencia entre dos instancias y `flutter test` + `flutter analyze` en verde.

## 4. Tabla de parciales

- [x] 4.1 Reescribir `TablaParciales` con la nueva estructura, cabeceras con unidades, etiquetas compactas, tipografía de 12–13 sp y cifras tabulares; verificar con un widget test de `Km 1`, `Final`, unidades en cabecera y ausencia de `/km` repetido, y `flutter test` + `flutter analyze` en verde.
- [x] 4.2 Añadir la columna de altitud y el modo estrecho (contenido menor de 340 dp) que la mueve bajo el tramo; verificar con widget tests a 411 y 360 dp, con ruta con altitud y sin altitud, y `flutter test` + `flutter analyze` en verde.
- [x] 4.3 Añadir la barra por fila con `fraccionBarra`, pista, relleno y semántica decorativa; verificar con tests de la función pura y un widget test de una barra alineada por parcial, y `flutter test` + `flutter analyze` en verde.
- [x] 4.4 Añadir los iconos de más rápido y más lento y la leyenda bajo la tabla; verificar con un widget test de destacados, empate y tramo final sin marca, y `flutter test` + `flutter analyze` en verde.
- [x] 4.5 Plegar la tabla a 10 filas con «Ver los N restantes» y «Ver menos», reiniciando el estado al cambiar la configuración; verificar con un widget test de 25 tramos y `flutter test` + `flutter analyze` en verde.
- [x] 4.6 Ajustar los estados vacíos por modo y el subtítulo «Cada … · N tramos»; verificar con widget tests de ruta corta por distancia y por tiempo, y `flutter test` + `flutter analyze` en verde.

## 5. Selector e integración

- [x] 5.1 Crear `lib/core/widgets/selector_parciales.dart` con la hoja de modo y paso, Cancelar/Listo y reset al cambiar de modo; verificar con un widget test del valor devuelto, la cancelación y el valor por defecto del modo, y `flutter test` + `flutter analyze` en verde.
- [x] 5.2 Integrar la preferencia en el detalle: leerla en `initState`, recalcular al cambiarla, persistirla y abrir la hoja desde la tarjeta; verificar con un widget test de cambio a 5 min y persistencia, y `flutter test` + `flutter analyze` en verde.
- [x] 5.3 Añadir la sección «Parciales» a Ajustes con el valor actual y la hoja compartida; verificar con un widget test de apertura y cambio, y `flutter test` + `flutter analyze` en verde.

## 6. Gráficas

- [x] 6.1 Añadir `EjeX` y los dos desplegables con claves `grafico-metrica` y `grafico-eje-x`, descripción y reglas de habilitación (Distancia fija Tiempo y Por minuto oculta X); verificar con widget tests de cambio de métrica y eje, y `flutter test` + `flutter analyze` en verde.
- [x] 6.2 Seleccionar las series por métrica y eje, formatear etiquetas y rangos (0 para distancia, velocidad y minutos; margen en altitud) y corregir el mínimo negativo; verificar con un test de `LineChart.data.minY == 0` y de altitud con margen, y `flutter test` + `flutter analyze` en verde.
- [x] 6.3 Ajustar los mensajes sin datos por combinación y el gráfico por minuto; verificar con widget tests de altitud sin datos y de metros por minuto, y `flutter test` + `flutter analyze` en verde.
- [x] 6.4 Actualizar el widget test existente que pulsaba el chip «Velocidad» para usar los desplegables; verificar `flutter test test/widget_test.dart` + `flutter analyze` en verde.

## 7. Verificación final

- [x] 7.1 Ejecutar `dart format .`, `flutter analyze` y `flutter test`; verificar la salida en verde.
- [x] 7.2 Ejecutar `npm run verify`; verificar la salida en verde.
- [x] 7.3 Revisar con una sesión sintética de 2,5 km y otra de 15 min: 1 km, 500 m, 100 m, 5 min, pausa, sin altitud, 21 km con 100 m plegado, 360 dp, tema claro y oscuro; verificar que la tabla, las barras y las gráficas se comportan como el diseño.
- [x] 7.4 Ejecutar `scripts/check_changes.sh`, `scripts/check_openspec_config.sh` y `openspec validate feature-e6d3a480-parciales-legibles-configurables-y-graficas-combinables`; verificar la salida en verde.

## Workflow follow-up

- Archivar el change tras la revisión y el commit en `dev` (código y specs).
- No tocar la versión a mano: `version.yml` la calcula al fusionar en `dev`.
