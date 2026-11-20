import 'package:flutter/foundation.dart';

@immutable
class PuntoRuta {
  const PuntoRuta({
    required this.latitud,
    required this.longitud,
    required this.tiempo,
    this.altitud,
    this.precision,
    this.velocidad,
    this.rumbo,
  });

  final double latitud;
  final double longitud;
  final DateTime tiempo;
  final double? altitud;
  final double? precision;
  final double? velocidad;
  final double? rumbo;

  bool get tieneAltitud => altitud != null;

  Map<String, Object?> aJson() => {
    'lat': latitud,
    'lon': longitud,
    't': tiempo.toUtc().toIso8601String(),
    if (altitud != null) 'alt': altitud,
    if (precision != null) 'prec': precision,
    if (velocidad != null) 'vel': velocidad,
    if (rumbo != null) 'rumbo': rumbo,
  };

  factory PuntoRuta.desdeJson(Map<String, Object?> json) {
    final latitud = _numero(json['lat']);
    final longitud = _numero(json['lon']);
    final tiempo = _fecha(json['t']);
    if (latitud == null ||
        longitud == null ||
        tiempo == null ||
        latitud < -90 ||
        latitud > 90 ||
        longitud < -180 ||
        longitud > 180) {
      throw const FormatException('Punto de ruta inválido');
    }
    return PuntoRuta(
      latitud: latitud,
      longitud: longitud,
      tiempo: tiempo,
      altitud: _numero(json['alt']),
      precision: _numero(json['prec']),
      velocidad: _numero(json['vel']),
      rumbo: _numero(json['rumbo']),
    );
  }

  static double? _numero(Object? valor) {
    if (valor is num) {
      final numero = valor.toDouble();
      return numero.isFinite ? numero : null;
    }
    return double.tryParse(valor?.toString() ?? '');
  }

  static DateTime? _fecha(Object? valor) {
    if (valor is! String) return null;
    return DateTime.tryParse(valor)?.toLocal();
  }
}
