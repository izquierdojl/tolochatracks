import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';
import 'package:tolochatracks/core/servicios/ubicacion.dart';

Position posicionDePrueba({required bool hasSpeed, double speed = 0}) {
  final ahora = DateTime(2026, 11, 21, 12);
  return Position(
    longitude: -0.2355,
    latitude: 40.9408,
    timestamp: ahora,
    accuracy: 8,
    altitude: 450,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0.2,
    hasSpeed: hasSpeed,
    hasSpeedAccuracy: true,
  );
}

void main() {
  test('con hasSpeed usa la velocidad reportada, incluido el cero', () {
    final punto = convertirPosicion(
      posicionDePrueba(hasSpeed: true, speed: 0),
      ahora: () => DateTime(2026, 11, 21, 12),
    );
    expect(punto.velocidad, 0);
  });

  test('sin hasSpeed deja la velocidad en null', () {
    final punto = convertirPosicion(
      posicionDePrueba(hasSpeed: false),
      ahora: () => DateTime(2026, 11, 21, 12),
    );
    expect(punto.velocidad, isNull);
  });

  test('con hasSpeed conserva una velocidad distinta de cero', () {
    final punto = convertirPosicion(
      posicionDePrueba(hasSpeed: true, speed: 3.2),
      ahora: () => DateTime(2026, 11, 21, 12),
    );
    expect(punto.velocidad, closeTo(3.2, 0.001));
  });

  test('los perfiles se traducen a AndroidSettings', () {
    final ahorro = ajustesAndroidPara(PerfilGps.ahorro);
    expect(ahorro.accuracy, LocationAccuracy.medium);
    expect(ahorro.distanceFilter, 10);
    expect(ahorro.intervalDuration, const Duration(seconds: 5));
    expect(ahorro.forceLocationManager, isTrue);
    expect(ahorro.useMSLAltitude, isTrue);

    final equilibrada = ajustesAndroidPara(PerfilGps.equilibrada);
    expect(equilibrada.accuracy, LocationAccuracy.high);
    expect(equilibrada.distanceFilter, 3);
    expect(equilibrada.intervalDuration, const Duration(seconds: 2));

    final maxima = ajustesAndroidPara(PerfilGps.maxima);
    expect(maxima.accuracy, LocationAccuracy.high);
    expect(maxima.distanceFilter, 1);
    expect(maxima.intervalDuration, const Duration(seconds: 1));
  });
}
