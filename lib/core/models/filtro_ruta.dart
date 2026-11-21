import 'package:flutter/foundation.dart';

import 'actividad.dart';
import 'perfil_gps.dart';

@immutable
class FiltroRuta {
  const FiltroRuta({
    this.precisionMaxima = 40,
    this.velocidadMaxima = 120 / 3.6,
    this.calentamiento = const Duration(seconds: 5),
    this.ventana = const Duration(seconds: 10),
  });

  final double precisionMaxima;
  final double velocidadMaxima;
  final Duration calentamiento;
  final Duration ventana;

  factory FiltroRuta.dePerfil(
    PerfilGps perfil,
    Actividad actividad, {
    Duration calentamiento = const Duration(seconds: 5),
  }) => FiltroRuta(
    precisionMaxima: perfil.precisionMaxima,
    velocidadMaxima: actividad.velocidadMaximaPlausible,
    calentamiento: calentamiento,
  );

  factory FiltroRuta.vistaSesion(Actividad actividad) => FiltroRuta(
    precisionMaxima: 40,
    velocidadMaxima: actividad.velocidadMaximaPlausible,
  );
}
