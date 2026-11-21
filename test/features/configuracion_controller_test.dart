import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';
import 'package:tolochatracks/core/models/proveedor_mapas.dart';
import 'package:tolochatracks/features/configuracion/data/configuracion_repositorio.dart';
import 'package:tolochatracks/features/configuracion/ui/configuracion_controller.dart';

import '../apoyo/falsos.dart';

void main() {
  test('por defecto usa el tema del sistema y no tiene carpeta', () async {
    SharedPreferences.setMockInitialValues({});
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: ServicioExportacionFalso(),
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();
    expect(controlador.tema, ThemeMode.system);
    expect(controlador.perfilGps, PerfilGps.equilibrada);
    expect(controlador.tieneDirectorio, isFalse);
    expect(controlador.directorioExportacionNombre, isNull);
  });

  test('persiste el tema y la carpeta entre instancias', () async {
    SharedPreferences.setMockInitialValues({});
    final servicio = ServicioExportacionFalso();
    final primero = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(primero.dispose);
    await primero.cargar();
    await primero.cambiarTema(ThemeMode.dark);
    final directorio = await primero.elegirDirectorioExportacion();
    expect(directorio, isNotNull);
    expect(primero.directorioExportacionNombre, 'Rutas');

    final segundo = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(segundo.dispose);
    await segundo.cargar();
    expect(segundo.tema, ThemeMode.dark);
    expect(segundo.tieneDirectorio, isTrue);
    expect(segundo.directorioExportacionNombre, 'Rutas');
  });

  test('persiste el proveedor de mapas', () async {
    SharedPreferences.setMockInitialValues({});
    final servicio = ServicioExportacionFalso();
    final primero = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(primero.dispose);
    await primero.cargar();
    expect(primero.proveedorMapas, ProveedorMapas.osm);
    await primero.cambiarProveedorMapas(ProveedorMapas.openTopoMap);

    final segundo = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(segundo.dispose);
    await segundo.cargar();
    expect(segundo.proveedorMapas, ProveedorMapas.openTopoMap);
  });

  test('quitar la carpeta la olvida y persiste', () async {
    SharedPreferences.setMockInitialValues({});
    final servicio = ServicioExportacionFalso();
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();
    await controlador.elegirDirectorioExportacion();
    await controlador.quitarDirectorioExportacion();
    expect(controlador.tieneDirectorio, isFalse);

    final segundo = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(segundo.dispose);
    await segundo.cargar();
    expect(segundo.tieneDirectorio, isFalse);
  });

  test('cancelar la selección conserva la carpeta anterior', () async {
    SharedPreferences.setMockInitialValues({});
    final servicio = ServicioExportacionFalso();
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();
    await controlador.elegirDirectorioExportacion();
    servicio.directorio = null;
    final resultado = await controlador.elegirDirectorioExportacion();
    expect(resultado, isNull);
    expect(controlador.tieneDirectorio, isTrue);
    expect(controlador.directorioExportacionNombre, 'Rutas');
  });

  test('persiste el perfil GPS entre instancias', () async {
    SharedPreferences.setMockInitialValues({});
    final servicio = ServicioExportacionFalso();
    final primero = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(primero.dispose);
    await primero.cargar();
    await primero.cambiarPerfilGps(PerfilGps.maxima);
    expect(primero.perfilGps, PerfilGps.maxima);

    final segundo = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: servicio,
    );
    addTearDown(segundo.dispose);
    await segundo.cargar();
    expect(segundo.perfilGps, PerfilGps.maxima);
  });

  test('una clave de perfil desconocida cae en Equilibrada', () async {
    SharedPreferences.setMockInitialValues({
      'config.gps.perfil': 'desconocido',
    });
    final controlador = ConfiguracionController(
      repositorio: ConfiguracionRepositorio(),
      exportacion: ServicioExportacionFalso(),
    );
    addTearDown(controlador.dispose);
    await controlador.cargar();
    expect(controlador.perfilGps, PerfilGps.equilibrada);
  });
}
