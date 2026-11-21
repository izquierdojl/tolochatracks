import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/shell/seccion_app.dart';
import '../../../app/shell/shell_controller.dart';
import '../../../app/theme/actividad_visual.dart';
import '../../../core/calculos/calculos_ruta.dart';
import '../../../core/models/proveedor_mapas.dart';
import '../../../core/models/sesion.dart';
import '../../../core/utilidades/formato.dart';
import '../../sesiones/ui/historial_controller.dart';
import '../../configuracion/ui/configuracion_controller.dart';
import '../../sesiones/ui/widgets/mapa_ruta.dart';
import 'grabacion_controller.dart';
import 'widgets/estadisticas_grabacion.dart';
import 'widgets/selector_actividad.dart';

class GrabacionPantalla extends StatelessWidget {
  const GrabacionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<GrabacionController>();
    final proveedorMapas = context
        .watch<ConfiguracionController>()
        .proveedorMapas;
    if (controlador.estado == EstadoGrabacion.guardando) {
      return const _Guardando();
    }
    final enCurso =
        controlador.tienePuntos ||
        controlador.estado == EstadoGrabacion.grabando ||
        controlador.estado == EstadoGrabacion.pausado ||
        controlador.estado == EstadoGrabacion.error;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (controlador.estado == EstadoGrabacion.inactivo &&
            controlador.borrador != null) ...[
          _BannerBorrador(borrador: controlador.borrador!),
          const SizedBox(height: 16),
        ],
        if (controlador.estado == EstadoGrabacion.iniciando)
          const _PreparandoGps()
        else if (enCurso)
          _EnCurso(controlador: controlador, proveedorMapas: proveedorMapas)
        else
          _Inicio(controlador: controlador),
      ],
    );
  }
}

class _Inicio extends StatelessWidget {
  const _Inicio({required this.controlador});

  final GrabacionController controlador;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nueva ruta',
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige la actividad y pulsa empezar. Sin cuentas ni configuraciones.',
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SelectorActividad(
          seleccionada: controlador.actividad,
          onSeleccionar: controlador.cambiarActividad,
          habilitado: !controlador.bloqueadoPorBorrador,
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 176,
            height: 176,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: controlador.bloqueadoPorBorrador
                  ? null
                  : controlador.iniciar,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 60),
                  const SizedBox(height: 2),
                  Text(
                    'Empezar',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tema.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controlador.mensajeError != null) ...[
          const SizedBox(height: 20),
          _AvisoError(
            controlador: controlador,
            permiteReintentar: !controlador.servicioDesactivado,
          ),
        ],
        const SizedBox(height: 24),
        _Consejo(
          icono: Icons.gps_fixed,
          titulo: 'Espera a que el GPS te encuentre',
          texto:
              'Los primeros segundos son normales. La ubicación solo se usa '
              'mientras grabas y la ruta se guarda en tu móvil.',
        ),
        if (controlador.ultimaSesion != null) ...[
          const SizedBox(height: 16),
          _UltimaSesion(sesion: controlador.ultimaSesion!),
        ],
      ],
    );
  }
}

class _EnCurso extends StatelessWidget {
  const _EnCurso({required this.controlador, required this.proveedorMapas});

