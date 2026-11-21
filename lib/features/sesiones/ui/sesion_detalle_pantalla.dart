import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/actividad_visual.dart';
import '../../../core/calculos/calculos_ruta.dart';
import '../../../core/models/configuracion_parciales.dart';
import '../../../core/models/estadisticas_ruta.dart';
import '../../../core/models/sesion.dart';
import '../../../core/utilidades/formato.dart';
import '../../../core/widgets/selector_parciales.dart';
import '../../compartir/ui/compartir_controller.dart';
import '../../configuracion/ui/configuracion_controller.dart';
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
  late EstadisticasRuta _estadisticas;
  late ConfiguracionParciales _parciales;
  bool _eliminando = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _parciales = context.read<ConfiguracionController>().parciales;
    _estadisticas = _calcularEstadisticas(_parciales);
  }

  EstadisticasRuta _calcularEstadisticas(ConfiguracionParciales parciales) {
    return calcularEstadisticas(
      widget.sesion.puntos,
      duracionActiva: widget.sesion.duracionActiva,
      inicio: widget.sesion.inicio,
      fin: widget.sesion.fin,
      actividad: widget.sesion.actividad,
      parciales: parciales,
    );
  }

  Future<void> _configurarParciales() async {
    final configuracion = context.read<ConfiguracionController>();
    final nueva = await mostrarSelectorParciales(context, actual: _parciales);
    if (!mounted || nueva == null || nueva == _parciales) return;
    setState(() {
      _parciales = nueva;
      _estadisticas = _calcularEstadisticas(nueva);
    });
    try {
      await configuracion.cambiarParciales(nueva);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la preferencia de parciales.'),
        ),
      );
    }
  }

  Future<void> _exportar() async {
    final disponible = await asegurarDirectorioExportacion(context);
    if (!disponible || !mounted) return;
    setState(() => _exportando = true);
    final exportacion = context.read<ExportacionController>();
    final historial = context.read<HistorialController>();
    final resultado = await exportacion.exportar([widget.sesion]);
    if (!mounted) return;
    setState(() => _exportando = false);
    final guardado = await historial.actualizarExportadas(
      intentadas: {widget.sesion.id},
      correctas: resultado?.sesionesExportadas ?? const <String>{},
    );
    if (!mounted) return;
    if (resultado != null && !guardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el estado de exportación.'),
        ),
      );
    }
    mostrarResultadoExportacion(context, resultado, exportacion.error);
  }

  Future<void> _compartir() async {
    final compartir = context.read<CompartirController>();
    final exito = await compartir.compartir(widget.sesion);
    if (!mounted || exito) return;
    final mensaje = compartir.error ?? 'No se pudo compartir la ruta.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
    compartir.limpiarError();
  }

  Future<void> _eliminar() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final historial = context.read<HistorialController>();
    final exportacion = context.read<ExportacionController>();
    final configuracion = context.read<ConfiguracionController>();
    final sesion = historial.sesionPorId(widget.sesion.id) ?? widget.sesion;
    final opciones = await showDialog<_OpcionesEliminacion>(
      context: context,
      builder: (context) => _DialogoEliminarSesion(
        sesion: sesion,
        tieneDirectorio: configuracion.tieneDirectorio,
        nombreDirectorio: configuracion.directorioExportacionNombre,
      ),
    );
    if (opciones == null || !mounted) return;
    setState(() => _eliminando = true);
    final eliminada = await historial.eliminar(sesion);
    if (!mounted) return;
    if (!eliminada) {
      setState(() => _eliminando = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(historial.error ?? 'No se pudo eliminar la ruta.'),
        ),
      );
      return;
    }
    var mensaje = 'Ruta eliminada.';
    if (opciones.borrarArchivos) {
      final borrado = await exportacion.borrarArchivosDeSesion(sesion);
      if (!mounted) return;
      if (borrado == null) {
        mensaje =
            'Ruta eliminada; no se pudieron borrar los archivos exportados.';
      } else if (!borrado.correcto) {
        if (borrado.noEncontrados > 0 && borrado.errores.isEmpty) {
          mensaje =
              'Ruta eliminada; no se encontraron los archivos exportados en '
              'la carpeta actual.';
        } else if (borrado.errores.isNotEmpty) {
          mensaje =
              'Ruta eliminada; no se pudieron borrar '
              '${borrado.errores.length} archivo(s) exportado(s).';
        } else {
          mensaje =
              'Ruta eliminada; no se pudieron borrar todos los archivos '
              'exportados.';
        }
      } else {
        mensaje = 'Ruta y archivos exportados eliminados.';
      }
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final proveedorMapas = context
        .watch<ConfiguracionController>()
        .proveedorMapas;
    final compartir = context.watch<CompartirController>();
    final historial = context.watch<HistorialController>();
    final sesion = widget.sesion;
    final sesionActual = historial.sesionPorId(sesion.id) ?? sesion;
    final compartiendo = compartir.compartiendoSesion(sesion.id);
    final usaRitmo = sesion.actividad.usaRitmo;
    final color = sesion.actividad.color(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${sesion.actividad.etiqueta} · ${formatearFecha(sesion.inicio)}',
        ),
        actions: [
          IconButton(
            tooltip: 'Compartir ruta',
            onPressed: compartir.compartiendo ? null : _compartir,
            icon: compartiendo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
          ),
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
                      if (sesionActual.exportada) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: tema.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Exportada a disco',
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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
          MapaRuta(
            puntos: puntosValidosDeSesion(
              sesion.puntos,
              actividad: sesion.actividad,
            ),
            altura: 280,
            proveedor: proveedorMapas,
          ),
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
            configuracion: _parciales,
            onConfigurar: _configurarParciales,
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

class _OpcionesEliminacion {
  const _OpcionesEliminacion({required this.borrarArchivos});

  final bool borrarArchivos;
}

class _DialogoEliminarSesion extends StatefulWidget {
  const _DialogoEliminarSesion({
    required this.sesion,
    required this.tieneDirectorio,
    required this.nombreDirectorio,
  });

  final Sesion sesion;
  final bool tieneDirectorio;
  final String? nombreDirectorio;

  @override
  State<_DialogoEliminarSesion> createState() => _DialogoEliminarSesionState();
}

class _DialogoEliminarSesionState extends State<_DialogoEliminarSesion> {
  bool _borrarArchivos = false;

  @override
  Widget build(BuildContext context) {
    final sesion = widget.sesion;
    final nombre = widget.nombreDirectorio ?? 'la carpeta actual';
    return AlertDialog(
      title: const Text('Eliminar ruta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se borrará la ruta de '
              '${sesion.actividad.etiqueta.toLowerCase()} del '
              '${formatearFechaHora(sesion.inicio)}. Esta acción no se puede '
              'deshacer.',
            ),
            if (sesion.exportada) ...[
              const SizedBox(height: 12),
              if (widget.tieneDirectorio)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _borrarArchivos,
                  onChanged: (valor) =>
                      setState(() => _borrarArchivos = valor ?? false),
                  title: const Text(
                    'Borrar también los archivos exportados (GPX y JSON)',
                  ),
                  subtitle: Text('Carpeta: $nombre'),
                )
              else
                Text(
                  'Esta ruta se exportó, pero no hay carpeta de exportación '
                  'configurada; los archivos GPX y JSON no se pueden borrar '
                  'desde la app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop(_OpcionesEliminacion(borrarArchivos: _borrarArchivos)),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
