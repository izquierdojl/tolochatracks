import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../configuracion/ui/configuracion_controller.dart';

class ConfiguracionPantalla extends StatelessWidget {
  const ConfiguracionPantalla({super.key});

  Future<void> _elegirCarpeta(BuildContext context) async {
    final configuracion = context.read<ConfiguracionController>();
    final directorio = await configuracion.elegirDirectorioExportacion();
    if (!context.mounted) return;
    final error = configuracion.ultimoError;
    if (directorio == null && error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _quitarCarpeta(BuildContext context) async {
    final configuracion = context.read<ConfiguracionController>();
    final quitar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar carpeta'),
        content: const Text(
          'Las rutas ya exportadas no se borran. La próxima exportación te '
          'pedirá elegir una carpeta de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (quitar == true) {
      await configuracion.quitarDirectorioExportacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = context.watch<ConfiguracionController>();
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Seccion(titulo: 'Apariencia'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '«Sistema» sigue el modo claro u oscuro del dispositivo.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Sistema'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {configuracion.tema},
                    onSelectionChanged: (seleccion) =>
                        configuracion.cambiarTema(seleccion.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Seccion(titulo: 'Exportación'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Carpeta de exportación'),
                subtitle: Text(
                  configuracion.directorioExportacionNombre ??
                      'Sin configurar · se pedirá al exportar',
                ),
                trailing: configuracion.tieneDirectorio
                    ? IconButton(
                        tooltip: 'Quitar carpeta',
                        onPressed: () => _quitarCarpeta(context),
                        icon: const Icon(Icons.delete_outline),
                      )
                    : null,
                onTap: () => _elegirCarpeta(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cada ruta se exporta como GPX 1.1 y JSON. Los archivos se '
                      'escriben solo en la carpeta que elijas.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () => _elegirCarpeta(context),
                      icon: const Icon(Icons.folder_open),
                      label: Text(
                        configuracion.tieneDirectorio
                            ? 'Cambiar carpeta'
                            : 'Elegir carpeta',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Seccion(titulo: 'Privacidad'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Tus rutas se quedan en tu móvil'),
            subtitle: const Text(
              'No hay cuentas ni subida a servidores. Solo se accede a la red '
              'para las teselas del mapa, que puedes no usar.',
            ),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        titulo.toUpperCase(),
        style: tema.textTheme.labelSmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
