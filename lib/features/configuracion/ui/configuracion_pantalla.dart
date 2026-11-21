import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/perfil_gps.dart';
import '../../../core/models/proveedor_mapas.dart';
import '../../../core/servicios/bateria.dart';
import '../../../core/widgets/selector_parciales.dart';
import 'acerca_de_pantalla.dart';
import 'configuracion_controller.dart';

class ConfiguracionPantalla extends StatefulWidget {
  const ConfiguracionPantalla({super.key});

  @override
  State<ConfiguracionPantalla> createState() => _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends State<ConfiguracionPantalla>
    with WidgetsBindingObserver {
  final ServicioBateria _bateria = const ServicioBateriaCanal();
  late Future<bool?> _exentoBateria;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _exentoBateria = _bateria.estaExento();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _exentoBateria = _bateria.estaExento());
    }
  }

  Future<void> _pedirExencionBateria() async {
    await _bateria.pedirExencion();
    if (!mounted) return;
    setState(() => _exentoBateria = _bateria.estaExento());
  }

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

  Future<void> _elegirParciales(BuildContext context) async {
    final configuracion = context.read<ConfiguracionController>();
    final nueva = await mostrarSelectorParciales(
      context,
      actual: configuracion.parciales,
    );
    if (nueva == null || !context.mounted) return;
    try {
      await configuracion.cambiarParciales(nueva);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la preferencia de parciales.'),
        ),
      );
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
        _Seccion(titulo: 'Mapas'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ProveedorMapas>(
                  initialValue: configuracion.proveedorMapas,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor de teselas',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final proveedor in ProveedorMapas.values)
                      DropdownMenuItem(
                        value: proveedor,
                        child: Text(proveedor.etiqueta),
                      ),
                  ],
                  onChanged: (proveedor) {
                    if (proveedor != null) {
                      configuracion.cambiarProveedorMapas(proveedor);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  configuracion.proveedorMapas.activo
                      ? 'Las teselas se descargan del proveedor elegido y '
                            'necesitan conexión. La ruta se guarda igualmente '
                            'sin mapas.'
                      : 'Los mapas están desactivados: no se descargan teselas. '
                            'La grabación, las estadísticas y la exportación '
                            'siguen funcionando.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Seccion(titulo: 'GPS'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calidad GPS',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La app ajusta la frecuencia de captura y el filtro. La '
                  'precisión real depende del móvil y del entorno.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<PerfilGps>(
                    showSelectedIcon: false,
                    segments: [
                      for (final perfil in PerfilGps.values)
                        ButtonSegment(
                          value: perfil,
                          label: Text(perfil.etiqueta),
                        ),
                    ],
                    selected: {configuracion.perfilGps},
                    onSelectionChanged: (seleccion) =>
                        configuracion.cambiarPerfilGps(seleccion.first),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  configuracion.perfilGps.descripcion,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Seccion(titulo: 'Parciales'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.stacked_bar_chart),
            title: const Text('Parciales por defecto'),
            subtitle: Text(configuracion.parciales.descripcion),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _elegirParciales(context),
          ),
        ),
        const SizedBox(height: 20),
        _Seccion(titulo: 'Batería'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_saver, color: tema.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Grabación en segundo plano',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Android puede limitar el GPS con la pantalla apagada. '
                  'Permitir que TolochaTracks funcione sin restricciones mejora '
                  'la fiabilidad de las rutas largas; también puede aumentar el '
                  'consumo de batería.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<bool?>(
                  future: _exentoBateria,
                  builder: (context, snapshot) {
                    final exento = snapshot.data;
                    final comprobando =
                        snapshot.connectionState == ConnectionState.waiting;
                    final texto = comprobando
                        ? 'Comprobando el estado…'
                        : exento == true
                        ? 'Permitido: Android no limitará la grabación.'
                        : exento == false
                        ? 'Optimizado por el sistema.'
                        : 'No disponible en esta plataforma.';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(texto, style: tema.textTheme.bodyMedium),
                        if (exento != true && !comprobando) ...[
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: _pedirExencionBateria,
                            icon: const Icon(Icons.battery_charging_full),
                            label: const Text('Permitir sin restricciones'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'En algunos fabricantes (Xiaomi, Huawei, Samsung…) también '
                  'conviene permitir el inicio automático de la app en sus '
                  'ajustes del sistema.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
        const SizedBox(height: 20),
        _Seccion(titulo: 'Información'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de TolochaTracks'),
            subtitle: const Text('Versión, privacidad y licencias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AcercaDePantalla()),
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