  final GrabacionController controlador;
  final ProveedorMapas proveedorMapas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final actividad = controlador.actividad;
    final enPausa = controlador.estado == EstadoGrabacion.pausado;
    final conError = controlador.estado == EstadoGrabacion.error;
    final estadoTexto = enPausa
        ? 'En pausa'
        : conError
        ? 'Grabación detenida'
        : controlador.sinSenal
        ? 'Buscando señal GPS'
        : 'Grabando';
    final precision = controlador.precisionActual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: actividad.color(context).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(actividad.icono, color: actividad.color(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actividad.etiqueta,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        enPausa
                            ? Icons.pause_circle_outline
                            : conError
                            ? Icons.error_outline
                            : Icons.circle,
                        size: 12,
                        color: enPausa || conError
                            ? tema.colorScheme.error
                            : tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        precision == null
                            ? estadoTexto
                            : '$estadoTexto · ±${precision.toStringAsFixed(0)} m',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (controlador.inicio != null)
              Text(
                'Inicio ${formatearHora(controlador.inicio!)}',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (!enPausa && !conError && controlador.sinSenal) ...[
          const SizedBox(height: 12),
          _Banda(
            icono: Icons.satellite_alt,
            texto:
                'Aún no hay señal suficiente. Puedes seguir moviéndote; los '
                'puntos se guardarán cuando el GPS mejore.',
          ),
        ],
        if (!enPausa &&
            !conError &&
            !controlador.sinSenal &&
            controlador.senalDebil) ...[
          const SizedBox(height: 12),
          _Banda(
            icono: Icons.signal_cellular_alt,
            texto:
                'Señal débil: la distancia y la velocidad pueden ser '
                'imprecisas.',
          ),
        ],
        if (enPausa) ...[
          const SizedBox(height: 12),
          _Banda(
            icono: Icons.pause,
            texto:
                'La grabación está en pausa. El tiempo y la distancia no '
                'avanzan.',
          ),
        ],
        if (controlador.avisoNotificaciones) ...[
          const SizedBox(height: 12),
          _Banda(
            icono: Icons.notifications_off_outlined,
            texto:
                'Notificaciones desactivadas: la grabación sigue, pero el '
                'aviso del servicio puede no verse.',
          ),
        ],
        if (conError && controlador.mensajeError != null) ...[
          const SizedBox(height: 12),
          _AvisoError(controlador: controlador, permiteReintentar: true),
        ],
        if (controlador.puntos.isNotEmpty) ...[
          const SizedBox(height: 16),
          MapaRuta(puntos: controlador.puntos, altura: 220, seguir: true),
        ],
        const SizedBox(height: 16),
        EstadisticasGrabacion(controlador: controlador),
        const SizedBox(height: 16),
        if (!conError)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enPausa
                      ? controlador.reanudar
                      : controlador.pausar,
                  icon: Icon(enPausa ? Icons.play_arrow : Icons.pause),
                  label: Text(enPausa ? 'Reanudar' : 'Pausar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmarFinalizar(context, controlador),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Finalizar'),
                ),
              ),
            ],
          )
        else if (controlador.errorGuardado)
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _confirmarFinalizar(context, controlador),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar de nuevo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarDescartar(context, controlador),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Descartar'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: controlador.reanudar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarFinalizar(context, controlador),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Finalizar'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmarDescartar(context, controlador),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Descartar grabación'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${controlador.puntos.length} puntos · precisión y distancia '
          'filtradas automáticamente',
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PreparandoGps extends StatelessWidget {
  const _PreparandoGps();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Obteniendo GPS…', style: tema.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Solicitando permiso de ubicación y esperando la primera posición.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Guardando extends StatelessWidget {
  const _Guardando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Guardando la ruta…'),
        ],
      ),
    );
  }
}

class _BannerBorrador extends StatelessWidget {
  const _BannerBorrador({required this.borrador});

