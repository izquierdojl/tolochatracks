import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';

void main() {
  test('los perfiles tienen los parámetros cerrados', () {
    expect(PerfilGps.ahorro.intervalo, const Duration(seconds: 5));
    expect(PerfilGps.ahorro.distanciaMinima, 10);
    expect(PerfilGps.ahorro.precisionMaxima, 40);
    expect(PerfilGps.ahorro.calidad, CalidadGps.media);

    expect(PerfilGps.equilibrada.intervalo, const Duration(seconds: 2));
    expect(PerfilGps.equilibrada.distanciaMinima, 3);
    expect(PerfilGps.equilibrada.precisionMaxima, 30);
    expect(PerfilGps.equilibrada.calidad, CalidadGps.alta);

    expect(PerfilGps.maxima.intervalo, const Duration(seconds: 1));
    expect(PerfilGps.maxima.distanciaMinima, 1);
    expect(PerfilGps.maxima.precisionMaxima, 20);
    expect(PerfilGps.maxima.calidad, CalidadGps.alta);
  });

  test('desdeClave recupera el perfil y cae en Equilibrada', () {
    expect(PerfilGps.desdeClave('ahorro'), PerfilGps.ahorro);
    expect(PerfilGps.desdeClave('maxima'), PerfilGps.maxima);
    expect(PerfilGps.desdeClave('equilibrada'), PerfilGps.equilibrada);
    expect(PerfilGps.desdeClave('otro'), PerfilGps.equilibrada);
    expect(PerfilGps.desdeClave(null), PerfilGps.equilibrada);
  });

  test('las etiquetas y descripciones están en español', () {
    for (final perfil in PerfilGps.values) {
      expect(perfil.etiqueta, isNotEmpty);
      expect(perfil.descripcion, isNotEmpty);
    }
  });
}
