import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/actividad_visual.dart';
import '../../../../core/models/actividad.dart';

class SelectorActividad extends StatelessWidget {
  const SelectorActividad({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
    this.habilitado = true,
  });

  final Actividad seleccionada;
  final ValueChanged<Actividad> onSeleccionar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final actividad in Actividad.values)
          ChoiceChip(
            selected: actividad == seleccionada,
            onSelected: habilitado ? (_) => onSeleccionar(actividad) : null,
            avatar: Icon(actividad.icono, size: 18),
            label: Text(actividad.etiqueta),
          ),
      ],
    );
  }
}
