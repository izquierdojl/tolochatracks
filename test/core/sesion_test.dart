import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';

void main() {
  final inicio = DateTime(2026, 11, 20, 18, 30);
  final sesion = Sesion(
    id: Sesion.generarId(inicio),
    actividad: Actividad.senderismo,
    inicio: inicio,
    fin: inicio.add(const Duration(hours: 1, minutes: 20)),
    duracionActiva: const Duration(hours: 1, minutes: 15),
    puntos: [
      PuntoRuta(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: inicio,
        altitud: 12,
        precision: 4,
        velocidad: 1.2,
      ),
      PuntoRuta(
        latitud: 37.3901,
        longitud: -5.9835,
        tiempo: inicio.add(const Duration(minutes: 5)),
        altitud: 18,
      ),
    ],
  );

  test('la sesión sobrevive a un round-trip JSON', () {
    final json = sesion.aJson();
    final reconstruida = Sesion.desdeJson(json);

    expect(reconstruida.id, sesion.id);
    expect(reconstruida.actividad, Actividad.senderismo);
    expect(reconstruida.formato, formatoSesionActual);
    expect(reconstruida.inicio, sesion.inicio);
    expect(reconstruida.fin, sesion.fin);
    expect(reconstruida.duracionActiva, sesion.duracionActiva);
    expect(reconstruida.puntos, hasLength(2));
    expect(reconstruida.puntos.first.latitud, closeTo(37.3891, 0.000001));
    expect(reconstruida.puntos.first.altitud, 12);
    expect(reconstruida.puntos.last.precision, isNull);
  });

  test('el id es único y seguro para un nombre de archivo', () {
    final otro = Sesion.generarId(inicio);
    expect(sesion.id, isNot(otro));
    expect(sesion.id, matches(RegExp(r'^[0-9T-]+-[0-9a-f]{4}$')));
  });

  test('una actividad desconocida cae en Otras', () {
    final json = Map<String, Object?>.from(sesion.aJson())
      ..['actividad'] = 'paracaidismo';
    expect(Sesion.desdeJson(json).actividad, Actividad.otras);
  });

  test('los puntos inválidos se ignoran sin tumbar la sesión', () {
    final json = Map<String, Object?>.from(sesion.aJson());
    json['puntos'] = [
      {'lat': 'no', 'lon': 1, 't': 'no'},
      {'lat': 37.0, 'lon': -5.0, 't': '2026-11-20T18:30:00.000Z'},
    ];
    final reconstruida = Sesion.desdeJson(json);
    expect(reconstruida.puntos, hasLength(1));
  });

  test('un JSON sin inicio lanza FormatException', () {
    expect(
      () => Sesion.desdeJson({'id': 'x', 'puntos': <Object?>[]}),
      throwsFormatException,
    );
  });

  test('el borrador se distingue por no tener fin', () {
    final borrador = Sesion(
      id: sesion.id,
      actividad: sesion.actividad,
      inicio: sesion.inicio,
      duracionActiva: const Duration(minutes: 5),
      puntos: sesion.puntos,
    );
    expect(borrador.abierta, isTrue);
    final json = borrador.aJson();
    expect(json.containsKey('fin'), isFalse);
    expect(Sesion.desdeJson(json).fin, isNull);
  });

  test('la actividad conoce si usa ritmo', () {
    expect(Actividad.correr.usaRitmo, isTrue);
    expect(Actividad.senderismo.usaRitmo, isTrue);
    expect(Actividad.bicicleta.usaRitmo, isFalse);
    expect(Actividad.otras.usaRitmo, isFalse);
  });
}
