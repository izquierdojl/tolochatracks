# Design

## Context

La grabación ya persiste `Sesion` en JSON y `HistorialController` lista sesiones y cachea
estadísticas. Falta navegación al detalle, filtros y eliminación. La app mantiene el shell
con `IndexedStack`; el detalle se abre como ruta nueva con su propio `Scaffold`.

## Goals / Non-Goals

**Goals:**

- Historial útil como pantalla principal de consulta, con totales y filtros.
- Detalle legible de todas las estadísticas sin recalcular en cada frame.
- Eliminación segura y consistente con el estado del historial.

**Non-Goals:**

- Gráficos, mapas, parciales y exportación (changes posteriores).
- Edición o recorte de sesiones.

## Decisions

- **Filtro en el controlador**: `Actividad? filtro` y `sesionesFiltradas`; los totales se
  calculan sobre la lista filtrada. El filtro no se persiste (vive con la pantalla) para
  mantener el arranque simple.
- **Caché de estadísticas** por id, ya existente; al eliminar se invalida la entrada.
- **Detalle** recibe la `Sesion` completa (los puntos ya están en memoria desde el
  listado) y calcula una sola vez `EstadisticasRuta` en `initState`. No hace peticiones.
- **Eliminación** desde el menú del `AppBar` del detalle y con confirmación; el controlador
  borra el archivo y la lista, y la pantalla hace `pop` con un resultado. El historial se
  reconstruye por `notifyListeners`.
- **Navegación** con `MaterialPageRoute` propia del detalle; no se añade un router
  declarativo para una sola pantalla.
- **Formato** consistente con la grabación: `formatearDistancia`, `formatearDuracion`,
  `formatearRitmo`/`formatearVelocidad` y `formatearFechaHora`.
- **Detalle preparado para crecer**: se organiza en tarjetas (cabecera, estadísticas,
  datos) para insertar mapa, gráficos y parciales en los siguientes changes sin rehacerlo.

## Risks / Trade-offs

- Cargar todas las sesiones con puntos al inicio puede crecer con el uso; para el alcance
  personal es aceptable y el parseo es tolerante. Si hiciera falta, se añadiría un índice
  o carga perezosa en un change futuro.
- El detalle recibe datos ya cargados; si el archivo se borra por fuera, la pantalla sigue
  mostrando la copia en memoria hasta volver. Aceptable.
