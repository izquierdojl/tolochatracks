import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/calculos/calculos_ruta.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';
import 'package:tolochatracks/core/models/estadisticas_ruta.dart';
import 'package:tolochatracks/core/models/filtro_ruta.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';

PuntoRuta punto(
  double latitud,
  double longitud,
  DateTime tiempo, {
  double? altitud,
  double? precision = 5,
  int segmento = 0,
  double? velocidad,
}) => PuntoRuta(
  latitud: latitud,
  longitud: longitud,
  tiempo: tiempo,
  altitud: altitud,
  precision: precision,
  segmento: segmento,
  velocidad: velocidad,
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
    test('rechaza una precisión peor que el umbral por defecto', () {
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

  group('filtro por perfil y velocidad fiable', () {
    test('la precisión depende del perfil', () {
      final equilibrada = FiltroRuta.dePerfil(
        PerfilGps.equilibrada,
        Actividad.correr,
      );
      expect(
        puntoAceptable(
          null,
          punto(latSevilla, lonSevilla, inicio, precision: 25),
          filtro: equilibrada,
        ),
        isTrue,
      );
      expect(
        puntoAceptable(
          null,
          punto(latSevilla, lonSevilla, inicio, precision: 35),
          filtro: equilibrada,
        ),
        isFalse,
      );
      final ahorro = FiltroRuta.dePerfil(PerfilGps.ahorro, Actividad.correr);
      expect(
        puntoAceptable(
          null,
          punto(latSevilla, lonSevilla, inicio, precision: 35),
          filtro: ahorro,
        ),
        isTrue,
      );
      expect(
        puntoAceptable(
          null,
          punto(latSevilla, lonSevilla, inicio, precision: 45),
          filtro: ahorro,
        ),
        isFalse,
      );
    });

    test('la velocidad máxima depende de la actividad', () {
      final primero = punto(latSevilla, lonSevilla, inicio);
      final veinteMetros = punto(
        latSevilla + 20 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(seconds: 2)),
      );
      final diezMetros = punto(
        latSevilla + 10 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(seconds: 2)),
      );
      expect(
        puntoAceptable(
          primero,
          veinteMetros,
          filtro: FiltroRuta.dePerfil(PerfilGps.equilibrada, Actividad.correr),
        ),
        isFalse,
      );
      expect(
        puntoAceptable(
          primero,
          diezMetros,
          filtro: FiltroRuta.dePerfil(PerfilGps.equilibrada, Actividad.correr),
        ),
        isTrue,
      );
      expect(
        puntoAceptable(
          primero,
          diezMetros,
          filtro: FiltroRuta.dePerfil(PerfilGps.equilibrada, Actividad.caminar),
        ),
        isFalse,
      );
      expect(
        puntoAceptable(
          primero,
          veinteMetros,
          filtro: FiltroRuta.dePerfil(
            PerfilGps.equilibrada,
            Actividad.bicicleta,
          ),
        ),
        isTrue,
      );
    });

    test('usa la menor entre la velocidad reportada y la derivada', () {
      final filtro = const FiltroRuta(
        precisionMaxima: 40,
        velocidadMaxima: 120 / 3.6,
        calentamiento: Duration.zero,
      );
      final acumulador = AcumuladorRuta(filtro: filtro);
      acumulador.agregar(punto(latSevilla, lonSevilla, inicio));
      acumulador.agregar(
        punto(
          latSevilla + 43.8 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 3)),
          velocidad: 1.05,
        ),
      );
      expect(acumulador.velocidadMaxima * 3.6, closeTo(3.8, 0.1));
    });

    test('el tope de actividad descarta el salto de 52,5 km/h', () {
      final filtro = FiltroRuta.dePerfil(
        PerfilGps.equilibrada,
        Actividad.correr,
        calentamiento: Duration.zero,
      );
      final acumulador = AcumuladorRuta(filtro: filtro);
      acumulador.agregar(punto(latSevilla, lonSevilla, inicio));
      acumulador.agregar(
        punto(
          latSevilla + 43.8 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 3)),
          velocidad: 1.05,
        ),
      );
      expect(acumulador.puntosValidos, 1);
      expect(acumulador.velocidadMaxima, 0);
    });

    test('sin velocidad reportada usa una ventana de 10 s', () {
      final filtro = const FiltroRuta(
        precisionMaxima: 40,
        velocidadMaxima: 120 / 3.6,
        calentamiento: Duration.zero,
      );
      final acumulador = AcumuladorRuta(filtro: filtro);
      for (var i = 0; i <= 9; i++) {
        acumulador.agregar(
          punto(
            latSevilla + i * 3 / metroPorGradoLatitud,
            lonSevilla,
            inicio.add(Duration(seconds: i * 2)),
          ),
        );
      }
      acumulador.agregar(
        punto(
          latSevilla + 36.4 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(milliseconds: 19800)),
        ),
      );
      expect(acumulador.velocidadMaxima * 3.6, lessThan(12));
    });

    test('el primer punto de un segmento no aporta velocidad', () {
      final filtro = FiltroRuta.dePerfil(
        PerfilGps.equilibrada,
        Actividad.correr,
        calentamiento: Duration.zero,
      );
      final acumulador = AcumuladorRuta(filtro: filtro);
      acumulador.agregar(punto(latSevilla, lonSevilla, inicio, segmento: 0));
      acumulador.agregar(
        punto(
          latSevilla + 20 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 1)),
          segmento: 1,
          velocidad: 33.9 / 3.6,
        ),
      );
      expect(acumulador.puntosValidos, 2);
      expect(acumulador.velocidadMaxima, 0);
    });

    test('la vista válida quita los fixes malos y conserva segmentos', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio, precision: 7),
        punto(
          latSevilla + 10 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 2)),
          precision: 44.2,
        ),
        punto(
          latSevilla + 20 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 4)),
          precision: 54.7,
        ),
        punto(
          latSevilla + 30 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 6)),
          precision: 63.7,
        ),
        punto(
          latSevilla + 40 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 8)),
          precision: 9,
          segmento: 1,
        ),
      ];
      final validos = puntosValidosDeSesion(
        puntos,
        actividad: Actividad.correr,
      );
      expect(validos.map((p) => p.segmento), [0, 1]);
      expect(validos.map((p) => p.precision), [7, 9]);
    });

    test('el máximo no incluye un pico de un solo punto', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio, velocidad: 0),
        punto(
          latSevilla + 3 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 2)),
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 6 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 4)),
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 50 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 6)),
          velocidad: 1.05,
        ),
        punto(
          latSevilla + 9 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 8)),
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 12 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 10)),
          velocidad: 1.6,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 10),
        actividad: Actividad.correr,
      );
      expect(estadisticas.velocidadMaxima * 3.6, lessThan(6));
      expect(
        estadisticas.serieVelocidad.every((muestra) => muestra.y < 10),
        isTrue,
      );
    });
  });

  group('sesión sintética tipo GPX real', () {
    test('quita el pico de 52,5 y la pausa y deja un máximo creíble', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio, velocidad: 0),
        punto(
          latSevilla + 100 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 20)),
          precision: 7,
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 200 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 40)),
          precision: 7,
          velocidad: 3.0,
        ),
        punto(
          latSevilla + 243.8 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 43)),
          precision: 54.7,
          velocidad: 1.05,
        ),
        punto(
          latSevilla + 300 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 60)),
          precision: 7,
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 400 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 80)),
          precision: 7,
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 480 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 380)),
          precision: 9,
          segmento: 1,
          velocidad: 3.0,
        ),
        punto(
          latSevilla + 580 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 400)),
          precision: 7,
          segmento: 1,
          velocidad: 1.6,
        ),
        punto(
          latSevilla + 680 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 420)),
          precision: 7,
          segmento: 1,
          velocidad: 1.6,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 2),
        inicio: inicio,
        fin: inicio.add(const Duration(seconds: 420)),
        actividad: Actividad.correr,
      );
      expect(estadisticas.distanciaMetros, closeTo(600, 5));
      expect(estadisticas.velocidadMaxima * 3.6, closeTo(10.8, 0.2));
      expect(estadisticas.serieDistancia.last.x, closeTo(2, 0.1));
      expect(estadisticas.puntos, 8);
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

    test('genera las series de velocidad y altitud frente a tiempo', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.serieVelocidadTiempo, isNotEmpty);
      expect(estadisticas.serieVelocidadTiempo.last.x, closeTo(15, 0.1));
      expect(
        estadisticas.serieVelocidadTiempo.every(
          (m) => m.y.isFinite && m.y >= 0,
        ),
        isTrue,
      );
      expect(estadisticas.serieAltitudTiempo, isNotEmpty);
      expect(estadisticas.serieAltitudTiempo.last.x, closeTo(15, 0.1));
      expect(estadisticas.serieAltitudTiempo.last.y, closeTo(110, 20));
    });

    test('las series por tiempo usan tiempo activo y no la pausa', () {
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
      expect(estadisticas.serieVelocidadTiempo.last.x, closeTo(10, 0.2));
      expect(estadisticas.serieAltitudTiempo, isEmpty);
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

  group('parciales configurables', () {
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

    List<PuntoRuta> rutaDeTresKilometros() => [
      punto(latSevilla, lonSevilla, inicio, altitud: 100),
      punto(
        latSevilla + 1000 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 4)),
        altitud: 110,
      ),
      punto(
        latSevilla + 2000 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 10)),
        altitud: 90,
      ),
      punto(
        latSevilla + 3000 / metroPorGradoLatitud,
        lonSevilla,
        inicio.add(const Duration(minutes: 15)),
        altitud: 120,
      ),
    ];

    test('por distancia cada 500 m genera cinco tramos', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
        parciales: ConfiguracionParciales.distancia(500),
      );
      expect(estadisticas.parciales, hasLength(5));
      expect(estadisticas.parciales.every((p) => p.completo), isTrue);
      expect(estadisticas.parciales.first.distanciaMetros, closeTo(500, 1));
      expect(estadisticas.parciales.last.distanciaMetros, closeTo(500, 1));
    });

    test('por distancia cada 100 m genera veinticinco tramos', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
        parciales: ConfiguracionParciales.distancia(100),
      );
      expect(estadisticas.parciales, hasLength(25));
      expect(estadisticas.parciales.every((p) => p.completo), isTrue);
      expect(estadisticas.parciales.first.distanciaMetros, closeTo(100, 1));
    });

    test('la altitud media usa los puntos del tramo', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio, altitud: 100),
        punto(
          latSevilla + 300 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 2)),
          altitud: 110,
        ),
        punto(
          latSevilla + 700 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
          altitud: 120,
        ),
        punto(
          latSevilla + 1200 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 9)),
          altitud: 130,
        ),
        punto(
          latSevilla + 1700 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 13)),
          altitud: 140,
        ),
        punto(
          latSevilla + 2200 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 17)),
          altitud: 150,
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 17),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 17)),
        parciales: ConfiguracionParciales.distancia(1000),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(estadisticas.parciales[0].altitudMedia, closeTo(110, 0.01));
      expect(estadisticas.parciales[1].altitudMedia, closeTo(135, 0.01));
      expect(estadisticas.parciales[2].altitudMedia, closeTo(150, 0.01));
    });

    test('por tiempo cada 5 min genera tres tramos', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(estadisticas.parciales.every((p) => p.completo), isTrue);
      expect(estadisticas.parciales[0].distanciaMetros, closeTo(1000, 5));
      expect(estadisticas.parciales[1].distanciaMetros, closeTo(750, 5));
      expect(estadisticas.parciales[2].distanciaMetros, closeTo(750, 5));
      expect(
        estadisticas.parciales.every(
          (p) => p.duracion == const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('el modo tiempo excluye la pausa', () {
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
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, hasLength(2));
      expect(estadisticas.parciales[0].distanciaMetros, closeTo(1000, 5));
      expect(estadisticas.parciales[1].distanciaMetros, closeTo(1000, 5));
      expect(
        estadisticas.parciales.every(
          (p) => p.duracion == const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('el tramo final de tiempo respeta los 10 s', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 6)),
        ),
        punto(
          latSevilla + 2000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 12)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 12),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 12)),
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(estadisticas.parciales[2].completo, isFalse);
      expect(estadisticas.parciales[2].duracion, const Duration(minutes: 2));
    });

    test('un resto de tiempo menor de 10 s no genera tramo final', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
        ),
        punto(
          latSevilla + 2000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 10, seconds: 5)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 10, seconds: 5),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 10, seconds: 5)),
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, hasLength(2));
      expect(estadisticas.parciales.every((p) => p.completo), isTrue);
    });

    test('menos de 10 segundos no genera parciales por tiempo', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 10 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(seconds: 5)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(seconds: 5),
        inicio: inicio,
        fin: inicio.add(const Duration(seconds: 5)),
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, isEmpty);
    });

    test('marca el más rápido y el más lento entre completos', () {
      final estadisticas = calcularEstadisticas(
        rutaDeTresKilometros(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(estadisticas.parciales[0].destacado, DestacadoParcial.masRapido);
      expect(estadisticas.parciales[1].destacado, DestacadoParcial.masLento);
      expect(estadisticas.parciales[2].destacado, DestacadoParcial.ninguno);
    });

    test('el tramo incompleto no compite por el más rápido', () {
      final puntos = [
        ...rutaDeTresKilometros(),
        punto(
          latSevilla + 3500 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 15, seconds: 30)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 15, seconds: 30),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15, seconds: 30)),
      );
      expect(estadisticas.parciales, hasLength(4));
      expect(estadisticas.parciales.last.completo, isFalse);
      expect(estadisticas.parciales.last.destacado, DestacadoParcial.ninguno);
      expect(estadisticas.parciales[0].destacado, DestacadoParcial.masRapido);
    });

    test('con menos de tres tramos completos no hay destacados', () {
      final estadisticas = calcularEstadisticas(
        rutaDeEjemplo(),
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(
        estadisticas.parciales.every(
          (p) => p.destacado == DestacadoParcial.ninguno,
        ),
        isTrue,
      );
    });

    test('un empate no marca a nadie', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(
          latSevilla + 1000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 5)),
        ),
        punto(
          latSevilla + 2000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 10)),
        ),
        punto(
          latSevilla + 3000 / metroPorGradoLatitud,
          lonSevilla,
          inicio.add(const Duration(minutes: 15)),
        ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(
        estadisticas.parciales.every(
          (p) => p.destacado == DestacadoParcial.ninguno,
        ),
        isTrue,
      );
    });

    test('sin movimiento no hay destacados', () {
      final puntos = [
        punto(latSevilla, lonSevilla, inicio),
        punto(latSevilla, lonSevilla, inicio.add(const Duration(minutes: 5))),
        punto(latSevilla, lonSevilla, inicio.add(const Duration(minutes: 10))),
        punto(latSevilla, lonSevilla, inicio.add(const Duration(minutes: 15))),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 15),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 15)),
        parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(estadisticas.parciales, hasLength(3));
      expect(
        estadisticas.parciales.every(
          (p) => p.destacado == DestacadoParcial.ninguno,
        ),
        isTrue,
      );
    });

    test('una ruta de 21 km con 100 m genera 210 tramos', () {
      final puntos = [
        for (var i = 0; i <= 210; i++)
          punto(
            latSevilla + i * 100 / metroPorGradoLatitud,
            lonSevilla,
            inicio.add(Duration(seconds: i * 30)),
          ),
      ];
      final estadisticas = calcularEstadisticas(
        puntos,
        duracionActiva: const Duration(minutes: 105),
        inicio: inicio,
        fin: inicio.add(const Duration(minutes: 105)),
        parciales: ConfiguracionParciales.distancia(100),
      );
      expect(estadisticas.parciales, hasLength(210));
    });

    test(
      'sin configuración usa 1 km y las otras opciones cambian la lista',
      () {
        final porDefecto = calcularEstadisticas(
          rutaDeEjemplo(),
          duracionActiva: const Duration(minutes: 15),
          inicio: inicio,
          fin: inicio.add(const Duration(minutes: 15)),
        );
        final quinientos = calcularEstadisticas(
          rutaDeEjemplo(),
          duracionActiva: const Duration(minutes: 15),
          inicio: inicio,
          fin: inicio.add(const Duration(minutes: 15)),
          parciales: ConfiguracionParciales.distancia(500),
        );
        final cincoMinutos = calcularEstadisticas(
          rutaDeEjemplo(),
          duracionActiva: const Duration(minutes: 15),
          inicio: inicio,
          fin: inicio.add(const Duration(minutes: 15)),
          parciales: ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
        );
        expect(porDefecto.parciales, hasLength(3));
        expect(quinientos.parciales, hasLength(5));
        expect(cincoMinutos.parciales, hasLength(3));
        expect(porDefecto.parciales[1].distanciaMetros, closeTo(1000, 5));
        expect(cincoMinutos.parciales[1].distanciaMetros, closeTo(750, 5));
      },
    );
  });
}
