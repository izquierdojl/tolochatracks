import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/shell/shell_pantalla.dart';
import 'app/theme/app_theme.dart';
import 'core/servicios/ubicacion.dart';
import 'features/grabacion/ui/grabacion_controller.dart';
import 'features/sesiones/data/sesiones_repositorio.dart';
import 'features/sesiones/ui/historial_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repositorio = SesionesRepositorio();
  final historial = HistorialController(repositorio: repositorio);
  final grabacion = GrabacionController(
    ubicacion: const ServicioUbicacionGeolocator(),
    repositorio: repositorio,
  );
  await Future.wait([historial.cargar(), grabacion.inicializar()]);
  runApp(TolochaTracksApp(historial: historial, grabacion: grabacion));
}

class TolochaTracksApp extends StatelessWidget {
  const TolochaTracksApp({
    super.key,
    required this.historial,
    required this.grabacion,
  });

  final HistorialController historial;
  final GrabacionController grabacion;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: historial),
        ChangeNotifierProvider.value(value: grabacion),
      ],
      child: MaterialApp(
        title: 'TolochaTracks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        darkTheme: AppTheme.oscuro,
        themeMode: ThemeMode.system,
        home: const ShellPantalla(),
      ),
    );
  }
}
