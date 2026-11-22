import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';
import 'package:tolochatracks/features/configuracion/data/configuracion_repositorio.dart';
import 'package:tolochatracks/features/configuracion/ui/configuracion_controller.dart';
import 'package:tolochatracks/features/configuracion/ui/configuracion_pantalla.dart';

import '../apoyo/falsos.dart';

void main() {
  testWidgets('cambia los parciales desde Ajustes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: ServicioExportacionFalso(),
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.oscuro,
        home: ChangeNotifierProvider<ConfiguracionController>.value(
          value: controlador,
          child: const Scaffold(body: ConfiguracionPantalla()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.text('Parciales por defecto');
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Por tiempo'), findsOneWidget);
    await tester.tap(find.text('Por tiempo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selector-parciales-listo')));
    await tester.pumpAndSettle();

    expect(
      controlador.parciales,
      ConfiguracionParciales.tiempo(const Duration(minutes: 15)),
    );
    expect(find.text('Cada 15 min'), findsOneWidget);
  });
}
