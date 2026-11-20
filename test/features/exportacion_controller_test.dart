import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/features/configuracion/data/configuracion_repositorio.dart';
import 'package:tolochatracks/features/configuracion/ui/configuracion_controller.dart';
import 'package:tolochatracks/features/exportacion/ui/exportacion_controller.dart';

import '../apoyo/falsos.dart';

Sesion sesionDePrueba({String id = 'exportar'}) => Sesion(
  id: id,
  actividad: Actividad.correr,
  inicio: DateTime(2026, 11, 20, 18),
  fin: DateTime(2026, 11, 20, 18, 30),
  duracionActiva: const Duration(minutes: 29),
  puntos: const [],
);

void main() {
  late ServicioExportacionFalso servicio;
  late ConfiguracionController configuracion;
  late ExportacionController exportacion;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    servicio = ServicioExportacionFalso();
    configuracion = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    await configuracion.cargar();
    exportacion = ExportacionController(
      servicio: servicio,
      configuracion: configuracion,
    );
  });

  tearDown(() {
    configuracion.dispose();
    exportacion.dispose();
  });

  test('sin carpeta no exporta y explica qué hacer', () async {
    final resultado = await exportacion.exportar([sesionDePrueba()]);
    expect(resultado, isNull);
    expect(exportacion.error, contains('carpeta'));
    expect(servicio.archivos, isEmpty);
  });

  test('con carpeta exporta GPX y JSON por sesión', () async {
    final directorio = await configuracion.elegirDirectorioExportacion();
    expect(directorio, isNotNull);
    expect(configuracion.tieneDirectorio, isTrue);
    final resultado = await exportacion.exportar([sesionDePrueba()]);
    expect(resultado, isNotNull, reason: exportacion.error);
    expect(resultado!.exportados, 2);
    expect(resultado.correcto, isTrue);
    expect(servicio.archivos, hasLength(2));
    expect(servicio.archivos[0].nombre, endsWith('.gpx'));
    expect(servicio.archivos[1].nombre, endsWith('.json'));
    expect(exportacion.exportando, isFalse);
  });

  test('exporta varias sesiones en una sola operación', () async {
    await configuracion.elegirDirectorioExportacion();
    final resultado = await exportacion.exportar([
      sesionDePrueba(),
      sesionDePrueba(id: 'otra'),
    ]);
    expect(resultado!.exportados, 4);
  });

  test('un fallo del servicio deja un error y no marca éxito', () async {
    await configuracion.elegirDirectorioExportacion();
    servicio.fallar = true;
    final resultado = await exportacion.exportar([sesionDePrueba()]);
    expect(resultado, isNull);
    expect(exportacion.error, isNotNull);
    expect(exportacion.exportando, isFalse);
  });

  test('sin sesiones avisa y no llama al servicio', () async {
    await configuracion.elegirDirectorioExportacion();
    final resultado = await exportacion.exportar([]);
    expect(resultado, isNull);
    expect(exportacion.error, contains('No hay rutas'));
    expect(servicio.archivos, isEmpty);
  });
}
