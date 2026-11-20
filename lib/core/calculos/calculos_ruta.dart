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

  final validos = _puntosValidos(puntos);
  final acumulados = _acumular(validos, inicioReal);
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
    parciales: _parciales(acumulados),
    porMinuto: _porMinuto(acumulados),
    serieDistancia: _muestrear(_serieDistancia(acumulados)),
    serieVelocidad: _muestrear(_serieVelocidad(acumulados)),
    serieAltitud: _muestrear(_serieAltitud(acumulados)),
  );
}

List<PuntoRuta> _puntosValidos(List<PuntoRuta> puntos) {
  final validos = <PuntoRuta>[];
  PuntoRuta? anterior;
  for (final punto in puntos) {
    if (punto.precision != null && punto.precision! > _precisionMaximaMetros) {
      continue;
    }
    if (anterior != null && !puntoAceptable(anterior, punto)) continue;
    validos.add(punto);
    anterior = punto;
  }
  return validos;
}

class _PuntoAcumulado {
  const _PuntoAcumulado({
    required this.punto,
    required this.distancia,
    required this.tiempo,
  });

  final PuntoRuta punto;
  final double distancia;
  final Duration tiempo;
}

List<_PuntoAcumulado> _acumular(List<PuntoRuta> puntos, DateTime? inicio) {
  if (puntos.isEmpty) return const [];
  final inicioReal = inicio ?? puntos.first.tiempo;
  var tiempo = puntos.first.tiempo.difference(inicioReal);
  if (tiempo.isNegative) tiempo = Duration.zero;
  final acumulados = <_PuntoAcumulado>[
    _PuntoAcumulado(punto: puntos.first, distancia: 0, tiempo: tiempo),
  ];
  var anterior = puntos.first;
  var distancia = 0.0;
  for (final punto in puntos.skip(1)) {
    final delta = punto.tiempo.difference(anterior.tiempo);
    if (!delta.isNegative) tiempo += delta;
    final segmento = distanciaHaversine(anterior, punto);
    final esJitter =
        segmento < _distanciaMinimaSegmentoMetros &&
        delta.inMilliseconds < _segundosMinimosJitter * 1000;
    if (!esJitter) distancia += segmento;
    acumulados.add(
      _PuntoAcumulado(punto: punto, distancia: distancia, tiempo: tiempo),
    );
    anterior = punto;
  }
  return acumulados;
}

List<MuestraRuta> _serieDistancia(List<_PuntoAcumulado> acumulados) {
  if (acumulados.length < 2) return const [];
  final serie = <MuestraRuta>[const MuestraRuta(0, 0)];
  for (final acumulado in acumulados) {
    final minutos = acumulado.tiempo.inMilliseconds / 60000;
    serie.add(MuestraRuta(minutos, acumulado.distancia / 1000));
  }
  return serie;
}

List<MuestraRuta> _serieVelocidad(List<_PuntoAcumulado> acumulados) {
  final serie = <MuestraRuta>[];
  double? suavizada;
  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    final distancia = actual.distancia - anterior.distancia;
    final segundos = (actual.tiempo - anterior.tiempo).inMilliseconds / 1000.0;
    if (distancia <= 0 || segundos <= 0) continue;
    final velocidad = distancia / segundos * 3.6;
    suavizada = suavizada == null
        ? velocidad
        : suavizada + (velocidad - suavizada) * 0.35;
    serie.add(MuestraRuta(actual.distancia / 1000, suavizada));
  }
  return serie;
}

List<MuestraRuta> _serieAltitud(List<_PuntoAcumulado> acumulados) {
  if (acumulados.length < 2) return const [];
  final serie = <MuestraRuta>[];
  double? suavizada;
  for (final acumulado in acumulados) {
    final altitud = acumulado.punto.altitud;
    if (altitud == null) continue;
    suavizada = suavizada == null
        ? altitud
        : suavizada + (altitud - suavizada) * 0.25;
    serie.add(MuestraRuta(acumulado.distancia / 1000, suavizada));
  }
  return serie;
}

List<ParcialKm> _parciales(List<_PuntoAcumulado> acumulados) {
  if (acumulados.length < 2) return const [];
  final distanciaTotal = acumulados.last.distancia;
  if (distanciaTotal < 20) return const [];

  final parciales = <ParcialKm>[];
  var numero = 1;
  var inicioDistancia = 0.0;
  var inicioTiempo = Duration.zero;

  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    if (actual.distancia <= anterior.distancia) continue;
    while (actual.distancia >= numero * 1000) {
      final limite = numero * 1000.0;
      final fraccion =
          ((limite - anterior.distancia) /
                  (actual.distancia - anterior.distancia))
              .clamp(0.0, 1.0);
      final milisegundos =
          anterior.tiempo.inMilliseconds +
          (actual.tiempo.inMilliseconds - anterior.tiempo.inMilliseconds) *
              fraccion;
      final tiempo = Duration(milliseconds: milisegundos.round());
      final duracion = tiempo - inicioTiempo;
      final distancia = limite - inicioDistancia;
      parciales.add(
        ParcialKm(
          numero: numero,
          distanciaMetros: distancia,
          duracion: duracion,
          velocidadMedia: duracion.inMilliseconds > 0
              ? distancia / (duracion.inMilliseconds / 1000)
              : 0,
        ),
      );
      numero += 1;
      inicioDistancia = limite;
      inicioTiempo = tiempo;
    }
  }

  final restante = distanciaTotal - inicioDistancia;
  if (restante > 20) {
    final duracion = acumulados.last.tiempo - inicioTiempo;
    parciales.add(
      ParcialKm(
        numero: numero,
        distanciaMetros: restante,
        duracion: duracion.isNegative ? Duration.zero : duracion,
        velocidadMedia: duracion.inMilliseconds > 0
            ? restante / (duracion.inMilliseconds / 1000)
            : 0,
      ),
    );
  }
  return parciales;
}

List<DistanciaMinuto> _porMinuto(List<_PuntoAcumulado> acumulados) {
  final metros = <int, double>{};
  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    final distancia = actual.distancia - anterior.distancia;
    final inicioSegundos = anterior.tiempo.inMilliseconds / 1000;
    final finSegundos = actual.tiempo.inMilliseconds / 1000;
    if (distancia <= 0 || finSegundos <= inicioSegundos) continue;
    final minutoInicio = (inicioSegundos / 60).floor();
    final minutoFin = (finSegundos / 60).floor();
    final duracionSegmento = finSegundos - inicioSegundos;
    for (var minuto = minutoInicio; minuto <= minutoFin; minuto++) {
      final solapeInicio = max(inicioSegundos, minuto * 60.0);
      final solapeFin = min(finSegundos, (minuto + 1) * 60.0);
      final solape = solapeFin - solapeInicio;
      if (solape <= 0) continue;
      metros[minuto] =
          (metros[minuto] ?? 0) + distancia * (solape / duracionSegmento);
    }
  }
  if (metros.isEmpty) return const [];
  final ultimo = metros.keys.reduce(max);
  return [
    for (var minuto = 0; minuto <= ultimo; minuto++)
      DistanciaMinuto(minuto: minuto, metros: metros[minuto] ?? 0),
  ];
}

const _maximoMuestras = 240;

List<MuestraRuta> _muestrear(List<MuestraRuta> muestras) {
  if (muestras.length <= _maximoMuestras) return muestras;
  final paso = (muestras.length - 1) / (_maximoMuestras - 1);
  return [
    for (var i = 0; i < _maximoMuestras; i++)
      muestras[(i * paso).round().clamp(0, muestras.length - 1)],
  ];
}
