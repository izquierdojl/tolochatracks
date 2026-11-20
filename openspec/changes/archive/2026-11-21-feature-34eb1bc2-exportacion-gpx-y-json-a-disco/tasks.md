# Tasks

## 1. Generación y servicio

- [x] 1.1 Generador GPX 1.1 con escape XML, altitudes opcionales y tiempos UTC
- [x] 1.2 Exportación JSON nativa y nombres de archivo ASCII seguros
- [x] 1.3 `ServicioExportacion` sobre el canal SAF y fakes de test
- [x] 1.4 Tests de GPX, JSON, nombres y caracteres especiales

## 2. Exportación

- [x] 2.1 `ExportacionController` con progreso, errores parciales y sin carpeta
- [x] 2.2 Exportar desde el detalle, pidiendo carpeta si falta
- [x] 2.3 Exportar todo el historial visible con informe
- [x] 2.4 Tests del controlador y de la UI de exportación

## 3. Ajustes

- [x] 3.1 `ConfiguracionRepositorio` y `ConfiguracionController` (tema y carpeta)
- [x] 3.2 Pantalla de Ajustes con tema, carpeta, cambiar y quitar
- [x] 3.3 Conectar `themeMode` y proveedores en `main`
- [x] 3.4 Tests de persistencia y de la pantalla de ajustes

## 4. Verificación

- [x] 4.1 `npm run verify` en verde con formato aplicado
- [x] 4.2 Build APK y prueba en emulador: elegir carpeta, exportar una ruta y exportar todo
