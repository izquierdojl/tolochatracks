import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';
import 'package:tolochatracks/features/configuracion/data/configuracion_repositorio.dart';
import 'package:tolochatracks/features/configuracion/ui/acerca_de_pantalla.dart';
import 'package:tolochatracks/features/configuracion/ui/configuracion_controller.dart';

import '../apoyo/falsos.dart';

void main() {
  testWidgets('Acerca de muestra la licencia MIT y la de Inter', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'TolochaTracks',
      packageName: 'com.izquierdojl.tolochatracks',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: ServicioExportacionFalso(),
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 2200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: ChangeNotifierProvider<ConfiguracionController>.value(
          value: controlador,
          child: const AcercaDePantalla(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tituloMit = find.text('Código con licencia MIT');
    await tester.scrollUntilVisible(tituloMit, 200);
    expect(tituloMit, findsOneWidget);
    expect(find.textContaining('archivo LICENSE'), findsOneWidget);

    final licenciaInter = find.textContaining('SIL Open Font License 1.1');
    await tester.scrollUntilVisible(licenciaInter, 200);
    expect(licenciaInter, findsOneWidget);
  });
}
