# Tasks

## 1. Modelo y serialización

- [x] 1.1 Añadir `segmento` (int, por defecto 0) a `PuntoRuta`, serializarlo como `seg` solo si es mayor que 0 y conservarlo en copias; verificar con tests de ida y vuelta y con un JSON antiguo sin `seg`, y `flutter analyze` en verde.
- [x] 1.2 Subir `formatoSesionActual` a 3, inferir segmentos en `Sesion.desdeJson` para formatos anteriores usando huecos de más de 60 s y respetar `seg` en formato 3; verificar con tests de formato 2, formato 3 y `seg` inválido, y `flutter analyze` en verde.
- [x] 1.3 Asegurar que el borrador y `Sesion.copiaCon` conservan los segmentos y el formato actual; verificar con un test de guardado/recuperación de borrador y `flutter analyze` en verde.

## 2. Cálculos

- [x] 2.1 Hacer que `AcumuladorRuta` corte al cambiar de segmento: el primer punto del segmento no suma distancia ni velocidad y no se compara con el anterior; verificar con un test de dos segmentos y un salto de 80 m, y `flutter analyze` en verde.
- [x] 2.2 Ajustar `_puntosValidos`, `_acumular`, series, parciales y por minuto para excluir la pausa del tiempo activo y no sumar distancia entre segmentos; verificar con tests de series, parciales y minutos con una pausa intermedia, y `flutter analyze` en verde.

## 3. Captura

- [x] 3.1 Añadir `_segmentoActual` a `GrabacionController`, incrementarlo al reanudar y asignarlo a los puntos nuevos; el primer punto del segmento no se filtra contra el anterior; verificar con tests de pausa/reanudación y `flutter analyze` en verde.
- [x] 3.2 Restaurar el segmento al recuperar un borrador y mantener el comportamiento desde la notificación (Pausar/Reanudar); verificar con tests del controlador y de las acciones de notificación, y `flutter analyze` en verde.

## 4. Exportación y mapa

- [x] 4.1 Exportar el GPX con un `<trkseg>` por segmento y sin puntos de unión; verificar con un test de una sesión con dos pausas y otro de una sesión antigua con hueco, y `flutter analyze` en verde.
- [x] 4.2 Dibujar una polilínea por segmento en `MapaRuta`, sin unir los extremos de la pausa, tanto en el detalle como durante la grabación; verificar con un widget test que cuente las polilíneas y `flutter analyze` en verde.

## 5. Integración

- [x] 5.1 Comprobar que el detalle usa los segmentos inferidos y el tiempo activo en el mapa y el gráfico; verificar con un test de widget o de integración con una sesión sintética con pausa, y `flutter analyze` en verde.
- [x] 5.2 Ejecutar `npm run verify` y comprobar que formato, análisis y tests están en verde.

## Workflow follow-up

- Archivar el change después de la revisión y del commit en `dev`.
- No tocar la versión a mano: `version.yml` la calcula al fusionar en `dev`.
