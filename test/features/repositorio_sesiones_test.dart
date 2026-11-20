import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/features/sesiones/data/sesiones_repositorio.dart';

Sesion crearSesion(String id, DateTime inicio) => Sesion(
  id: id,
  actividad: Actividad.correr,
  inicio: inicio,
  fin: inicio.add(const Duration(minutes: 30)),
  duracionActiva: const Duration(minutes: 28),
  puntos: [
    PuntoRuta(
      latitud: 37.3891,
      longitud: -5.9845,
      tiempo: inicio,
      altitud: 10,
      precision: 5,
    ),
    PuntoRuta(
      latitud: 37.3991,
      longitud: -5.9845,
      tiempo: inicio.add(const Duration(minutes: 28)),
      altitud: 25,
      precision: 5,
    ),
  ],
);

void main() {
  late Directory temporal;
  late SesionesRepositorio repositorio;

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('tolochatracks_test_');
    repositorio = SesionesRepositorio(directorioBase: temporal);
  });

  tearDown(() async {
    if (await temporal.exists()) {
      await temporal.delete(recursive: true);
    }
  });

  test('guarda y recupera una sesión', () async {
    final sesion = crearSesion(
      '20261120T183000-abcd',
      DateTime(2026, 11, 20, 18, 30),
    );
    await repositorio.guardar(sesion);

    final recuperada = await repositorio.cargar(sesion.id);
    expect(recuperada, isNotNull);
    expect(recuperada!.id, sesion.id);
    expect(recuperada.puntos, hasLength(2));
    expect(recuperada.actividad, Actividad.correr);
  });

  test('lista las sesiones de la más reciente a la más antigua', () async {
    await repositorio.guardar(crearSesion('vieja', DateTime(2026, 11, 18, 8)));
    await repositorio.guardar(crearSesion('nueva', DateTime(2026, 11, 20, 18)));

    final sesiones = await repositorio.listar();
    expect(sesiones.map((sesion) => sesion.id), ['nueva', 'vieja']);
  });

  test('no lista el borrador como sesión', () async {
    final inicio = DateTime(2026, 11, 20, 18);
    await repositorio.guardarBorrador(crearSesion('borrador', inicio));
    final sesiones = await repositorio.listar();
    expect(sesiones, isEmpty);
    final borrador = await repositorio.cargarBorrador();
    expect(borrador, isNotNull);
    expect(borrador!.id, 'borrador');
  });

  test('elimina una sesión y su archivo', () async {
    final sesion = crearSesion('borrar', DateTime(2026, 11, 20, 18));
    await repositorio.guardar(sesion);
    await repositorio.eliminar(sesion.id);
    expect(await repositorio.cargar(sesion.id), isNull);
    expect(await repositorio.listar(), isEmpty);
  });

  test('ignora archivos corruptos al listar', () async {
    final carpeta = Directory('${temporal.path}/sesiones');
    await carpeta.create(recursive: true);
    await File('${carpeta.path}/corrupto.json').writeAsString('{no es json');
    await repositorio.guardar(crearSesion('buena', DateTime(2026, 11, 20, 18)));
    final sesiones = await repositorio.listar();
    expect(sesiones, hasLength(1));
    expect(sesiones.single.id, 'buena');
  });

  test('no deja archivos temporales tras guardar', () async {
    await repositorio.guardar(
      crearSesion('temporal', DateTime(2026, 11, 20, 18)),
    );
    final carpeta = Directory('${temporal.path}/sesiones');
    final temporales = await carpeta
        .list()
        .where((entrada) => entrada.path.endsWith('.tmp'))
        .toList();
    expect(temporales, isEmpty);
  });

  test('borra el borrador', () async {
    await repositorio.guardarBorrador(
      crearSesion('borrador', DateTime(2026, 11, 20, 18)),
    );
    await repositorio.borrarBorrador();
    expect(await repositorio.cargarBorrador(), isNull);
  });
}
