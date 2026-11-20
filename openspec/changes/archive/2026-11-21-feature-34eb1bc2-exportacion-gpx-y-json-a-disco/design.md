# Design

## Context

`MainActivity` ya expone un canal SAF con `elegirDirectorio` y `exportar`. La sesión
serializa a JSON; solo falta generar GPX, construir nombres seguros y conectar la UI. La
app no tiene aún controlador de ajustes: el tema está fijo en `ThemeMode.system`.

## Goals / Non-Goals

**Goals:**

- Exportar GPX y JSON a una carpeta elegida, con permiso persistente.
- Informar de errores parciales.
- Ajustes reales con tema y carpeta, persistentes y testeables.

**Non-Goals:**

- Compartir con otras apps, importar o exportar a la nube.
- Mapas/acerca de (change siguiente).

## Decisions

- **Servicio de plataforma** `ServicioExportacion` (interfaz) con implementación
  `ServicioExportacionCanal` sobre `MethodChannel('.../exportacion')`. Los tests usan un
  fake que registra archivos; la app nunca toca SAF en tests.
- **Generación pura**: `gpxDeSesion(Sesion)` y `jsonDeSesion(Sesion)` en
  `lib/core/exportacion`, con escape XML propio y fechas UTC ISO 8601. El GPX usa
  `version="1.1"`, `creator="TolochaTracks"`, `metadata`, `trk`, `trkseg`, `trkpt`,
  `<ele>` solo si hay altitud y `<time>` siempre.
- **Nombres**: `tolochatracks_<YYYYMMDD>_<HHmm>_<actividad>_<id>` + `.gpx`/`.json`,
  normalizando acentos a ASCII y recortando; el id evita colisiones.
- **Exportación**: `ExportacionController` construye dos archivos por sesión, llama una
  vez al servicio con la URI y los archivos, y expone `exportando`, `error` y el último
  resultado (exportados, errores). No borra ni modifica las sesiones locales.
- **Sin carpeta**: el controlador devuelve un error tipado `sinDirectorio`; la UI pide al
  `ConfiguracionController` elegir carpeta y reintenta solo si se eligió.
- **Ajustes**: `ConfiguracionRepositorio` sobre `shared_preferences` con claves
  versionadas; `ConfiguracionController` notifica y `MaterialApp` consume el `themeMode`.
  La URI y el nombre de la carpeta se guardan juntos; quitar la carpeta borra ambos.
- **UI**: `ConfiguracionPantalla` con tema segmentado y sección de exportación; botón
  «Exportar ruta» en el `AppBar` del detalle y «Exportar todo» en la cabecera del
  historial. Mensajes de éxito/errores parciales en `SnackBar`.
- **Tests**: GPX/JSON/nombres puros; controlador con fake; ajustes con
  `SharedPreferences.setMockInitialValues`; widget de ajustes y exportación.

## Risks / Trade-offs

- **Archivos grandes**: se envían contenidos por platform channel; para rutas enormes
  puede consumir memoria. Si el uso lo exige, se cambiará a escribir temporales y copiar
  por ruta en un change futuro.
- **Permisos SAF**: el proveedor puede perder el permiso o no aceptar tipos MIME; se
  notifica el error y se pide reelegir carpeta.
- **Sobrescritura**: se usa un id único por sesión; si se exporta dos veces la misma
  sesión, el archivo se reemplaza (comportamiento esperado).
