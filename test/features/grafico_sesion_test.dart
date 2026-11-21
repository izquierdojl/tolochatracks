import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';
import 'package:tolochatracks/core/models/estadisticas_ruta.dart';
import 'package:tolochatracks/features/sesiones/ui/widgets/grafico_sesion.dart';

EstadisticasRuta datos({
  bool conAltitud = true,
  bool conVelocidad = true,
  bool conMinutos = true,
}) => EstadisticasRuta(
  distanciaMetros: 10000,
  duracionActiva: const Duration(minutes: 60),
  duracionTotal: const Duration(minutes: 60),
  velocidadMedia: 2.77,
  velocidadMaxima: 4,
  desnivelPositivo: 50,
  desnivelNegativo: 20,
  puntos: 100,
  altitudMinima: conAltitud ? 100 : null,
  altitudMaxima: conAltitud ? 150 : null,
  porMinuto: conMinutos
      ? const [
          DistanciaMinuto(minuto: 0, metros: 100),
          DistanciaMinuto(minuto: 1, metros: 120),
        ]
      : const [],
  serieDistancia: const [MuestraRuta(0, 0), MuestraRuta(60, 10)],
  serieVelocidad: conVelocidad
      ? const [MuestraRuta(0, 10), MuestraRuta(10, 12)]
      : const [],
  serieVelocidadTiempo: conVelocidad
      ? const [MuestraRuta(0, 10), MuestraRuta(60, 12)]
      : const [],
  serieAltitud: conAltitud
      ? const [MuestraRuta(0, 100), MuestraRuta(10, 150)]
      : const [],
  serieAltitudTiempo: conAltitud
      ? const [MuestraRuta(0, 100), MuestraRuta(60, 150)]
      : const [],
);

Future<void> pumpGrafico(
  WidgetTester tester,
  EstadisticasRuta estadisticas,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.oscuro,
      home: Scaffold(
        body: SingleChildScrollView(
          child: GraficoSesion(estadisticas: estadisticas),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> elegirMetrica(WidgetTester tester, String etiqueta) async {
  await tester.tap(find.byKey(const Key('grafico-metrica')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(etiqueta).last);
  await tester.pumpAndSettle();
}

Future<void> elegirEje(WidgetTester tester, String etiqueta) async {
  await tester.tap(find.byKey(const Key('grafico-eje-x')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(etiqueta).last);
  await tester.pumpAndSettle();
}

LineChartData linea(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart)).data;

void main() {
  testWidgets('cambia la métrica y el eje', (tester) async {
    await pumpGrafico(tester, datos());

    expect(find.byKey(const Key('grafico-metrica')), findsOneWidget);
    expect(find.byKey(const Key('grafico-eje-x')), findsOneWidget);
    expect(
      find.text('Distancia acumulada (km) por tiempo (min)'),
      findsOneWidget,
    );

    await elegirMetrica(tester, 'Velocidad');
    expect(find.text('Velocidad (km/h) por tiempo (min)'), findsOneWidget);

    await elegirEje(tester, 'Distancia');
    expect(find.text('Velocidad (km/h) por distancia (km)'), findsOneWidget);

    await elegirMetrica(tester, 'Distancia');
    final eje = tester.widget<DropdownButton<EjeX>>(
      find.byKey(const Key('grafico-eje-x')),
    );
    expect(eje.value, EjeX.tiempo);
    expect(eje.onChanged, isNull);
    expect(
      find.text('La distancia se dibuja frente al tiempo.'),
      findsOneWidget,
    );

    await elegirMetrica(tester, 'Por minuto');
    expect(find.byKey(const Key('grafico-eje-x')), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('usa la serie del eje y empieza en cero', (tester) async {
    await pumpGrafico(tester, datos());

    expect(linea(tester).minY, 0);
    expect(linea(tester).maxX, closeTo(60, 0.01));

    await elegirMetrica(tester, 'Velocidad');
    expect(linea(tester).maxX, closeTo(60, 0.01));
    expect(linea(tester).minY, 0);

    await elegirEje(tester, 'Distancia');
    expect(linea(tester).maxX, closeTo(10, 0.01));

    await elegirMetrica(tester, 'Altitud');
    expect(linea(tester).minY, lessThan(100));
    expect(linea(tester).maxY, greaterThan(150));

    await elegirEje(tester, 'Tiempo');
    expect(linea(tester).maxX, closeTo(60, 0.01));
  });

  testWidgets('explica cuándo no hay datos', (tester) async {
    await pumpGrafico(tester, datos(conAltitud: false));
    await elegirMetrica(tester, 'Altitud');
    expect(find.text('Esta ruta no tiene datos de altitud.'), findsOneWidget);

    await pumpGrafico(tester, datos(conVelocidad: false));
    await elegirMetrica(tester, 'Velocidad');
    expect(
      find.text('No hay datos de velocidad para este eje.'),
      findsOneWidget,
    );

    await pumpGrafico(tester, datos(conMinutos: false));
    await elegirMetrica(tester, 'Por minuto');
    expect(
      find.text('No hay minutos con movimiento para dibujar.'),
      findsOneWidget,
    );
  });
}
