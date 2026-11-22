# Design

## Context

`Sesion` es inmutable y se serializa a JSON versionado; `SesionesRepositorio` guarda una
sesión por archivo de forma atómica y tolera archivos corruptos. `ExportacionController`
conoce el resultado agregado de la exportación (archivos escritos y errores), pero no qué
sesión quedó completa. El canal SAF de `MainActivity` ya escribe en la carpeta concedida y
sabe buscar y borrar documentos. `HistorialController` mantiene la lista en memoria y es
quien persiste los cambios de las sesiones. Ver `proposal.md` y las deltas de
`exportacion-sesiones` e `historial-sesiones`.

## Goals / Non-Goals

**Goals:**

- Persistir si la última exportación de cada sesión completó GPX y JSON.
- Mostrar el estado con un check en historial y detalle.
- Ofrecer el borrado de los archivos exportados al eliminar la ruta, sin borrarlos por
  defecto.
- Informar de errores parciales sin dejar el historial inconsistente.

**Non-Goals:**

- Verificar la existencia física de los archivos en cada arranque.
- Recordar la carpeta exacta de cada exportación histórica.
- Borrado masivo o limpieza automática de la carpeta.

## Decisions

- **El estado vive en la sesión (`exportada: bool`), no en `shared_preferences`.** Así el
  check viaja con la sesión, sobrevive a reinicios y no hay dos fuentes de verdad. El JSON
  pasa a formato 2; `desdeJson` trata la ausencia del campo como `false`, por lo que las
  sesiones antiguas siguen cargando. Alternativa descartada: un registro aparte de ids en
  preferencias, que puede desincronizarse si se borra o restaura una sesión.
- **El check refleja la última exportación intentada, no solo la primera.** El servicio
  nativo devuelve los nombres de los archivos escritos; el controlador considera completa
  una sesión solo si aparecen su GPX y su JSON. `HistorialController.actualizarExportadas`
  recibe las sesiones intentadas y las correctas, actualiza `exportada` en todas y guarda
  las que cambian. Si una reexportación falla, la marca se desactiva: el exportador borra
  el archivo anterior antes de escribir el nuevo, así que no se puede afirmar que la copia
  sigue completa. Alternativa descartada: marcar solo los éxitos y no limpiar nunca, que
  dejaría un check falso tras un fallo.
- **La actualización del estado la orquesta la UI tras exportar.** `ExportacionController`
  calcula `sesionesExportadas` a partir del resultado y del nombre de archivo de cada
  sesión; el detalle o el historial llaman a `HistorialController.actualizarExportadas`.
  Así el controlador de exportación no depende del repositorio de sesiones. Si falla el
  guardado, la lista en memoria se actualiza igualmente y la UI avisa de que el estado
  puede no conservarse.
- **Borrado con el mismo canal SAF.** Se añade `borrar` al canal de exportación con la URI
  de la carpeta y los nombres `nombreGpx`/`nombreJson`; devuelve borrados, no encontrados
  y errores. Se usa la carpeta configurada en ese momento. Si se cambió de carpeta, los
  archivos de la anterior no se localizan y se informa como «no encontrados».
- **Primero la sesión local, después los archivos.** Si falla el borrado local, no se
  tocan los archivos externos y el detalle sigue abierto. Si el borrado local funciona y
  el externo falla, la ruta desaparece y se informa de los archivos que quedan; es
  preferible a perder archivos y conservar la ruta. Alternativa descartada: borrar primero
  los archivos externos, que podría dejar una ruta viva sin sus copias.
- **Casilla desmarcada por defecto.** Borrar documentos del usuario es destructivo; la
  opción se ofrece solo si `exportada` es verdadera y se indica la carpeta. Sin carpeta o
  sin permiso, se explica y se permite eliminar solo la ruta. El diálogo se implementa
  como widget propio para poder testearlo.
- **UI del check.** La tarjeta del historial añade un icono de check con etiqueta
  semántica «Exportada a disco»; el detalle muestra el mismo texto en la cabecera de la
  ruta. Los colores salen del tema y no hay literales.

## Risks / Trade-offs

- **Archivos borrados fuera de la app** → el check sigue mostrando la última exportación
  registrada; se documenta como limitación y el diálogo de borrado informa si no encuentra
  los archivos.
- **Cambio de carpeta de exportación** → el borrado solo busca en la carpeta actual; los
  archivos de carpetas anteriores quedan fuera del alcance y se informa como no
  encontrados.
- **Permiso SAF perdido** → la sesión local se elimina y se muestra el error; los archivos
  se pueden borrar desde el gestor de archivos.
- **Fallo al guardar el estado** → la marca se ve en memoria pero puede perderse al
  reiniciar; la UI lo advierte sin impedir la exportación.
- **Reexportación fallida** → la marca se desactiva aunque el archivo anterior pudiera
  seguir existiendo; se prefiere no afirmar que la copia está completa.
- **Proveedores SAF que no permiten borrar** → se informa de los errores parciales y la
  sesión local ya está eliminada.

## Migration Plan

- Las sesiones antiguas se leen con `exportada = false`; no se reescriben hasta que se
  exporten o se actualice su estado.
- El formato 2 es compatible hacia atrás: la app anterior ignora el campo nuevo y sigue
  leyendo el resto de la sesión.
- No hay migración de datos ni cambios de permisos.
