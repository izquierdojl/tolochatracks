import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/features/compartir/ui/compartir_controller.dart';

import '../apoyo/falsos.dart';

Sesion sesionDePrueba({bool conPuntos = true}) {
  final inicio = DateTime(2026, 11, 20, 18);
  return Sesion(
    id: 'compartir',
    actividad: Actividad.correr,
    inicio: inicio,
    fin: inicio.add(const Duration(minutes: 30)),
    duracionActiva: const Duration(minutes: 29),
    puntos: conPuntos
        ? [
            PuntoRuta(
              latitud: 37.3891,
              longitud: -5.9845,
              tiempo: inicio,
              precision: 5,
            ),
          ]
        : const [],
  );
}

void main() {
  late ServicioCompartirFalso servicio;
  late CompartirController controlador;

  setUp(() {
    servicio = ServicioCompartirFalso();
    controlador = CompartirController(servicio: servicio);
  });

  tearDown(() => controlador.dispose());

  test('comparte una sesión y limpia el progreso', () async {
    final sesion = sesionDePrueba();

    expect(await controlador.compartir(sesion), isTrue);
    expect(servicio.compartidas, hasLength(1));
    expect(servicio.compartidas.single.id, sesion.id);
    expect(controlador.compartiendo, isFalse);
    expect(controlador.sesionCompartiendoId, isNull);
    expect(controlador.error, isNull);
  });

  test('no comparte una sesión sin puntos', () async {
    expect(
      await controlador.compartir(sesionDePrueba(conPuntos: false)),
      isFalse,
    );
    expect(servicio.compartidas, isEmpty);
    expect(controlador.error, contains('puntos'));
  });

  test('un fallo del servicio deja un error y no deja progreso', () async {
    servicio.fallar = true;

    expect(await controlador.compartir(sesionDePrueba()), isFalse);
    expect(controlador.error, 'No se pudo compartir la ruta.');
    expect(controlador.compartiendo, isFalse);
  });

  test('ignora una segunda pulsación mientras comparte', () async {
    final espera = Completer<void>();
    servicio.espera = espera;
    final primera = controlador.compartir(sesionDePrueba());
    await Future<void>.delayed(Duration.zero);

    expect(controlador.compartiendo, isTrue);
    expect(controlador.sesionCompartiendoId, 'compartir');
    expect(await controlador.compartir(sesionDePrueba()), isFalse);
    expect(servicio.compartidas, isEmpty);

    espera.complete();
    expect(await primera, isTrue);
    expect(servicio.compartidas, hasLength(1));
  });

  test('limpiarError elimina el mensaje', () async {
    servicio.fallar = true;
    await controlador.compartir(sesionDePrueba());
    expect(controlador.error, isNotNull);

    controlador.limpiarError();
    expect(controlador.error, isNull);
  });
}
