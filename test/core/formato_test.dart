import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/configuracion_parciales.dart';
import 'package:tolochatracks/core/utilidades/formato.dart';

void main() {
  group('formatos cortos', () {
    test('ritmo sin unidad y con unidad', () {
      final velocidad = 1000 / 683;
      expect(formatearRitmoCorto(velocidad), '11:23');
      expect(formatearRitmo(velocidad), '11:23 /km');
      expect(formatearRitmoCorto(null), '—');
      expect(formatearRitmo(0.01), '—');
    });

    test('velocidad sin unidad y con unidad', () {
      expect(formatearVelocidadCorto(1000 / 300), '12,0');
      expect(formatearVelocidad(1000 / 300), '12,0 km/h');
      expect(formatearVelocidadCorto(null), '—');
    });

    test('metros cortos y con unidad', () {
      expect(formatearMetrosCorto(124.4), '124');
      expect(formatearMetrosCorto(null), '—');
      expect(formatearMetros(124.4), '124 m');
    });
  });

  group('etiquetaTramoParcial', () {
    test('distancias habituales', () {
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(1000), 1),
        'Km 1',
      );
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(500), 1),
        '500 m',
      );
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(500), 2),
        'Km 1,0',
      );
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(100), 9),
        '900 m',
      );
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(100), 10),
        'Km 1,0',
      );
      expect(
        etiquetaTramoParcial(ConfiguracionParciales.distancia(5000), 2),
        'Km 10',
      );
    });

    test('tiempos habituales', () {
      expect(
        etiquetaTramoParcial(
          ConfiguracionParciales.tiempo(const Duration(minutes: 5)),
          3,
        ),
        '15 min',
      );
      expect(
        etiquetaTramoParcial(
          ConfiguracionParciales.tiempo(const Duration(minutes: 45)),
          2,
        ),
        '1 h 30',
      );
      expect(
        etiquetaTramoParcial(
          ConfiguracionParciales.tiempo(const Duration(minutes: 60)),
          1,
        ),
        '1 h',
      );
    });

    test('el último tramo se llama Final', () {
      expect(
        etiquetaTramoParcial(
          ConfiguracionParciales.distancia(1000),
          3,
          completo: false,
        ),
        'Final',
      );
    });
  });
}
