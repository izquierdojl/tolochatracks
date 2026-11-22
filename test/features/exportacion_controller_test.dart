import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolochatracks/core/exportacion/exportacion_sesion.dart';
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

  test('marca la sesión cuando se escriben los dos archivos', () async {
    await configuracion.elegirDirectorioExportacion();
    final sesion = sesionDePrueba();

    final resultado = await exportacion.exportar([sesion]);

    expect(resultado, isNotNull);
    expect(resultado!.sesionesExportadas, {'exportar'});
    expect(resultado.archivosCorrectos, hasLength(2));
    expect(resultado.archivosCorrectos, contains(nombreGpx(sesion)));
    expect(resultado.archivosCorrectos, contains(nombreJson(sesion)));
  });

  test('marca solo las sesiones con GPX y JSON completos', () async {
    await configuracion.elegirDirectorioExportacion();
    final una = sesionDePrueba(id: 'una');
    final otra = sesionDePrueba(id: 'otra');
    servicio.fallarNombres.add(nombreGpx(una));

    final resultado = await exportacion.exportar([una, otra]);

    expect(resultado!.errores, hasLength(1));
    expect(resultado.sesionesExportadas, {'otra'});
    expect(resultado.archivosCorrectos, contains(nombreJson(una)));
    expect(resultado.archivosCorrectos, isNot(contains(nombreGpx(una))));
  });

  test('borra el GPX y el JSON de la sesión en la carpeta actual', () async {
    await configuracion.elegirDirectorioExportacion();
    final sesion = sesionDePrueba();

    final resultado = await exportacion.borrarArchivosDeSesion(sesion);

    expect(resultado, isNotNull);
    expect(resultado!.correcto, isTrue);
    expect(resultado.borrados, 2);
    expect(servicio.nombresBorrados, [nombreGpx(sesion), nombreJson(sesion)]);
  });

  test('sin carpeta no intenta borrar archivos y explica', () async {
    final resultado = await exportacion.borrarArchivosDeSesion(
      sesionDePrueba(),
    );

    expect(resultado, isNull);
    expect(exportacion.error, contains('carpeta'));
    expect(servicio.nombresBorrados, isEmpty);
  });

  test('un permiso perdido deja un error al borrar', () async {
    await configuracion.elegirDirectorioExportacion();
    servicio.errorBorrado = PlatformException(
      code: 'sin_permiso',
      message: 'La carpeta ya no es accesible.',
    );

    final resultado = await exportacion.borrarArchivosDeSesion(
      sesionDePrueba(),
    );

    expect(resultado, isNull);
    expect(exportacion.error, 'La carpeta ya no es accesible.');
  });

  test('informa de archivos no encontrados sin fallar', () async {
    await configuracion.elegirDirectorioExportacion();
    servicio.noEncontrados = 1;

    final resultado = await exportacion.borrarArchivosDeSesion(
      sesionDePrueba(),
    );

    expect(resultado, isNotNull);
    expect(resultado!.noEncontrados, 1);
    expect(resultado.correcto, isFalse);
  });

  test('informa de errores parciales al borrar', () async {
    await configuracion.elegirDirectorioExportacion();
    servicio.erroresBorrado.add('gpx: no se pudo borrar');

    final resultado = await exportacion.borrarArchivosDeSesion(
      sesionDePrueba(),
    );

    expect(resultado, isNotNull);
    expect(resultado!.errores, hasLength(1));
    expect(resultado.correcto, isFalse);
  });
}
