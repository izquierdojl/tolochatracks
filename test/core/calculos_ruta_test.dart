import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/calculos/calculos_ruta.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';

PuntoRuta punto(
  double latitud,
  double longitud,
  DateTime tiempo, {
  double? altitud,
  double? precision = 5,
  int segmento = 0,
}) => PuntoRuta(
  latitud: latitud,
  longitud: longitud,
  tiempo: tiempo,
  altitud: altitud,
  precision: precision,
  segmento: segmento,
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

  group('segmentos', () {
    test('el acumulador no suma distancia ni velocidad entre segmentos', () {
      final acumulador = AcumuladorRuta();
      final a = punto(latSevilla, lonSevilla, inicio);
      final b = punto(
        latSevilla + 100 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(seconds: 10)),
      );
      final c = punto(
        latSevilla + 180 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 20)),
        segmento: 1,
      );
      final d = punto(
        latSevilla + 280 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 20, seconds: 10)),
        segmento: 1,
      );
      for (final p in [a, b, c, d]) {
        acumulador.agregar(p);
      }
      expect(acumulador.distanciaMetros, closeTo(200, 2));
      expect(acumulador.puntosValidos, 4);
    });

    test('la pausa no suma distancia ni tiempo activo', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
        ),
        punto(
          latSevilla + 1080 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 20)),
          segmento: 1,
        ),
        punto(
          latSevilla + 2080 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 25)),
          segmento: 1,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 10),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 25)),
      );
      expect(estadisticas.distanciaMetros, closeTo(2000, 20));
      expect(estadisticas.serieDistancia.last.x, closeTo(10, 0.2));
      expect(estadisticas.porMinuto, hasLength(10));
      expect(estadisticas.parciales, hasLength(2));
      expect(estadisticas.parciales[0].duracion, const Duration(minutes: 5));
      expect(estadisticas.parciales[1].duracion, const Duration(minutes: 5));
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

  group('series y parciales', () {
    List<PuntoRuta> rutaDeEjemplo() => [
      punto(latSevilla, lonSevilla, inicio, altitud: 100),
      punto(
        latSevilla + 1000 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 5)),
        altitud: 130,
      ),
      punto(
        latSevilla + 2500 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 15)),
        altitud: 110,
      ),
    ];

    test('genera las series de distancia, velocidad y altitud', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.serieDistancia.length, greaterThanOrEqualTo(2));
      expect(estadisticas.serieDistancia.first.x, 0);
      expect(estadisticas.serieDistancia.last.x, closeTo(15, 0.1));
      expect(estadisticas.serieDistancia.last.y, closeTo(2.5, 0.01));
      expect(estadisticas.serieVelocidad, isNotEmpty);
      expect(
        estadisticas.serieVelocidad.every((m) => m.y.isFinite && m.y >= 0),
        isTrue,
      );
      expect(estadisticas.serieAltitud, isNotEmpty);
      expect(estadisticas.serieAltitud.last.y, closeTo(110, 20));
    });

    test('genera parciales por km con el último tramo incompleto', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(estadisticas.parciales[0].numero, 1);
      expect(estadisticas.parciales[0].distanciaMetros, closeTo(1000, 1));
      expect(estadisticas.parciales[0].duracion.inSeconds, closeTo(300, 3));
      expect(estadisticas.parciales[1].distanciaMetros, closeTo(1000, 1));
      expect(estadisticas.parciales[1].duracion.inSeconds, closeTo(400, 3));
      expect(estadisticas.parciales[2].distanciaMetros, closeTo(500, 5));
      expect(estadisticas.parciales[2].duracion.inSeconds, closeTo(200, 3));
      expect(estadisticas.parciales[2].completo, isFalse);
      expect(estadisticas.parciales.first.completo, isTrue);
    });

    test('reparte la distancia por minuto y rellena los minutos', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.porMinuto, hasLength(15));
      final total = estadisticas.porMinuto.fold<double>(
        0,
        (suma, minuto) => suma + minuto.metros,
      );
      expect(total, closeTo(2500, 30));
      expect(estadisticas.porMinuto.first.minuto, 0);
      expect(estadisticas.porMinuto.last.minuto, 14);
    });

    test('sin altitud, la serie y los campos quedan vacíos', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 100 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 1)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 1),
      );
      expect(estadisticas.serieAltitud, isEmpty);
      expect(estadisticas.tieneAltitud, isFalse);
    });

    test('una ruta de menos de 20 metros no genera parciales', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 10 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 10)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 10),
      );
      expect(estadisticas.parciales, isEmpty);
    });

    test('muestrea rutas largas para los gráficos', () {
      final puntos = <PuntoRuta>[
        for (var i = 0; i < 1000; i++)
          punto(
            latSevilla + i * 5.0 / metroPorGradoLatitud,
            lonSevilla,
            inicio.add(Duration(seconds: i * 5)),
            altitud: 100 + (i % 50),
          ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 4995),
      );
      expect(estadisticas.serieDistancia.length, lessThanOrEqualTo(240));
      expect(estadisticas.serieDistancia.last.x, closeTo(4995 / 60, 0.1));
      expect(estadisticas.parciales.first.numero, 1);
    });

    test('una sesión de un solo punto no tiene series ni parciales', () {
      final estadisticas = calcularEstadisticas([
        punto(latSevilla, lonSevilla, inicio),
      ], duracionActiva: Duration.zero);
      expect(estadisticas.serieDistancia, isEmpty);
      expect(estadisticas.serieVelocidad, isEmpty);
      expect(estadisticas.parciales, isEmpty);
      expect(estadisticas.porMinuto, isEmpty);
    });
  });
}
