import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/actividad.dart';
import '../../../../core/models/configuracion_parciales.dart';
import '../../../../core/models/estadisticas_ruta.dart';
import '../../../../core/utilidades/formato.dart';

double fraccionBarra(double velocidad, double maximo) {
  if (!velocidad.isFinite ||
      !maximo.isFinite ||
      velocidad <= 0 ||
      maximo <= 0) {
    return 0;
  }
  return (velocidad / maximo).clamp(0.06, 1.0);
}

class TablaParciales extends StatefulWidget {
  const TablaParciales({
    super.key,
    required this.estadisticas,
    required this.actividad,
    this.configuracion = ConfiguracionParciales.porDefecto,
    this.onConfigurar,
  });

  final EstadisticasRuta estadisticas;
  final Actividad actividad;
  final ConfiguracionParciales configuracion;
  final VoidCallback? onConfigurar;

  @override
  State<TablaParciales> createState() => _TablaParcialesState();
}

class _TablaParcialesState extends State<TablaParciales> {
  static const _maximoVisible = 10;

  bool _mostrarTodos = false;

  @override
  void didUpdateWidget(covariant TablaParciales oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuracion != widget.configuracion) {
      _mostrarTodos = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final parciales = widget.estadisticas.parciales;
    final configuracion = widget.configuracion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Parciales',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onConfigurar != null)
                  IconButton(
                    key: const Key('parciales-configurar'),
                    tooltip: 'Configurar parciales',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onConfigurar,
                    icon: const Icon(Icons.tune),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              parciales.isEmpty
                  ? configuracion.descripcion
                  : '${configuracion.descripcion} · ${parciales.length} '
                        '${parciales.length == 1 ? 'tramo' : 'tramos'}',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (parciales.isEmpty)
              _SinParciales(configuracion: configuracion)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final muestraAltitud =
                      constraints.maxWidth >= 340 &&
                      parciales.any((p) => p.altitudMedia != null);
                  final hueco = constraints.maxWidth < 280 ? 4.0 : 8.0;
                  final completos = parciales.where((p) => p.completo);
                  final base = completos.isEmpty ? parciales : completos;
                  final maximo = base.fold<double>(
                    0,
                    (valor, parcial) => parcial.velocidadMedia > valor
                        ? parcial.velocidadMedia
                        : valor,
                  );
                  final visibles = _mostrarTodos
                      ? parciales
                      : parciales.take(_maximoVisible).toList();
                  final hayDestacados = parciales.any(
                    (p) => p.destacado != DestacadoParcial.ninguno,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Cabecera(
                        usaRitmo: widget.actividad.usaRitmo,
                        muestraAltitud: muestraAltitud,
                        hueco: hueco,
                      ),
                      const SizedBox(height: 2),
                      for (var i = 0; i < visibles.length; i++) ...[
                        _FilaParcial(
                          key: Key('parcial-fila-${visibles[i].numero}'),
                          parcial: visibles[i],
                          configuracion: configuracion,
                          usaRitmo: widget.actividad.usaRitmo,
                          muestraAltitud: muestraAltitud,
                          maximo: maximo,
                          hueco: hueco,
                        ),
                        if (i < visibles.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: tema.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                      ],
                      if (hayDestacados) ...[
                        const SizedBox(height: 6),
                        const _LeyendaDestacados(),
                      ],
                      if (parciales.length > _maximoVisible) ...[
                        const SizedBox(height: 2),
                        TextButton.icon(
                          key: const Key('parciales-ver-todos'),
                          onPressed: () =>
                              setState(() => _mostrarTodos = !_mostrarTodos),
                          icon: Icon(
                            _mostrarTodos
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(
                            _mostrarTodos
                                ? 'Ver menos'
                                : 'Ver los '
                                      '${parciales.length - _maximoVisible} '
                                      'restantes',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.usaRitmo,
    required this.muestraAltitud,
    required this.hueco,
  });

  final bool usaRitmo;
  final bool muestraAltitud;
  final double hueco;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.labelSmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    final estiloUnidad = estilo?.copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
    );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('TRAMO', style: estilo)),
        SizedBox(width: hueco),
        const Expanded(flex: 2, child: SizedBox.shrink()),
        SizedBox(width: hueco),
        SizedBox(
          width: 46,
          child: Text('TIEMPO', textAlign: TextAlign.end, style: estilo),
        ),
        SizedBox(width: hueco),
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(usaRitmo ? 'RITMO' : 'VEL.', style: estilo),
              Text(usaRitmo ? '(min/km)' : '(km/h)', style: estiloUnidad),
            ],
          ),
        ),
        if (muestraAltitud) ...[
          SizedBox(width: hueco),
          SizedBox(
            width: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ALT.', style: estilo),
                Text('(m)', style: estiloUnidad),
              ],
            ),
          ),
        ],
        SizedBox(width: hueco),
        const SizedBox(width: 22),
      ],
    );
  }
}

