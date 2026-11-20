import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/actividad_visual.dart';
import '../../../core/models/actividad.dart';
import '../../../core/models/estadisticas_ruta.dart';
import '../../../core/models/sesion.dart';
import '../../../core/utilidades/formato.dart';
import 'historial_controller.dart';
import 'sesion_detalle_pantalla.dart';

class HistorialPantalla extends StatelessWidget {
  const HistorialPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<HistorialController>();
    return switch (historial.estado) {
      EstadoHistorial.cargando => const Center(
        child: CircularProgressIndicator(),
      ),
      EstadoHistorial.error => _ErrorHistorial(
        mensaje: historial.error ?? 'No se pudo leer el historial.',
        onReintentar: historial.cargar,
      ),
      EstadoHistorial.vacio => const _HistorialVacio(),
      EstadoHistorial.datos => _ListaHistorial(historial: historial),
    };
  }
}

class _ListaHistorial extends StatelessWidget {
  const _ListaHistorial({required this.historial});

  final HistorialController historial;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sesiones = historial.sesionesFiltradas;
    return RefreshIndicator(
      onRefresh: historial.cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tema.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Resumen(
                    etiqueta: 'Rutas',
                    valor: '${sesiones.length}',
                  ),
                ),
                Expanded(
                  child: _Resumen(
                    etiqueta: 'Distancia',
                    valor: formatearDistanciaCorta(
                      historial.distanciaTotalMetros,
                    ),
                  ),
                ),
                Expanded(
                  child: _Resumen(
                    etiqueta: 'Tiempo',
                    valor: formatearDuracion(historial.duracionTotal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: historial.filtro == null,
                onSelected: (_) => historial.cambiarFiltro(null),
              ),
              for (final actividad in Actividad.values)
                ChoiceChip(
                  avatar: Icon(actividad.icono, size: 18),
                  label: Text(actividad.etiqueta),
                  selected: historial.filtro == actividad,
                  onSelected: (_) => historial.cambiarFiltro(actividad),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (sesiones.isEmpty)
            _FiltroVacio(actividad: historial.filtro)
          else
            for (final sesion in sesiones) ...[
              _TarjetaSesion(
                sesion: sesion,
                estadisticas: historial.estadisticas(sesion),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.etiqueta, required this.valor});

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
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          etiqueta,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({required this.sesion, required this.estadisticas});

  final Sesion sesion;
  final EstadisticasRuta estadisticas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = sesion.actividad.color(context);
    final usaRitmo = sesion.actividad.usaRitmo;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SesionDetallePantalla(sesion: sesion),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sesion.actividad.icono, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sesion.actividad.etiqueta,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatearFechaHora(sesion.inicio),
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _Dato(
                          valor: formatearDistanciaCorta(
                            estadisticas.distanciaMetros,
                          ),
                        ),
                        _Dato(valor: formatearDuracion(sesion.duracionActiva)),
                        _Dato(
                          valor: usaRitmo
                              ? formatearRitmo(estadisticas.velocidadMedia)
                              : formatearVelocidad(estadisticas.velocidadMedia),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroVacio extends StatelessWidget {
  const _FiltroVacio({required this.actividad});

  final Actividad? actividad;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final nombre = actividad?.etiqueta ?? 'esta actividad';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 40,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'No hay rutas de $nombre',
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.read<HistorialController>().cambiarFiltro(null),
              child: const Text('Ver todas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor});

  final String valor;

  @override
  Widget build(BuildContext context) {
    return Text(
      valor,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: tema.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay rutas',
              style: tema.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa Grabar para registrar tu primera ruta. Aparecerá aquí al '
              'terminar.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorHistorial extends StatelessWidget {
  const _ErrorHistorial({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
