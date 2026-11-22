# Documentación de TolochaTracks

Este directorio guarda la documentación técnica. La portada del repositorio
([`README.md`](../README.md)) está pensada para quien quiere instalar y usar la app; aquí
está lo que necesita quien va a desarrollar, publicar o auditar el proyecto.

| Documento | Para quién | Contenido |
|---|---|---|
| [`desarrollo.md`](desarrollo.md) | Quien empieza a contribuir | Requisitos, comandos, estructura, tests y flujo OpenSpec. |
| [`arquitectura.md`](arquitectura.md) | Quien toca el código | Capas, estado, modelo de sesión, persistencia, grabación, mapas y servicios. |
| [`exportacion.md`](exportacion.md) | Quien usa o depura GPX/JSON | Formato de archivos, SAF, nombres, filtros y errores. |
| [`releases.md`](releases.md) | Quien publica versiones | Semver, ramas, CI/CD, firma y APK. |
| [`privacidad-y-mapas.md`](privacidad-y-mapas.md) | Quien revisa permisos o datos | Almacenamiento local, permisos, batería, teselas, atribución y modo sin conexión. |
| [`capturas/`](capturas/) | Documentación y presentación | Capturas reales de la app usadas en el README. |

La constitución del proyecto, las reglas de gobernanza y los acuerdos que no se
renegocian están en [`AGENTS.md`](../AGENTS.md). Ese documento prevalece sobre esta
documentación y sobre los skills generados por `openspec update`.

## Recorridos rápidos

- **Quiero ejecutar la app:** [`desarrollo.md`](desarrollo.md).
- **Quiero entender cómo se guarda una ruta:** [`arquitectura.md`](arquitectura.md).
- **Quiero exportar o importar GPX:** [`exportacion.md`](exportacion.md).
- **Quiero publicar una versión:** [`releases.md`](releases.md).
- **Quiero revisar qué datos salen del dispositivo:** [`privacidad-y-mapas.md`](privacidad-y-mapas.md).

## OpenSpec

Los changes activos y archivados viven en `openspec/`. La configuración personalizada
está en [`openspec/config.yaml`](../openspec/config.yaml) y el flujo se explica en
[`desarrollo.md`](desarrollo.md#flujo-de-trabajo-con-openspec).
