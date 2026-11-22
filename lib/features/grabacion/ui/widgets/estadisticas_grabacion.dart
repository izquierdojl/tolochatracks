import 'package:material_ui/material_ui.dart';

import '../../../../core/utilidades/formato.dart';
import '../grabacion_controller.dart';

class EstadisticasGrabacion extends StatelessWidget {
  const EstadisticasGrabacion({super.key, required this.controlador});

  final GrabacionController controlador;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final usaRitmo = controlador.actividad.usaRitmo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          children: [
            Text(
              formatearDuracion(controlador.duracionActiva),
              style: tema.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'tiempo activo',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Dato(
                    etiqueta: 'Distancia',
                    valor: formatearDistancia(controlador.distanciaMetros),
                  ),
                ),
                Expanded(
                  child: _Dato(
                    etiqueta: usaRitmo ? 'Ritmo medio' : 'Velocidad media',
                    valor: usaRitmo
                        ? formatearRitmo(controlador.velocidadMedia)
                        : formatearVelocidad(controlador.velocidadMedia),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Dato(
                    etiqueta: 'Velocidad actual',
                    valor: formatearVelocidad(controlador.velocidadActual),
                  ),
                ),
                Expanded(
                  child: _Dato(
                    etiqueta: 'Desnivel +',
                    valor: formatearDesnivel(controlador.desnivelPositivo),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: tema.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          etiqueta,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
