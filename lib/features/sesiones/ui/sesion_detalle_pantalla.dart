import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/actividad_visual.dart';
import '../../../core/calculos/calculos_ruta.dart';
import '../../../core/models/estadisticas_ruta.dart';
import '../../../core/models/sesion.dart';
import '../../../core/utilidades/formato.dart';
import '../../exportacion/ui/acciones_exportacion.dart';
import '../../exportacion/ui/exportacion_controller.dart';
import 'historial_controller.dart';
import 'widgets/grafico_sesion.dart';
import 'widgets/mapa_ruta.dart';
import 'widgets/tabla_parciales.dart';

class SesionDetallePantalla extends StatefulWidget {
  const SesionDetallePantalla({super.key, required this.sesion});

  final Sesion sesion;

  @override
  State<SesionDetallePantalla> createState() => _SesionDetallePantallaState();
}

class _SesionDetallePantallaState extends State<SesionDetallePantalla> {
  late final EstadisticasRuta _estadisticas;
  bool _eliminando = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _estadisticas = calcularEstadisticas(
      widget.sesion.puntos,
      duracionActiva: widget.sesion.duracionActiva,
      inicio: widget.sesion.inicio,
      fin: widget.sesion.fin,
    );
  }

  Future<void> _exportar() async {
    final disponible = await asegurarDirectorioExportacion(context);
    if (!disponible || !mounted) return;
    setState(() => _exportando = true);
    final exportacion = context.read<ExportacionController>();
    final resultado = await exportacion.exportar([widget.sesion]);
    if (!mounted) return;
    setState(() => _exportando = false);
    mostrarResultadoExportacion(context, resultado, exportacion.error);
  }

  Future<void> _eliminar() async {
    final sesion = widget.sesion;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final historial = context.read<HistorialController>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ruta'),
        content: Text(
          'Se borrará la ruta de ${sesion.actividad.etiqueta.toLowerCase()} del '
          '${formatearFechaHora(sesion.inicio)}. Esta acción no se puede '
          'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _eliminando = true);
    final eliminada = await historial.eliminar(sesion);
    if (!mounted) return;
    setState(() => _eliminando = false);
    if (!eliminada) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(historial.error ?? 'No se pudo eliminar la ruta.'),
        ),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Ruta eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sesion = widget.sesion;
    final usaRitmo = sesion.actividad.usaRitmo;
    final color = sesion.actividad.color(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${sesion.actividad.etiqueta} · ${formatearFecha(sesion.inicio)}',
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar ruta',
            onPressed: _exportando ? null : _exportar,
            icon: _exportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Eliminar ruta',
            onPressed: _eliminando ? null : _eliminar,
            icon: _eliminando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(sesion.actividad.icono, color: color, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sesion.actividad.etiqueta,
                        style: tema.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatearFechaHora(sesion.inicio),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatearDuracion(sesion.duracionActiva),
                        style: tema.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MapaRuta(puntos: sesion.puntos, altura: 280),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FilaDatos(
                    izquierda: _Dato(
                      etiqueta: 'Distancia',
                      valor: formatearDistancia(_estadisticas.distanciaMetros),
                      icono: Icons.straighten,
                    ),
                    derecha: _Dato(
                      etiqueta: 'Tiempo activo',
                      valor: formatearDuracion(sesion.duracionActiva),
                      icono: Icons.timer_outlined,
                    ),
                  ),
                  const Divider(height: 28),
                  _FilaDatos(
                    izquierda: _Dato(
                      etiqueta: usaRitmo ? 'Ritmo medio' : 'Velocidad media',
                      valor: usaRitmo
                          ? formatearRitmo(_estadisticas.velocidadMedia)
                          : formatearVelocidad(_estadisticas.velocidadMedia),
                      icono: usaRitmo ? Icons.speed : Icons.speed,
                    ),
                    derecha: _Dato(
                      etiqueta: 'Velocidad máxima',
                      valor: _estadisticas.tieneVelocidad
                          ? formatearVelocidad(_estadisticas.velocidadMaxima)
                          : '—',
                      icono: Icons.bolt_outlined,
                    ),
                  ),
                  const Divider(height: 28),
                  _FilaDatos(
                    izquierda: _Dato(
                      etiqueta: 'Desnivel positivo',
                      valor: _estadisticas.tieneAltitud
                          ? '+${formatearDesnivel(_estadisticas.desnivelPositivo)}'
                          : '—',
                      icono: Icons.trending_up,
                    ),
                    derecha: _Dato(
                      etiqueta: 'Desnivel negativo',
                      valor: _estadisticas.tieneAltitud
                          ? '−${formatearDesnivel(_estadisticas.desnivelNegativo)}'
                          : '—',
                      icono: Icons.trending_down,
                    ),
                  ),
                  const Divider(height: 28),
                  _FilaDatos(
                    izquierda: _Dato(
                      etiqueta: 'Altitud mínima',
                      valor: _estadisticas.altitudMinima == null
                          ? '—'
                          : formatearMetros(_estadisticas.altitudMinima!),
                      icono: Icons.terrain,
                    ),
                    derecha: _Dato(
                      etiqueta: 'Altitud máxima',
                      valor: _estadisticas.altitudMaxima == null
                          ? '—'
                          : formatearMetros(_estadisticas.altitudMaxima!),
                      icono: Icons.landscape_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GraficoSesion(estadisticas: _estadisticas),
          const SizedBox(height: 16),
          TablaParciales(
            estadisticas: _estadisticas,
            actividad: sesion.actividad,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Tiempo total'),
                  subtitle: const Text('Incluye las pausas'),
                  trailing: Text(
                    formatearDuracion(_estadisticas.duracionTotal),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Inicio'),
                  trailing: Text(formatearHora(sesion.inicio)),
                ),
                if (sesion.fin != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sports_score),
                    title: const Text('Fin'),
                    trailing: Text(formatearHora(sesion.fin!)),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Puntos GPS'),
                  trailing: Text('${_estadisticas.puntos}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruta guardada solo en este dispositivo.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaDatos extends StatelessWidget {
  const _FilaDatos({required this.izquierda, required this.derecha});

  final Widget izquierda;
  final Widget derecha;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: izquierda),
        const SizedBox(width: 12),
        Expanded(child: derecha),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.icono,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: tema.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
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
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
