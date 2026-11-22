import 'package:material_ui/material_ui.dart';

import '../../core/models/actividad.dart';
import 'app_theme.dart';

extension ActividadVisual on Actividad {
  IconData get icono => switch (this) {
    Actividad.correr => Icons.directions_run,
    Actividad.caminar => Icons.directions_walk,
    Actividad.senderismo => Icons.hiking,
    Actividad.bicicleta => Icons.directions_bike,
    Actividad.otras => Icons.explore_outlined,
  };

  Color color(BuildContext context) {
    final colores = context.coloresRuta;
    return switch (this) {
      Actividad.correr => colores.fin,
      Actividad.caminar => colores.inicio,
      Actividad.senderismo => colores.ruta,
      Actividad.bicicleta => colores.velocidad,
      Actividad.otras => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}
