import 'package:flutter/material.dart';

import '../../../../core/models/actividad.dart';
import '../../../../core/models/estadisticas_ruta.dart';
import '../../../../core/utilidades/formato.dart';

class TablaParciales extends StatelessWidget {
  const TablaParciales({
    super.key,
    required this.estadisticas,
    required this.actividad,
  });

  final EstadisticasRuta estadisticas;
  final Actividad actividad;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final usaRitmo = actividad.usaRitmo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              usaRitmo
                  ? 'Tiempo y ritmo por kilómetro, incluido el último tramo'
                  : 'Tiempo y velocidad por kilómetro, incluido el último tramo',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (estadisticas.parciales.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay distancia suficiente para calcular parciales '
                  '(mínimo 20 metros).',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  SizedBox(
                    width: 64,
                    child: Text(
                      'Tiempo',
                      textAlign: TextAlign.end,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: Text(
                      usaRitmo ? 'Ritmo' : 'Velocidad',
                      textAlign: TextAlign.end,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              for (final parcial in estadisticas.parciales) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tema.colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${parcial.numero}',
                        style: tema.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        parcial.completo
                            ? 'Kilómetro ${parcial.numero}'
                            : 'Parcial ${parcial.numero} · '
                                  '${formatearDistanciaCorta(parcial.distanciaMetros)}',
                        style: tema.textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        formatearDuracion(parcial.duracion),
                        textAlign: TextAlign.end,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 78,
                      child: Text(
                        usaRitmo
                            ? formatearRitmo(parcial.velocidadMedia)
                            : formatearVelocidad(parcial.velocidadMedia),
                        textAlign: TextAlign.end,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
