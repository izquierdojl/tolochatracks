import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/exportacion/exportacion_sesion.dart';
import 'package:tolochatracks/core/exportacion/gpx.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/core/servicios/exportacion.dart';

Sesion crearSesion({bool conAltitud = true}) {
  final inicio = DateTime(2026, 11, 20, 18, 30);
  return Sesion(
    id: '20261120T183000-abcd',
    actividad: Actividad.senderismo,
    inicio: inicio,
    fin: inicio.add(const Duration(minutes: 20)),
    duracionActiva: const Duration(minutes: 19),
    puntos: [
      PuntoRuta(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: inicio,
        altitud: conAltitud ? 100 : null,
        precision: 5,
      ),
      PuntoRuta(
        latitud: 37.3981,
        longitud: -5.9845,
        tiempo: inicio.add(const Duration(minutes: 19)),
        altitud: conAltitud ? 150 : null,
        precision: 5,
      ),
    ],
  );
}

void main() {
  test('el GPX es 1.1, contiene metadatos y un trkpt por punto', () {
    final sesion = crearSesion();
    final gpx = gpxDeSesion(sesion);
    final primerTiempo = sesion.puntos.first.tiempo.toUtc().toIso8601String();
    expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(gpx, contains('version="1.1"'));
    expect(gpx, contains('creator="TolochaTracks"'));
    expect(gpx, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
    expect(gpx, contains('<name>Senderismo'));
    expect(gpx, contains('<type>hiking</type>'));
    expect('<trkpt'.allMatches(gpx), hasLength(2));
    expect(gpx, contains('<ele>100.0</ele>'));
    expect(gpx, contains('<time>$primerTiempo</time>'));
    expect(gpx.trimRight(), endsWith('</gpx>'));
  });

  test('el GPX omite ele cuando no hay altitud', () {
    final gpx = gpxDeSesion(crearSesion(conAltitud: false));
    expect(gpx, isNot(contains('<ele>')));
    expect('<trkpt'.allMatches(gpx), hasLength(2));
  });

  test('el JSON exportado se puede volver a leer', () {
    final sesion = crearSesion();
    final json = jsonDeSesion(sesion);
    final mapa = jsonDecode(json);
    expect(mapa, isA<Map<String, Object?>>());
    final reconstruida = Sesion.desdeJson(
      Map<String, Object?>.from(mapa as Map),
    );
    expect(reconstruida.id, sesion.id);
    expect(reconstruida.puntos, hasLength(2));
    expect(reconstruida.actividad, Actividad.senderismo);
  });

  test('los nombres son ASCII seguros y distinguen formatos', () {
    final sesion = crearSesion();
    final gpx = nombreGpx(sesion);
    final json = nombreJson(sesion);
    expect(gpx, endsWith('.gpx'));
    expect(json, endsWith('.json'));
    expect(gpx, contains('senderismo'));
    expect(gpx, contains('20261120_1830'));
    expect(gpx, matches(RegExp(r'^[A-Za-z0-9._-]+$')));
    expect(nombreBaseSesion(sesion), nombreBaseSesion(sesion));
  });

  test('normaliza acentos en el identificador', () {
    final sesion = Sesion(
      id: 'sesión-á',
      actividad: Actividad.senderismo,
      inicio: DateTime(2026, 11, 20, 18),
      duracionActiva: Duration.zero,
      puntos: const [],
    );
    expect(nombreBaseSesion(sesion), contains('sesion-a'));
    expect(nombreBaseSesion(sesion), matches(RegExp(r'^[A-Za-z0-9._-]+$')));
  });

  test('archivosDeSesion genera GPX y JSON con sus MIME', () {
    final archivos = archivosDeSesion(crearSesion());
    expect(archivos, hasLength(2));
    expect(archivos[0].mime, 'application/gpx+xml');
    expect(archivos[1].mime, 'application/json');
    expect(archivos[0].contenido, contains('<gpx'));
    expect(archivos[1].contenido, contains('"formato": 2'));
  });

  test('el resultado de borrado es correcto solo sin errores ni ausentes', () {
    expect(
      const ResultadoBorrado(
        borrados: 2,
        noEncontrados: 0,
        errores: [],
      ).correcto,
      isTrue,
    );
    expect(
      const ResultadoBorrado(
        borrados: 1,
        noEncontrados: 1,
        errores: [],
      ).correcto,
      isFalse,
    );
    expect(
      const ResultadoBorrado(
        borrados: 1,
        noEncontrados: 0,
        errores: ['gpx: no se pudo borrar'],
      ).correcto,
      isFalse,
    );
  });
}
