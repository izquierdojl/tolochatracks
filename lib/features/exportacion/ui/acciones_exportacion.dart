import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/servicios/exportacion.dart';
import '../../configuracion/ui/configuracion_controller.dart';

Future<bool> asegurarDirectorioExportacion(BuildContext context) async {
  final configuracion = context.read<ConfiguracionController>();
  if (configuracion.tieneDirectorio) return true;
  final elegir = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Elige una carpeta'),
      content: const Text(
        'Las rutas se guardarán como GPX y JSON en la carpeta que elijas. '
        'Puedes cambiarla después en Ajustes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elegir carpeta'),
        ),
      ],
    ),
  );
  if (elegir != true || !context.mounted) return false;
  final directorio = await configuracion.elegirDirectorioExportacion();
  if (!context.mounted) return false;
  if (directorio == null) {
    final error = configuracion.ultimoError;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
    return false;
  }
  return true;
}

void mostrarResultadoExportacion(
  BuildContext context,
  ResultadoExportacion? resultado,
  String? error,
) {
  final mensaje = resultado == null
      ? error ?? 'No se pudo exportar.'
      : resultado.correcto
      ? '${resultado.exportados} archivos exportados.'
      : '${resultado.exportados} archivos exportados; '
            '${resultado.errores.length} fallaron.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}
