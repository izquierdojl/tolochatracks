import 'dart:math';

import '../models/estadisticas_ruta.dart';
import '../models/punto_ruta.dart';

const _radioTierraMetros = 6371000.0;
const _precisionMaximaMetros = 100.0;
const _velocidadMaximaPlausible = 55.0;
const _distanciaMinimaSegmentoMetros = 1.5;
const _segundosMinimosJitter = 10.0;
const _umbralDesnivelMetros = 2.0;

double distanciaHaversine(PuntoRuta a, PuntoRuta b) {
  final lat1 = a.latitud * pi / 180;
  final lat2 = b.latitud * pi / 180;
  final deltaLat = (b.latitud - a.latitud) * pi / 180;
  final deltaLon = (b.longitud - a.longitud) * pi / 180;
  final h =
      pow(sin(deltaLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(deltaLon / 2), 2);
  return 2 * _radioTierraMetros * asin(sqrt(h.clamp(0.0, 1.0)));
}

bool puntoAceptable(PuntoRuta? anterior, PuntoRuta punto) {
  if (punto.precision != null && punto.precision! > _precisionMaximaMetros) {
    return false;
  }
  if (anterior == null) return true;
  final segundos =
      punto.tiempo.difference(anterior.tiempo).inMilliseconds / 1000.0;
  if (segundos <= 0) return false;
  final distancia = distanciaHaversine(anterior, punto);
  return distancia / segundos <= _velocidadMaximaPlausible;
}

class AcumuladorRuta {
  double distanciaMetros = 0;
  double desnivelPositivo = 0;
  double desnivelNegativo = 0;
  double velocidadMaxima = 0;
  double? altitudMinima;
  double? altitudMaxima;
  int _puntosValidos = 0;

  PuntoRuta? _ultimo;
  double? _altitudSuavizada;
  double? _altitudReferencia;

  int get puntosValidos => _puntosValidos;

  void reiniciar() {
    distanciaMetros = 0;
    desnivelPositivo = 0;
    desnivelNegativo = 0;
    velocidadMaxima = 0;
    altitudMinima = null;
    altitudMaxima = null;
    _puntosValidos = 0;
    _ultimo = null;
    _altitudSuavizada = null;
    _altitudReferencia = null;
  }

  void agregar(PuntoRuta punto) {
    if (punto.precision != null && punto.precision! > _precisionMaximaMetros) {
      return;
    }
    if (_ultimo != null && !puntoAceptable(_ultimo, punto)) {
      return;
    }

    _puntosValidos += 1;
    final altitud = punto.altitud;
    if (altitud != null) {
      altitudMinima = altitudMinima == null
          ? altitud
          : min(altitudMinima!, altitud);
      altitudMaxima = altitudMaxima == null
          ? altitud
          : max(altitudMaxima!, altitud);
      _procesarAltitud(altitud);
    }

    final anterior = _ultimo;
    if (anterior != null) {
      final segundos =
          punto.tiempo.difference(anterior.tiempo).inMilliseconds / 1000.0;
      final distancia = distanciaHaversine(anterior, punto);
      final esJitter =
          distancia < _distanciaMinimaSegmentoMetros &&
          segundos < _segundosMinimosJitter;
      if (!esJitter && segundos > 0) {
        distanciaMetros += distancia;
        velocidadMaxima = max(velocidadMaxima, distancia / segundos);
      }
    }
    _ultimo = punto;
  }

  void _procesarAltitud(double altitud) {
    final suavizada = _altitudSuavizada == null
        ? altitud
        : _altitudSuavizada! + (altitud - _altitudSuavizada!) * 0.25;
    _altitudSuavizada = suavizada;
    if (_altitudReferencia == null) {
      _altitudReferencia = suavizada;
      return;
    }
    final diferencia = suavizada - _altitudReferencia!;
    if (diferencia >= _umbralDesnivelMetros) {
      desnivelPositivo += diferencia;
      _altitudReferencia = suavizada;
    } else if (diferencia <= -_umbralDesnivelMetros) {
      desnivelNegativo += -diferencia;
      _altitudReferencia = suavizada;
    }
  }
}

EstadisticasRuta calcularEstadisticas(
  List<PuntoRuta> puntos, {
  required Duration duracionActiva,
  DateTime? inicio,
  DateTime? fin,
}) {
  final acumulador = AcumuladorRuta();
  for (final punto in puntos) {
    acumulador.agregar(punto);
  }
  final inicioReal = inicio ?? (puntos.isEmpty ? null : puntos.first.tiempo);
  var duracionTotal = Duration.zero;
  if (fin != null && inicioReal != null) {
    duracionTotal = fin.difference(inicioReal);
  } else if (puntos.length >= 2) {
    duracionTotal = puntos.last.tiempo.difference(puntos.first.tiempo);
  }
  if (duracionTotal.isNegative) duracionTotal = Duration.zero;
  final segundos = duracionActiva.inMilliseconds / 1000.0;
  final velocidadMedia = segundos > 0
      ? acumulador.distanciaMetros / segundos
      : 0.0;
  return EstadisticasRuta(
    distanciaMetros: acumulador.distanciaMetros,
    duracionActiva: duracionActiva,
    duracionTotal: duracionTotal,
    velocidadMedia: velocidadMedia,
    velocidadMaxima: acumulador.velocidadMaxima,
    desnivelPositivo: acumulador.desnivelPositivo,
    desnivelNegativo: acumulador.desnivelNegativo,
    puntos: acumulador.puntosValidos,
    altitudMinima: acumulador.altitudMinima,
    altitudMaxima: acumulador.altitudMaxima,
  );
}