  final Sesion borrador;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restore, color: tema.colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sesión sin terminar',
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: tema.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${borrador.actividad.etiqueta} · '
            '${formatearFechaHora(borrador.inicio)} · '
            '${formatearDuracion(borrador.duracionActiva)} · '
            '${borrador.puntos.length} puntos',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () =>
                    context.read<GrabacionController>().recuperarBorrador(),
                child: const Text('Recuperar'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _confirmarDescartarBorrador(context),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  const _AvisoError({
    required this.controlador,
    required this.permiteReintentar,
  });

  final GrabacionController controlador;
  final bool permiteReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: tema.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controlador.mensajeError ?? 'Ha ocurrido un error.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onErrorContainer,
                  ),
                ),
                if (controlador.servicioDesactivado ||
                    controlador.denegadoSiempre) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: controlador.servicioDesactivado
                        ? controlador.abrirAjustesUbicacion
                        : controlador.abrirAjustesPermiso,
                    child: Text(
                      controlador.servicioDesactivado
                          ? 'Activar ubicación'
                          : 'Abrir ajustes',
                    ),
                  ),
                ] else if (permiteReintentar &&
                    controlador.estado == EstadoGrabacion.inactivo) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: controlador.iniciar,
                    child: const Text('Reintentar'),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controlador.limpiarAviso,
                    child: const Text('Entendido'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banda extends StatelessWidget {
  const _Banda({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Consejo extends StatelessWidget {
  const _Consejo({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: tema.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    texto,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltimaSesion extends StatelessWidget {
  const _UltimaSesion({required this.sesion});

  final Sesion sesion;

  @override
  Widget build(BuildContext context) {
    final estadisticas = calcularEstadisticas(
      sesion.puntos,
      duracionActiva: sesion.duracionActiva,
      inicio: sesion.inicio,
      fin: sesion.fin,
    );
    return Card(
      child: ListTile(
        leading: Icon(
          sesion.actividad.icono,
          color: sesion.actividad.color(context),
        ),
        title: Text('Última ruta · ${sesion.actividad.etiqueta}'),
        subtitle: Text(
          '${formatearDistancia(estadisticas.distanciaMetros)} · '
          '${formatearDuracion(sesion.duracionActiva)}',
        ),
        trailing: TextButton(
          onPressed: () =>
              context.read<ShellController>().irA(SeccionApp.historial),
          child: const Text('Ver'),
        ),
        onTap: () => context.read<ShellController>().irA(SeccionApp.historial),
      ),
    );
  }
}

Future<void> _confirmarFinalizar(
  BuildContext context,
  GrabacionController controlador,
) async {
  final historial = context.read<HistorialController>();
  final shell = context.read<ShellController>();
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final sinPuntos = controlador.puntos.isEmpty;
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(sinPuntos ? 'Descartar grabación' : 'Finalizar ruta'),
      content: Text(
        sinPuntos
            ? 'No se ha registrado ninguna posición. La grabación se '
                  'descartará sin guardar nada.'
            : 'Se guardarán ${formatearDistancia(controlador.distanciaMetros)} '
                  'en ${formatearDuracion(controlador.duracionActiva)}. '
                  'Después podrás verla en el historial.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Seguir'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(sinPuntos ? 'Descartar' : 'Guardar ruta'),
        ),
      ],
    ),
  );
  if (confirmar != true) return;
  final sesion = await controlador.finalizar();
  if (sesion == null) {
    final mensaje = controlador.mensajeError;
    if (mensaje != null) {
      messenger.showSnackBar(SnackBar(content: Text(mensaje)));
    }
    return;
  }
  await historial.cargar();
  if (!navigator.mounted) return;
  await _mostrarResumen(navigator.context, sesion, shell);
}

Future<void> _mostrarResumen(
  BuildContext context,
  Sesion sesion,
  ShellController shell,
) async {
  final ver = await showDialog<bool>(
    context: context,
    builder: (context) {
      final estadisticas = calcularEstadisticas(
        sesion.puntos,
        duracionActiva: sesion.duracionActiva,
        inicio: sesion.inicio,
        fin: sesion.fin,
      );
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: 8),
            Text('Ruta guardada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${sesion.actividad.etiqueta} · '
              '${formatearFechaHora(sesion.inicio)}',
            ),
            const SizedBox(height: 12),
            Text(
              '${formatearDistancia(estadisticas.distanciaMetros)} · '
              '${formatearDuracion(sesion.duracionActiva)}',
            ),
            Text(
              sesion.actividad.usaRitmo
                  ? 'Ritmo medio ${formatearRitmo(estadisticas.velocidadMedia)}'
                  : 'Velocidad media '
                        '${formatearVelocidad(estadisticas.velocidadMedia)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ver historial'),
          ),
        ],
      );
    },
  );
  if (ver == true) {
    shell.irA(SeccionApp.historial);
  }
}

Future<void> _confirmarDescartar(
  BuildContext context,
  GrabacionController controlador,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar grabación'),
      content: const Text(
        'Se perderán los puntos y el tiempo de esta grabación. Esta acción no '
        'se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    await controlador.descartar();
  }
}

Future<void> _confirmarDescartarBorrador(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar sesión pendiente'),
      content: const Text(
        'La sesión sin terminar se borrará del dispositivo. No se puede '
        'recuperar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  if (confirmar == true && context.mounted) {
    await context.read<GrabacionController>().descartarBorrador();
  }
}
