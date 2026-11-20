import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/calculos/calculos_ruta.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';

PuntoRuta punto(
  double latitud,
  double longitud,
  DateTime tiempo, {
  double? altitud,
  double? precision = 5,
}) => PuntoRuta(
  latitud: latitud,
  longitud: longitud,
  tiempo: tiempo,
  altitud: altitud,
  precision: precision,
);

void main() {
  final inicio = DateTime(2026, 11, 20, 18);
  const latSevilla = 37.3891;
  const lonSevilla = -5.9845;
  const metroPorGradoLatitud = 111195.0;

  group('distanciaHaversine', () {
    test('un grado de latitud ronda 111 km', () {
      final distancia = distanciaHaversine(
        punto(0, 0, inicio),
        punto(1, 0, inicio.add(const Duration(minutes: 1))),
      );
      expect(distancia, closeTo(111195, 200));
    });

    test('el mismo punto da distancia cero', () {
      final puntoA = punto(latSevilla, lonSevilla, inicio);
      expect(distanciaHaversine(puntoA, puntoA), 0);
    });
  });

  group('puntoAceptable', () {
    test('rechaza una precisión peor de 100 metros', () {
      expect(
        puntoAceptable(
          null,
          punto(latSevilla, lonSevilla, inicio, precision: 150),
        ),
        isFalse,
      );
    });

    test('rechaza un salto imposible', () {
      final primero = punto(latSevilla, lonSevilla, inicio);
      final segundo = punto(
        latSevilla + 0.1,
        lonSevilla,
        inicio.add(const Duration(seconds: 1)),
      );
      expect(puntoAceptable(primero, segundo), isFalse);
    });

    test('acepta un movimiento normal', () {
      final primero = punto(latSevilla, lonSevilla, inicio);
      final segundo = punto(
        latSevilla + 0.001,
        lonSevilla,
        inicio.add(const Duration(seconds: 10)),
      );
      expect(puntoAceptable(primero, segundo), isTrue);
    });
  });

  group('calcularEstadisticas', () {
    test('suma la distancia de una ruta recta', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio, altitud: 10),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
          altitud: 12,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 5),
      );
      expect(estadisticas.distanciaMetros, closeTo(1000, 10));
      expect(estadisticas.duracionActiva, const Duration(minutes: 5));
      expect(estadisticas.velocidadMedia, closeTo(1000 / 300, 0.05));
      expect(estadisticas.velocidadMaxima, closeTo(1000 / 300, 0.05));
      expect(estadisticas.puntos, 2);
    });

    test('filtra el jitter de estar parado', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 0.4 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 2)),
        ),
        punto(
          latSevilla + 0.8 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 4)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 4),
      );
      expect(estadisticas.distanciaMetros, 0);
    });

    test('ignora puntos con precisión insuficiente', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
          precision: 120,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 5),
      );
      expect(estadisticas.distanciaMetros, 0);
      expect(estadisticas.puntos, 1);
    });

    test('acumula desnivel con altitud suavizada', () {
      final puntos = <PuntoRuta>[];
      for (var i = 0; i < 6; i++) {
        puntos.add(
          punto(
            latSevilla + i * 10 / metroPorGradoLatitud,
            lonSevilla,
            inicio.add(Duration(seconds: i * 10)),
            altitud: 100,
          ),
        );
      }
      for (var i = 6; i < 40; i++) {
        puntos.add(
          punto(
            latSevilla + i * 10 / metroPorGradoLatitud,
            lonSevilla,
            inicio.add(Duration(seconds: i * 10)),
            altitud: 130,
          ),
        );
      }
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 400),
      );
      expect(estadisticas.altitudMinima, 100);
      expect(estadisticas.altitudMaxima, 130);
      expect(estadisticas.desnivelPositivo, greaterThan(15));
      expect(estadisticas.desnivelNegativo, lessThan(2));
    });

    test('el tiempo total usa el inicio de la sesión, no el primer punto', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio.add(const Duration(seconds: 10))),
        punto(
          latSevilla + 100 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 2)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 2),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 3)),
      );
      expect(estadisticas.duracionTotal, const Duration(minutes: 3));
    });

    test('calcula el ritmo medio por kilómetro', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 2000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 10)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 10),
      );
      expect(estadisticas.ritmoMedio, isNotNull);
      expect(estadisticas.ritmoMedio!.inSeconds, closeTo(300, 5));
    });
  });
}
