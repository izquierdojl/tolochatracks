import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/estadisticas_ruta.dart';

enum MetricaGrafico {
  distancia('Distancia'),
  velocidad('Velocidad'),
  altitud('Altitud'),
  minutos('Por minuto');

  const MetricaGrafico(this.etiqueta);

  final String etiqueta;
}

class GraficoSesion extends StatefulWidget {
  const GraficoSesion({super.key, required this.estadisticas});

  final EstadisticasRuta estadisticas;

  @override
  State<GraficoSesion> createState() => _GraficoSesionState();
}

class _GraficoSesionState extends State<GraficoSesion> {
  MetricaGrafico _metrica = MetricaGrafico.distancia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gráficos',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metrica in MetricaGrafico.values)
                  ChoiceChip(
                    label: Text(metrica.etiqueta),
                    selected: _metrica == metrica,
                    onSelected: (_) => setState(() => _metrica = metrica),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _descripcion,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _contenido()),
          ],
        ),
      ),
    );
  }

  String get _descripcion => switch (_metrica) {
    MetricaGrafico.distancia => 'Distancia acumulada (km) por tiempo (min)',
    MetricaGrafico.velocidad => 'Velocidad (km/h) por distancia (km)',
    MetricaGrafico.altitud => 'Altitud (m) por distancia (km)',
    MetricaGrafico.minutos => 'Metros recorridos en cada minuto',
  };

  Widget _contenido() {
    final estadisticas = widget.estadisticas;
    final series = switch (_metrica) {
      MetricaGrafico.distancia => estadisticas.serieDistancia,
      MetricaGrafico.velocidad => estadisticas.serieVelocidad,
      MetricaGrafico.altitud => estadisticas.serieAltitud,
      MetricaGrafico.minutos => const <MuestraRuta>[],
    };
    if (_metrica == MetricaGrafico.minutos) {
      return estadisticas.porMinuto.isEmpty
          ? const _SinDatos(
              mensaje: 'No hay minutos con movimiento para dibujar.',
            )
          : _GraficoMinutos(datos: estadisticas.porMinuto);
    }
    if (series.length < 2) {
      return _SinDatos(
        mensaje: _metrica == MetricaGrafico.altitud
            ? 'Esta ruta no tiene datos de altitud.'
            : 'No hay suficientes puntos para dibujar la gráfica.',
      );
    }
    return _GraficoLinea(metrica: _metrica, muestras: series);
  }
}

class _GraficoLinea extends StatelessWidget {
  const _GraficoLinea({required this.metrica, required this.muestras});

  final MetricaGrafico metrica;
  final List<MuestraRuta> muestras;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = context.coloresRuta;
    final color = switch (metrica) {
      MetricaGrafico.distancia => colores.ruta,
      MetricaGrafico.velocidad => colores.velocidad,
      MetricaGrafico.altitud => colores.altitud,
      MetricaGrafico.minutos => colores.ruta,
    };
    final maxX = muestras.map((m) => m.x).reduce(max);
    final minY = muestras.map((m) => m.y).reduce(min);
    final maxY = muestras.map((m) => m.y).reduce(max);
    final rangoY = maxY - minY;
    final margenY = rangoY > 0 ? rangoY * 0.12 : max(0.1, maxY.abs() * 0.05);
    final intervaloX = _intervalo(maxX, 4);
    final intervaloY = _intervalo(rangoY, 4);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX <= 0 ? 1 : maxX,
        minY: minY - margenY,
        maxY: maxY + margenY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervaloY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: intervaloY,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _etiquetaY(valor),
                  style: tema.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: intervaloX,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  _etiquetaX(valor),
                  style: tema.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final muestra in muestras) FlSpot(muestra.x, muestra.y),
            ],
            isCurved: true,
            curveSmoothness: 0.15,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
    );
  }

  String _etiquetaY(double valor) => switch (metrica) {
    MetricaGrafico.distancia => _numero(valor, 1),
    MetricaGrafico.velocidad => '${valor.round()}',
    MetricaGrafico.altitud => '${valor.round()}',
    MetricaGrafico.minutos => '${valor.round()}',
  };

  String _etiquetaX(double valor) => switch (metrica) {
    MetricaGrafico.distancia =>
      valor < 10 ? '${_numero(valor, 1)}′' : '${valor.round()}′',
    MetricaGrafico.velocidad => _numero(valor, 1),
    MetricaGrafico.altitud => _numero(valor, 1),
    MetricaGrafico.minutos => '${valor.round()}',
  };
}

class _GraficoMinutos extends StatelessWidget {
  const _GraficoMinutos({required this.datos});

  final List<DistanciaMinuto> datos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = context.coloresRuta.ruta;
    final maxY = datos.map((d) => d.metros).reduce(max);
    final intervaloX = _intervalo(datos.length.toDouble(), 5);
    final intervaloY = _intervalo(maxY, 4);
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.18,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervaloY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: intervaloY,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  '${valor.round()}',
                  style: tema.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: intervaloX,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                space: 6,
                child: Text(
                  '${valor.round()}′',
                  style: tema.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (final dato in datos)
            BarChartGroupData(
              x: dato.minuto,
              barRods: [
                BarChartRodData(
                  toY: dato.metros,
                  color: color,
                  width: 7,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 220),
    );
  }
}

class _SinDatos extends StatelessWidget {
  const _SinDatos({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: tema.textTheme.bodySmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _numero(double valor, int decimales) =>
    valor.toStringAsFixed(decimales).replaceAll('.', ',');

double _intervalo(double rango, int divisiones) {
  if (!rango.isFinite || rango <= 0) return 1;
  final bruto = rango / divisiones;
  final magnitud = pow(10, (log(bruto) / ln10).floor()).toDouble();
  final normalizado = bruto / magnitud;
  final paso = normalizado <= 1
      ? 1.0
      : normalizado <= 2
      ? 2.0
      : normalizado <= 5
      ? 5.0
      : 10.0;
  final resultado = paso * magnitud;
  return resultado <= 0 ? 1 : resultado;
}
