import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';
import 'package:tolochatracks/core/models/estadisticas_ruta.dart';
import 'package:tolochatracks/features/sesiones/ui/widgets/tabla_parciales.dart';

ParcialRuta parcial({
  int numero = 1,
  double distanciaMetros = 1000,
  Duration duracion = const Duration(minutes: 11, seconds: 23),
  double? velocidadMedia,
  double? altitudMedia = 124,
  bool completo = true,
  DestacadoParcial destacado = DestacadoParcial.ninguno,
}) => ParcialRuta(
  numero: numero,
  distanciaMetros: distanciaMetros,
  duracion: duracion,
  velocidadMedia: velocidadMedia ?? 1000 / 683,
  altitudMedia: altitudMedia,
  completo: completo,
  destacado: destacado,
);

EstadisticasRuta estadisticasCon(List<ParcialRuta> parciales) =>
    EstadisticasRuta(
      distanciaMetros: 0,
      duracionActiva: Duration.zero,
      duracionTotal: Duration.zero,
      velocidadMedia: 0,
      velocidadMaxima: 0,
      desnivelPositivo: 0,
      desnivelNegativo: 0,
      puntos: 0,
      parciales: parciales,
    );

Future<void> pumpTabla(
  WidgetTester tester,
  List<ParcialRuta> parciales, {
  ConfiguracionParciales configuracion = ConfiguracionParciales.porDefecto,
  Actividad actividad = Actividad.correr,
  double ancho = 411,
  VoidCallback? onConfigurar,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(ancho, 1400);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.oscuro,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TablaParciales(
            estadisticas: estadisticasCon(parciales),
            actividad: actividad,
            configuracion: configuracion,
            onConfigurar: onConfigurar,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('fraccionBarra', () {
    test('normaliza respecto al máximo y deja un mínimo visible', () {
      expect(fraccionBarra(0, 0), 0);
      expect(fraccionBarra(5, 0), 0);
      expect(fraccionBarra(5, 5), 1.0);
      expect(fraccionBarra(2.5, 5), 0.5);
      expect(fraccionBarra(0.01, 5), 0.06);
    });
  });

  testWidgets('muestra etiquetas compactas y unidades en la cabecera', (
    tester,
  ) async {
    final parciales = [
      parcial(numero: 1, altitudMedia: 124),
      parcial(
        numero: 2,
        distanciaMetros: 519,
        duracion: const Duration(minutes: 4, seconds: 46),
        velocidadMedia: 519 / 286,
        altitudMedia: 131,
        completo: false,
      ),
    ];
    await pumpTabla(tester, parciales, onConfigurar: () {});

    expect(find.text('Km 1'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
    expect(find.text('TIEMPO'), findsOneWidget);
    expect(find.text('RITMO'), findsOneWidget);
    expect(find.text('(min/km)'), findsOneWidget);
    expect(find.text('ALT.'), findsOneWidget);
    expect(find.text('(m)'), findsOneWidget);
    expect(find.text('11:23 /km'), findsNothing);
    expect(find.byKey(const Key('parciales-configurar')), findsOneWidget);
  });

  testWidgets('usa velocidad en actividades sin ritmo', (tester) async {
    await pumpTabla(tester, [
      parcial(velocidadMedia: 3.5),
    ], actividad: Actividad.bicicleta);

    expect(find.text('VEL.'), findsOneWidget);
    expect(find.text('(km/h)'), findsOneWidget);
    expect(find.text('12,6'), findsOneWidget);
  });

  testWidgets('en 360 dp mueve la altitud bajo el tramo', (tester) async {
    final parciales = [
      parcial(numero: 1, altitudMedia: 124),
      parcial(
        numero: 2,
        distanciaMetros: 519,
        completo: false,
        altitudMedia: 131,
      ),
    ];
    await pumpTabla(tester, parciales, ancho: 360);

    expect(find.text('ALT.'), findsNothing);
    expect(find.text('124 m'), findsOneWidget);
  });

  testWidgets('sin altitud omite la columna', (tester) async {
    final parciales = [
      parcial(numero: 1, altitudMedia: null),
      parcial(
        numero: 2,
        distanciaMetros: 519,
        completo: false,
        altitudMedia: null,
      ),
    ];
    await pumpTabla(tester, parciales);

    expect(find.text('ALT.'), findsNothing);
    expect(find.text('(m)'), findsNothing);
  });

  testWidgets('pinta una barra por parcial con la misma escala', (
    tester,
  ) async {
    final parciales = [
      parcial(numero: 1, velocidadMedia: 5),
      parcial(numero: 2, velocidadMedia: 2.5),
      parcial(numero: 3, velocidadMedia: 5 / 3),
    ];
    await pumpTabla(tester, parciales);

    expect(find.byKey(const Key('parcial-barra-1')), findsOneWidget);
    expect(find.byKey(const Key('parcial-barra-2')), findsOneWidget);
    expect(find.byKey(const Key('parcial-barra-3')), findsOneWidget);

    FractionallySizedBox barra(int numero) => tester.widget(
      find.descendant(
        of: find.byKey(Key('parcial-barra-$numero')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(barra(1).widthFactor, 1.0);
    expect(barra(2).widthFactor, closeTo(0.5, 0.001));
    expect(barra(3).widthFactor, closeTo(1 / 3, 0.001));
  });

  testWidgets('muestra trofeo, bajada y leyenda sin marcar el final', (
    tester,
  ) async {
    final parciales = [
      parcial(numero: 1, destacado: DestacadoParcial.masRapido),
      parcial(numero: 2, destacado: DestacadoParcial.masLento),
      parcial(numero: 3, completo: false),
    ];
    await pumpTabla(tester, parciales);

    expect(find.byIcon(Icons.emoji_events), findsNWidgets(2));
    expect(find.byIcon(Icons.trending_down), findsNWidgets(2));
    expect(find.text('Más rápido'), findsOneWidget);
    expect(find.text('Más lento'), findsOneWidget);

    final filaFinal = find.byKey(const Key('parcial-fila-3'));
    expect(
      find.descendant(of: filaFinal, matching: find.byIcon(Icons.emoji_events)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: filaFinal,
        matching: find.byIcon(Icons.trending_down),
      ),
      findsNothing,
    );
  });

  testWidgets('pliega a diez y muestra el resto', (tester) async {
    final parciales = [
      for (var numero = 1; numero <= 25; numero++) parcial(numero: numero),
    ];
    await pumpTabla(tester, parciales);

    expect(find.byKey(const Key('parcial-fila-10')), findsOneWidget);
    expect(find.byKey(const Key('parcial-fila-11')), findsNothing);
    expect(find.text('Ver los 15 restantes'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('parciales-ver-todos')));
    await tester.tap(find.byKey(const Key('parciales-ver-todos')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('parcial-fila-11')), findsOneWidget);
    expect(find.byKey(const Key('parcial-fila-25')), findsOneWidget);
    expect(find.text('Ver menos'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('parciales-ver-todos')));
    await tester.tap(find.byKey(const Key('parciales-ver-todos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('parcial-fila-11')), findsNothing);
  });

  testWidgets('el estado vacío cambia de mensaje según el modo', (
    tester,
  ) async {
    await pumpTabla(
      tester,
      const [],
      configuracion: ConfiguracionParciales.distancia(1000),
    );
    expect(
      find.text(
        'No hay distancia suficiente para calcular parciales (mínimo 20 m).',
      ),
      findsOneWidget,
    );
    expect(find.text('Cada 1 km'), findsOneWidget);

    await pumpTabla(
      tester,
      const [],
      configuracion: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
    );
    expect(
      find.text(
        'No hay tiempo activo suficiente para calcular parciales (mínimo 10 s).',
      ),
      findsOneWidget,
    );
    expect(find.text('Cada 5 min'), findsOneWidget);
  });
}
