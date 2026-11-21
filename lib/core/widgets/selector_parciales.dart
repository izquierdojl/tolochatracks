import 'package:material_ui/material_ui.dart';

import '../models/configuracion_parciales.dart';

Future<ConfiguracionParciales?> mostrarSelectorParciales(
  BuildContext context, {
  required ConfiguracionParciales actual,
}) {
  return showModalBottomSheet<ConfiguracionParciales>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SelectorParciales(actual: actual),
  );
}

class _SelectorParciales extends StatefulWidget {
  const _SelectorParciales({required this.actual});

  final ConfiguracionParciales actual;

  @override
  State<_SelectorParciales> createState() => _SelectorParcialesState();
}

class _SelectorParcialesState extends State<_SelectorParciales> {
  late ConfiguracionParciales _borrador = widget.actual;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parciales',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige cómo se divide la ruta. El último tramo puede ser más '
              'corto.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ModoParciales>(
                showSelectedIcon: false,
                segments: [
                  for (final modo in ModoParciales.values)
                    ButtonSegment(value: modo, label: Text(modo.etiqueta)),
                ],
                selected: {_borrador.modo},
                onSelectionChanged: (seleccion) {
                  final modo = seleccion.first;
                  setState(() {
                    _borrador = modo == ModoParciales.distancia
                        ? ConfiguracionParciales.porDefectoDistancia
                        : ConfiguracionParciales.porDefectoPorTiempo;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cada',
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final valor in _borrador.opciones)
                  ChoiceChip(
                    label: Text(_etiqueta(_borrador.modo, valor)),
                    selected: _borrador.valor == valor,
                    onSelected: (_) {
                      setState(() {
                        _borrador = _conValor(_borrador.modo, valor);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('selector-parciales-listo'),
                  onPressed: () => Navigator.of(context).pop(_borrador),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _etiqueta(ModoParciales modo, int valor) =>
      modo == ModoParciales.distancia
      ? ConfiguracionParciales.distancia(valor).etiquetaPaso
      : ConfiguracionParciales.tiempo(Duration(seconds: valor)).etiquetaPaso;

  static ConfiguracionParciales _conValor(ModoParciales modo, int valor) =>
      modo == ModoParciales.distancia
      ? ConfiguracionParciales.distancia(valor)
      : ConfiguracionParciales.tiempo(Duration(seconds: valor));
}
