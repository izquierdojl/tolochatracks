import 'package:flutter/foundation.dart';

@immutable
class MuestraRuta {
  const MuestraRuta(this.x, this.y);

  final double x;
  final double y;
}

enum DestacadoParcial { ninguno, masRapido, masLento }

@immutable
class ParcialRuta {
  const ParcialRuta({
    required this.numero,
    required this.distanciaMetros,
    required this.duracion,
    required this.velocidadMedia,
    this.altitudMedia,
    this.completo = false,
    this.destacado = DestacadoParcial.ninguno,
  });

  final int numero;
  final double distanciaMetros;
  final Duration duracion;
  final double velocidadMedia;
  final double? altitudMedia;
  final bool completo;
  final DestacadoParcial destacado;

  ParcialRuta copyWith({DestacadoParcial? destacado}) => ParcialRuta(
    numero: numero,
    distanciaMetros: distanciaMetros,
    duracion: duracion,
    velocidadMedia: velocidadMedia,
    altitudMedia: altitudMedia,
    completo: completo,
    destacado: destacado ?? this.destacado,
  );
}

@immutable
class DistanciaMinuto {
  const DistanciaMinuto({required this.minuto, required this.metros});

  final int minuto;
  final double metros;
}

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
    this.parciales = const [],
    this.porMinuto = const [],
    this.serieDistancia = const [],
    this.serieVelocidad = const [],
    this.serieVelocidadTiempo = const [],
    this.serieAltitud = const [],
    this.serieAltitudTiempo = const [],
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
  final List<ParcialRuta> parciales;
  final List<DistanciaMinuto> porMinuto;
  final List<MuestraRuta> serieDistancia;
  final List<MuestraRuta> serieVelocidad;
  final List<MuestraRuta> serieVelocidadTiempo;
  final List<MuestraRuta> serieAltitud;
  final List<MuestraRuta> serieAltitudTiempo;

  bool get tieneAltitud => altitudMinima != null && altitudMaxima != null;

  bool get tieneVelocidad => velocidadMaxima > 0;

  bool get tieneSeries =>
      serieDistancia.length >= 2 ||
      serieVelocidad.isNotEmpty ||
      serieVelocidadTiempo.isNotEmpty;

  Duration? get ritmoMedio {
    if (distanciaMetros < 5 || duracionActiva.inMilliseconds <= 0) return null;
    final segundosPorKm =
        duracionActiva.inMilliseconds / 1000 / (distanciaMetros / 1000);
    if (segundosPorKm <= 0 || segundosPorKm > 359999) return null;
    return Duration(milliseconds: (segundosPorKm * 1000).round());
  }
}
