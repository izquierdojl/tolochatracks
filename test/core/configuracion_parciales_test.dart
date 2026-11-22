import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';

void main() {
  group('ConfiguracionParciales', () {
    test('el valor por defecto es cada 1 km', () {
      expect(ConfiguracionParciales.porDefecto.modo, ModoParciales.distancia);
      expect(ConfiguracionParciales.porDefecto.valor, 1000);
      expect(ConfiguracionParciales.porDefecto.descripcion, 'Cada 1 km');
    });

    test('las opciones de distancia son las acordadas', () {
      expect(ConfiguracionParciales.pasosDistanciaMetros, [
        100,
        200,
        500,
        1000,
        5000,
        10000,
      ]);
    });

    test('las opciones de tiempo son las acordadas', () {
      expect(ConfiguracionParciales.pasosTiempoSegundos, [
        60,
        300,
        600,
        900,
        1200,
        1800,
        2700,
        3600,
      ]);
    });

    test('igualdad y hashCode dependen de modo y valor', () {
      expect(
        ConfiguracionParciales.distancia(500),
        ConfiguracionParciales.distancia(500),
      );
      expect(
        ConfiguracionParciales.distancia(500).hashCode,
        ConfiguracionParciales.distancia(500).hashCode,
      );
      expect(
        ConfiguracionParciales.distancia(500),
        isNot(ConfiguracionParciales.distancia(1000)),
      );
      expect(
        ConfiguracionParciales.distancia(1000),
        isNot(ConfiguracionParciales.tiempo(const Duration(minutes: 5))),
      );
    });

    test('copyWith conserva el valor y usa el defecto al cambiar de modo', () {
      final distancia = ConfiguracionParciales.distancia(500);
      expect(distancia.copyWith().valor, 500);
      expect(
        distancia.copyWith(valor: 5000),
        ConfiguracionParciales.distancia(5000),
      );

      final tiempo = distancia.copyWith(modo: ModoParciales.tiempo);
      expect(tiempo.modo, ModoParciales.tiempo);
      expect(tiempo.valor, 300);

      final vuelta = tiempo.copyWith(modo: ModoParciales.distancia);
      expect(vuelta.modo, ModoParciales.distancia);
      expect(vuelta.valor, 1000);
    });

    test('rechaza pasos no admitidos', () {
      expect(() => ConfiguracionParciales.distancia(123), throwsArgumentError);
      expect(
        () => ConfiguracionParciales.tiempo(const Duration(minutes: 2)),
        throwsArgumentError,
      );
      expect(
        () => ConfiguracionParciales.tiempo(
          const Duration(seconds: 300, milliseconds: 500),
        ),
        throwsArgumentError,
      );
    });

    test('desdeClaves tolera valores inválidos y cadenas', () {
      expect(
        ConfiguracionParciales.desdeClaves('distancia', 500),
        ConfiguracionParciales.distancia(500),
      );
      expect(
        ConfiguracionParciales.desdeClaves('tiempo', 300),
        ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
      );
      expect(
        ConfiguracionParciales.desdeClaves('distancia', '500'),
        ConfiguracionParciales.distancia(500),
      );
      expect(
        ConfiguracionParciales.desdeClaves('tiempo', 1000),
        ConfiguracionParciales.porDefecto,
      );
      expect(
        ConfiguracionParciales.desdeClaves('desconocido', 500),
        ConfiguracionParciales.porDefecto,
      );
      expect(
        ConfiguracionParciales.desdeClaves(null, null),
        ConfiguracionParciales.porDefecto,
      );
    });

    test('las etiquetas son cortas y en español', () {
      expect(ConfiguracionParciales.distancia(100).etiquetaPaso, '100 m');
      expect(ConfiguracionParciales.distancia(1000).etiquetaPaso, '1 km');
      expect(ConfiguracionParciales.distancia(10000).etiquetaPaso, '10 km');
      expect(
        ConfiguracionParciales.tiempo(const Duration(minutes: 5)).etiquetaPaso,
        '5 min',
      );
      expect(
        ConfiguracionParciales.tiempo(const Duration(minutes: 45)).etiquetaPaso,
        '45 min',
      );
      expect(
        ConfiguracionParciales.tiempo(const Duration(hours: 1)).etiquetaPaso,
        '1 h',
      );
    });
  });
}