class _FilaParcial extends StatelessWidget {
  const _FilaParcial({
    super.key,
    required this.parcial,
    required this.configuracion,
    required this.usaRitmo,
    required this.muestraAltitud,
    required this.maximo,
    required this.hueco,
  });

  final ParcialRuta parcial;
  final ConfiguracionParciales configuracion;
  final bool usaRitmo;
  final bool muestraAltitud;
  final double maximo;
  final double hueco;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estiloValor = tema.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final estiloTramo = tema.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final estiloSubtitulo = tema.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: tema.colorScheme.onSurfaceVariant,
    );
    final subtitulos = <String>[
      if (!parcial.completo)
        configuracion.esDistancia
            ? formatearDistanciaCorta(parcial.distanciaMetros)
            : formatearDuracion(parcial.duracion),
      if (!muestraAltitud && parcial.altitudMedia != null)
        formatearMetros(parcial.altitudMedia!),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiquetaTramoParcial(
                    configuracion,
                    parcial.numero,
                    completo: parcial.completo,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estiloTramo,
                ),
                if (subtitulos.isNotEmpty)
                  Text(
                    subtitulos.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estiloSubtitulo,
                  ),
              ],
            ),
          ),
          SizedBox(width: hueco),
          Expanded(
            flex: 2,
            child: _BarraParcial(
              key: Key('parcial-barra-${parcial.numero}'),
              velocidad: parcial.velocidadMedia,
              maximo: maximo,
            ),
          ),
          SizedBox(width: hueco),
          SizedBox(
            width: 46,
            child: Text(
              formatearDuracion(parcial.duracion),
              textAlign: TextAlign.end,
              maxLines: 1,
              style: estiloValor,
            ),
          ),
          SizedBox(width: hueco),
          SizedBox(
            width: 52,
            child: Text(
              usaRitmo
                  ? formatearRitmoCorto(parcial.velocidadMedia)
                  : formatearVelocidadCorto(parcial.velocidadMedia),
              textAlign: TextAlign.end,
              maxLines: 1,
              style: estiloValor,
            ),
          ),
          if (muestraAltitud) ...[
            SizedBox(width: hueco),
            SizedBox(
              width: 34,
              child: Text(
                formatearMetrosCorto(parcial.altitudMedia),
                textAlign: TextAlign.end,
                maxLines: 1,
                style: estiloValor,
              ),
            ),
          ],
          SizedBox(width: hueco),
          SizedBox(
            width: 22,
            child: _DestacadoIcono(destacado: parcial.destacado),
          ),
        ],
      ),
    );
  }
}

class _BarraParcial extends StatelessWidget {
  const _BarraParcial({
    super.key,
    required this.velocidad,
    required this.maximo,
  });

  final double velocidad;
  final double maximo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fraccion = fraccionBarra(velocidad, maximo);
    return ExcludeSemantics(
      child: Container(
        height: 6,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          widthFactor: fraccion,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.coloresRuta.velocidad,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestacadoIcono extends StatelessWidget {
  const _DestacadoIcono({required this.destacado});

  final DestacadoParcial destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return switch (destacado) {
      DestacadoParcial.ninguno => const SizedBox.shrink(),
      DestacadoParcial.masRapido => Icon(
        Icons.emoji_events,
        size: 16,
        color: tema.colorScheme.tertiary,
        semanticLabel: 'Parcial más rápido',
      ),
      DestacadoParcial.masLento => Icon(
        Icons.trending_down,
        size: 16,
        color: tema.colorScheme.onSurfaceVariant,
        semanticLabel: 'Parcial más lento',
      ),
    };
  }
}

class _LeyendaDestacados extends StatelessWidget {
  const _LeyendaDestacados();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: tema.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        Icon(Icons.emoji_events, size: 14, color: tema.colorScheme.tertiary),
        const SizedBox(width: 4),
        Text('Más rápido', style: estilo),
        const SizedBox(width: 12),
        Icon(
          Icons.trending_down,
          size: 14,
          color: tema.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text('Más lento', style: estilo),
      ],
    );
  }
}

class _SinParciales extends StatelessWidget {
  const _SinParciales({required this.configuracion});

  final ConfiguracionParciales configuracion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final mensaje = configuracion.esDistancia
        ? 'No hay distancia suficiente para calcular parciales (mínimo 20 m).'
        : 'No hay tiempo activo suficiente para calcular parciales (mínimo 10 s).';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        mensaje,
        style: tema.textTheme.bodySmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
