import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';
import 'package:tolochatracks/core/widgets/selector_parciales.dart';

void main() {
  testWidgets('devuelve el paso elegido', (tester) async {
    ConfiguracionParciales? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.oscuro,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  resultado = await mostrarSelectorParciales(
                    context,
                    actual: ConfiguracionParciales.porDefecto,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Por distancia'), findsOneWidget);
    await tester.tap(find.text('Por tiempo'));
    await tester.pumpAndSettle();
    expect(find.text('5 min'), findsOneWidget);

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-parciales-listo')));
    await tester.pumpAndSettle();

    expect(
      resultado,
      ConfiguracionParciales.tiempo(const Duration(minutes: 15)),
    );
  });

  testWidgets('cancelar no devuelve nada', (tester) async {
    ConfiguracionParciales? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.oscuro,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  resultado = await mostrarSelectorParciales(
                    context,
                    actual: ConfiguracionParciales.porDefecto,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
  });

  testWidgets('al cambiar de modo vuelve al valor por defecto', (tester) async {
    ConfiguracionParciales? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.oscuro,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  resultado = await mostrarSelectorParciales(
                    context,
                    actual: ConfiguracionParciales.distancia(500),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Por tiempo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-parciales-listo')));
    await tester.pumpAndSettle();

    expect(
      resultado,
      ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
    );
  });
}
