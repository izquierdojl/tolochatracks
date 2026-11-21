import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/shell/shell_pantalla.dart';
import 'app/theme/app_theme.dart';
import 'core/servicios/compartir.dart';
import 'core/servicios/exportacion.dart';
import 'core/servicios/notificacion_ruta.dart';
import 'core/servicios/ubicacion.dart';
import 'features/compartir/ui/compartir_controller.dart';
import 'features/configuracion/data/configuracion_repositorio.dart';
import 'features/configuracion/ui/configuracion_controller.dart';
import 'features/exportacion/ui/exportacion_controller.dart';
import 'features/grabacion/ui/grabacion_controller.dart';
import 'features/sesiones/data/sesiones_repositorio.dart';
import 'features/sesiones/ui/historial_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repositorio = SesionesRepositorio();
  final servicioExportacion = const ServicioExportacionCanal();
  final servicioCompartir = const ServicioCompartirCanal();
  final configuracion = ConfiguracionController(
    repositorio: ConfiguracionRepositorio(),
    exportacion: servicioExportacion,
  );
  final exportacion = ExportacionController(
    servicio: servicioExportacion,
    configuracion: configuracion,
  );
  final compartir = CompartirController(servicio: servicioCompartir);
  final historial = HistorialController(repositorio: repositorio);
  final notificacion = ServicioNotificacionRutaCanal();
  final grabacion = GrabacionController(
    ubicacion: const ServicioUbicacionGeolocator(),
    repositorio: repositorio,
    notificacion: notificacion,
    perfilGps: () => configuracion.perfilGps,
  );
  notificacion.acciones.listen((accion) async {
    switch (accion) {
      case AccionNotificacion.pausar:
        await grabacion.pausar();
      case AccionNotificacion.reanudar:
        await grabacion.reanudar();
      case AccionNotificacion.detener:
        final sesion = await grabacion.finalizar();
        if (sesion != null) await historial.cargar();
    }
  });
  await Future.wait([
    historial.cargar(),
    grabacion.inicializar(),
    configuracion.cargar(),
  ]);
  runApp(
    TolochaTracksApp(
      historial: historial,
      grabacion: grabacion,
      configuracion: configuracion,
      exportacion: exportacion,
      compartir: compartir,
    ),
  );
}

class TolochaTracksApp extends StatelessWidget {
  const TolochaTracksApp({
    super.key,
    required this.historial,
    required this.grabacion,
    required this.configuracion,
    required this.exportacion,
    required this.compartir,
  });

  final HistorialController historial;
  final GrabacionController grabacion;
  final ConfiguracionController configuracion;
  final ExportacionController exportacion;
  final CompartirController compartir;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: historial),
        ChangeNotifierProvider.value(value: grabacion),
        ChangeNotifierProvider.value(value: configuracion),
        ChangeNotifierProvider.value(value: exportacion),
        ChangeNotifierProvider.value(value: compartir),
      ],
      child: Consumer<ConfiguracionController>(
        builder: (context, config, _) => MaterialApp(
          title: 'TolochaTracks',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: config.tema,
          home: const ShellPantalla(),
        ),
      ),
    );
  }
}
