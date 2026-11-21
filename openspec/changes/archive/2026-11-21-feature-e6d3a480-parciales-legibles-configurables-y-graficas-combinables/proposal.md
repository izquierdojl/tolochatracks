# Proposal

## Why

La tabla de parciales del detalle es ilegible en un móvil de 411 dp: la celda de ritmo
mide 78 dp y el texto «11:23 /km» ocupa casi todo el ancho, la unidad se repite en cada
fila, las columnas no tienen aire, el círculo del número gasta 34 dp y «Kilómetro 1»
compite con las cifras. Además, los parciales están fijados a 1 km, no muestran la altitud
del tramo ni permiten ver de un vistazo cuál fue el más rápido y el más lento, y el
gráfico de distancia arranca en −0,2.

Este change agrupa el arreglo y las mejoras en una sola entrega autocontenida: al
aplicarlo, la tabla se lee, se compara y se configura sin depender de otro change.

## What Changes

- Rediseñar la tabla de parciales: unidades en la cabecera, etiquetas compactas
  (`Km 1`, `100 m`, `5 min`, `Final`), tipografía de 12–13 sp con cifras tabulares, sin
  círculo y con separación entre columnas.
- Añadir la altitud media de cada tramo y una columna final que marque el parcial más
  rápido y el más lento entre los tramos completos (mínimo tres).
- Añadir una barra horizontal por fila, proporcional a la velocidad media de ese mismo
  tramo y alineada 1:1 con la tabla; sin selección, sin panel aparte y sin gráfico
  duplicado.
- Corregir el eje vertical de las gráficas: distancia, velocidad y metros por minuto
  empiezan en 0, la altitud conserva margen y no aparecen marcas negativas.
- Hacer configurables los parciales por distancia (100 m, 200 m, 500 m, 1 km, 5 km y
  10 km) o por tiempo activo (1, 5, 10, 15, 20, 30, 45 y 60 min), con el tiempo de pausa
  excluido y el último tramo marcado como incompleto.
- Guardar la configuración como preferencia global (`SharedPreferences`) y ofrecer el
  selector en el detalle y en Ajustes; el valor por defecto es cada 1 km.
- Sustituir los cuatro chips de gráficas por dos selectores: métrica (distancia,
  velocidad, altitud o por minuto) y eje X (tiempo o distancia), con las combinaciones
  válidas y una descripción en español.
- Añadir las series de velocidad y altitud frente a tiempo activo para que el eje X
  «tiempo» funcione en esas métricas.
- Plegar la tabla a los primeros 10 tramos con «Ver los N restantes» para que 100 m en una
  ruta larga no conviertan el detalle en una lista interminable.
- Mantener intactos el JSON de sesión, el GPX, la grabación, los mapas y los permisos; la
  única preferencia nueva es la de parciales.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `estadisticas-ruta`: parciales configurables por distancia o tiempo, altitud media por
  tramo, presentación y comparación de la tabla, series con eje de tiempo y escalas de los
  gráficos.
- `configuracion`: preferencia persistente de parciales (modo y paso) y control en
  Ajustes.

## Impact

- `lib/core/models/estadisticas_ruta.dart`: `ParcialRuta` con altitud media y destacados;
  series nuevas; `EstadisticasRuta`.
- `lib/core/models/configuracion_parciales.dart` (nuevo): modo, pasos, etiquetas y
  serialización.
- `lib/core/calculos/calculos_ruta.dart`: cortes por distancia o tiempo activo,
  interpolación, altitud media, destacados y series por tiempo.
- `lib/core/utilidades/formato.dart`: formatos cortos de ritmo, velocidad y duración, y
  etiquetas de tramo.
- `lib/features/sesiones/ui/sesion_detalle_pantalla.dart`: configuración, recálculo y
  selector.
- `lib/features/sesiones/ui/widgets/tabla_parciales.dart`: tabla, barras, destacados y
  plegado.
- `lib/features/sesiones/ui/widgets/grafico_sesion.dart`: dos selectores, series y ejes.
- `lib/features/configuracion/{data,ui}`: `Ajustes`, repositorio, controlador y sección de
  Ajustes.
- `lib/core/widgets/selector_parciales.dart` (nuevo): hoja compartida por detalle y
  Ajustes.
- Tests de cálculos, formato, repositorio/controlador y widgets; sin dependencias nuevas.

## Fuera de alcance

- Guardar los parciales en el JSON de la sesión o exportarlos al GPX/JSON.
- Configuración por sesión: la preferencia es global y se aplica al abrir cada detalle.
- Un desglose interno del parcial seleccionado o un gráfico aparte duplicando la tabla.
- Ritmo como eje Y invertido; las gráficas siguen en km/h y el ritmo vive en la tabla.
- Valores libres o perfiles personalizados de parciales.
- Cambios en grabación, mapas, permisos, segundo plano o compartición.
- Migrar sesiones antiguas: los parciales se recalculan al abrir el detalle.
