import 'package:flutter/foundation.dart';

@immutable
class EstadisticasRuta {
  const EstadisticasRuta({
    required this.distanciaMetros,
    required this.duracionActiva,
    required this.duracionTotal,
    required this.velocidadMedia,
    required this.velocidadMaxima,
    required this.desnivelPositivo,
    required this.desnivelNegativo,
    required this.puntos,
    this.altitudMinima,
    this.altitudMaxima,
  });

  final double distanciaMetros;
  final Duration duracionActiva;
  final Duration duracionTotal;
  final double velocidadMedia;
  final double velocidadMaxima;
  final double desnivelPositivo;
  final double desnivelNegativo;
  final int puntos;
  final double? altitudMinima;
  final double? altitudMaxima;

  bool get tieneAltitud => altitudMinima != null && altitudMaxima != null;

  bool get tieneVelocidad => velocidadMaxima > 0;

  Duration? get ritmoMedio {
    if (distanciaMetros < 5 || duracionActiva.inMilliseconds <= 0) return null;
    final segundosPorKm =
        duracionActiva.inMilliseconds / 1000 / (distanciaMetros / 1000);
    if (segundosPorKm <= 0 || segundosPorKm > 359999) return null;
    return Duration(milliseconds: (segundosPorKm * 1000).round());
  }
}
