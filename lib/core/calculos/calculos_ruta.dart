import 'dart:math';

import '../models/actividad.dart';
import '../models/configuracion_parciales.dart';
import '../models/estadisticas_ruta.dart';
import '../models/filtro_ruta.dart';
import '../models/punto_ruta.dart';

const _radioTierraMetros = 6371000.0;
const _distanciaMinimaSegmentoMetros = 1.5;
const _segundosMinimosJitter = 10.0;
const _umbralDesnivelMetros = 2.0;
const _epsilonCorteMetros = 0.1;

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

bool puntoAceptable(
  PuntoRuta? anterior,
  PuntoRuta punto, {
  FiltroRuta filtro = const FiltroRuta(),
}) {
  if (punto.precision != null && punto.precision! > filtro.precisionMaxima) {
    return false;
  }
  if (anterior == null) return true;
  final segundos =
      punto.tiempo.difference(anterior.tiempo).inMilliseconds / 1000.0;
  if (segundos <= 0) return false;
  final distancia = distanciaHaversine(anterior, punto);
  return distancia / segundos <= filtro.velocidadMaxima;
}

class _PuntoVentana {
  const _PuntoVentana(this.tiempo, this.distancia);

  final DateTime tiempo;
  final double distancia;
}

class AcumuladorRuta {
  AcumuladorRuta({this.filtro = const FiltroRuta()});

  FiltroRuta filtro;
  double distanciaMetros = 0;
  double desnivelPositivo = 0;
  double desnivelNegativo = 0;
  double velocidadMaxima = 0;
  double? altitudMinima;
  double? altitudMaxima;
  int _puntosValidos = 0;

  PuntoRuta? _ultimo;
  DateTime? _inicioSegmento;
  final List<_PuntoVentana> _ventana = [];
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
    _inicioSegmento = null;
    _ventana.clear();
    _altitudSuavizada = null;
    _altitudReferencia = null;
  }

  void agregar(PuntoRuta punto) {
    if (punto.precision != null && punto.precision! > filtro.precisionMaxima) {
      return;
    }
    if (_ultimo != null && punto.segmento != _ultimo!.segmento) {
      _ultimo = null;
    }
    if (_ultimo != null && !puntoAceptable(_ultimo, punto, filtro: filtro)) {
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
    if (anterior == null) {
      _inicioSegmento = punto.tiempo;
      _ventana
        ..clear()
        ..add(_PuntoVentana(punto.tiempo, distanciaMetros));
    } else {
      final segundos =
          punto.tiempo.difference(anterior.tiempo).inMilliseconds / 1000.0;
      final distancia = distanciaHaversine(anterior, punto);
      final esJitter =
          distancia < _distanciaMinimaSegmentoMetros &&
          segundos < _segundosMinimosJitter;
      final valido = !esJitter && segundos > 0;
      if (valido) distanciaMetros += distancia;
      _ventana.add(_PuntoVentana(punto.tiempo, distanciaMetros));
      while (_ventana.length > 1 &&
          punto.tiempo.difference(_ventana[1].tiempo) >= filtro.ventana) {
        _ventana.removeAt(0);
      }
      final inicio = _inicioSegmento;
      final enCalentamiento =
          inicio != null &&
          filtro.calentamiento > Duration.zero &&
          punto.tiempo.difference(inicio) < filtro.calentamiento;
      if (valido && !enCalentamiento) {
        final reportada = punto.velocidad;
        final derivada = distancia / segundos;
        final double velocidad;
        if (reportada != null) {
          velocidad = min(reportada, derivada);
        } else {
          final primera = _ventana.first;
          final ventanaSegundos =
              punto.tiempo.difference(primera.tiempo).inMilliseconds / 1000.0;
          final minimo = filtro.ventana.inMilliseconds / 1000.0 * 0.8;
          velocidad = ventanaSegundos >= minimo
              ? (distanciaMetros - primera.distancia) / ventanaSegundos
              : derivada;
        }
        velocidadMaxima = max(velocidadMaxima, velocidad);
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
  Actividad actividad = Actividad.otras,
  ConfiguracionParciales parciales = ConfiguracionParciales.porDefecto,
}) {
  final filtro = FiltroRuta.vistaSesion(actividad);
  final acumulador = AcumuladorRuta(filtro: filtro);
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

  final validos = _puntosValidos(puntos, filtro);
  final acumulados = _acumular(validos, inicioReal);
  final segundos = duracionActiva.inMilliseconds / 1000.0;
  final velocidadMedia = segundos > 0
      ? acumulador.distanciaMetros / segundos
      : 0.0;
  final velocidad = _serieVelocidad(acumulados, filtro);
  final altitud = _serieAltitud(acumulados);

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
    parciales: _parciales(acumulados, parciales),
    porMinuto: _porMinuto(acumulados),
    serieDistancia: _muestrear(_serieDistancia(acumulados)),
    serieVelocidad: _muestrear(velocidad.porDistancia),
    serieVelocidadTiempo: _muestrear(velocidad.porTiempo),
    serieAltitud: _muestrear(altitud.porDistancia),
    serieAltitudTiempo: _muestrear(altitud.porTiempo),
  );
}

List<PuntoRuta> puntosValidosDeSesion(
  List<PuntoRuta> puntos, {
  Actividad actividad = Actividad.otras,
  double precisionMaxima = 40,
}) => _puntosValidos(
  puntos,
  FiltroRuta(
    precisionMaxima: precisionMaxima,
    velocidadMaxima: actividad.velocidadMaximaPlausible,
  ),
);

List<PuntoRuta> _puntosValidos(List<PuntoRuta> puntos, FiltroRuta filtro) {
  final validos = <PuntoRuta>[];
  PuntoRuta? anterior;
  for (final punto in puntos) {
    if (anterior != null && punto.segmento != anterior.segmento) {
      anterior = null;
    }
    if (punto.precision != null && punto.precision! > filtro.precisionMaxima) {
      continue;
    }
    if (anterior != null && !puntoAceptable(anterior, punto, filtro: filtro)) {
      continue;
    }
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
    final cambiaSegmento = punto.segmento != anterior.segmento;
    if (!cambiaSegmento && !delta.isNegative) tiempo += delta;
    final segmento = cambiaSegmento ? 0.0 : distanciaHaversine(anterior, punto);
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

({List<MuestraRuta> porDistancia, List<MuestraRuta> porTiempo}) _serieVelocidad(
  List<_PuntoAcumulado> acumulados,
  FiltroRuta filtro,
) {
  if (acumulados.length < 2) {
    return (porDistancia: const [], porTiempo: const []);
  }
  final porDistancia = <MuestraRuta>[];
  final porTiempo = <MuestraRuta>[];
  double? suavizada;
  var inicioSegmento = acumulados.first.tiempo;
  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    if (actual.punto.segmento != anterior.punto.segmento) {
      inicioSegmento = actual.tiempo;
    }
    final distancia = actual.distancia - anterior.distancia;
    final segundos = (actual.tiempo - anterior.tiempo).inMilliseconds / 1000.0;
    if (distancia <= 0 || segundos <= 0) continue;
    if (filtro.calentamiento > Duration.zero &&
        actual.tiempo - inicioSegmento < filtro.calentamiento) {
      continue;
    }
    final reportada = actual.punto.velocidad;
    final double velocidad;
    if (reportada != null) {
      final derivada = distancia / segundos;
      velocidad = min(reportada, derivada);
    } else {
      var j = i;
      while (j > 0 &&
          actual.tiempo - acumulados[j - 1].tiempo <= filtro.ventana &&
          acumulados[j - 1].punto.segmento == actual.punto.segmento) {
        j--;
      }
      final inicio = acumulados[j];
      final ventanaSegundos =
          (actual.tiempo - inicio.tiempo).inMilliseconds / 1000.0;
      final minimo = filtro.ventana.inMilliseconds / 1000.0 * 0.8;
      velocidad = ventanaSegundos >= minimo
          ? (actual.distancia - inicio.distancia) / ventanaSegundos
          : distancia / segundos;
    }
    final kmh = velocidad * 3.6;
    suavizada = suavizada == null ? kmh : suavizada + (kmh - suavizada) * 0.35;
    porDistancia.add(MuestraRuta(actual.distancia / 1000, suavizada));
    porTiempo.add(MuestraRuta(actual.tiempo.inMilliseconds / 60000, suavizada));
  }
  return (porDistancia: porDistancia, porTiempo: porTiempo);
}

({List<MuestraRuta> porDistancia, List<MuestraRuta> porTiempo}) _serieAltitud(
  List<_PuntoAcumulado> acumulados,
) {
  if (acumulados.length < 2) {
    return (porDistancia: const [], porTiempo: const []);
  }
  final porDistancia = <MuestraRuta>[];
  final porTiempo = <MuestraRuta>[];
  double? suavizada;
  for (final acumulado in acumulados) {
    final altitud = acumulado.punto.altitud;
    if (altitud == null) continue;
    suavizada = suavizada == null
        ? altitud
        : suavizada + (altitud - suavizada) * 0.25;
    porDistancia.add(MuestraRuta(acumulado.distancia / 1000, suavizada));
    porTiempo.add(
      MuestraRuta(acumulado.tiempo.inMilliseconds / 60000, suavizada),
    );
  }
  return (porDistancia: porDistancia, porTiempo: porTiempo);
}

class _Tramo {
  const _Tramo({
    required this.numero,
    required this.inicioDistancia,
    required this.finDistancia,
    required this.inicioTiempo,
    required this.finTiempo,
    required this.completo,
  });

  final int numero;
  final double inicioDistancia;
  final double finDistancia;
  final Duration inicioTiempo;
  final Duration finTiempo;
  final bool completo;
}

List<ParcialRuta> _parciales(
  List<_PuntoAcumulado> acumulados,
  ConfiguracionParciales configuracion,
) {
  if (acumulados.length < 2) return const [];
  final distanciaTotal = acumulados.last.distancia;
  final tiempoTotal = acumulados.last.tiempo;
  if (configuracion.esDistancia) {
    if (distanciaTotal < 20) return const [];
  } else if (tiempoTotal < const Duration(seconds: 10)) {
    return const [];
  }

  final tramos = configuracion.esDistancia
      ? _tramosPorDistancia(acumulados, configuracion.pasoMetros)
      : _tramosPorTiempo(acumulados, configuracion.valor);
  if (tramos.isEmpty) return const [];

  final sumas = List<double>.filled(tramos.length, 0);
  final cuentas = List<int>.filled(tramos.length, 0);
  var indiceTramo = 0;
  for (final acumulado in acumulados) {
    final valor = configuracion.esDistancia
        ? acumulado.distancia
        : acumulado.tiempo.inMilliseconds / 1000.0;
    while (indiceTramo < tramos.length - 1) {
      final fin = configuracion.esDistancia
          ? tramos[indiceTramo].finDistancia
          : tramos[indiceTramo].finTiempo.inMilliseconds / 1000.0;
      if (valor < fin) break;
      indiceTramo += 1;
    }
    final altitud = acumulado.punto.altitud;
    if (altitud != null) {
      sumas[indiceTramo] += altitud;
      cuentas[indiceTramo] += 1;
    }
  }

  final parciales = <ParcialRuta>[];
  for (var i = 0; i < tramos.length; i++) {
    final tramo = tramos[i];
    final distancia = tramo.finDistancia - tramo.inicioDistancia;
    final duracion = tramo.finTiempo - tramo.inicioTiempo;
    final segundos = duracion.inMilliseconds / 1000;
    parciales.add(
      ParcialRuta(
        numero: tramo.numero,
        distanciaMetros: distancia < 0 ? 0 : distancia,
        duracion: duracion.isNegative ? Duration.zero : duracion,
        velocidadMedia: segundos > 0 && distancia > 0
            ? distancia / segundos
            : 0,
        altitudMedia: cuentas[i] > 0 ? sumas[i] / cuentas[i] : null,
        completo: tramo.completo,
      ),
    );
  }
  return _conDestacados(parciales);
}

List<_Tramo> _tramosPorDistancia(
  List<_PuntoAcumulado> acumulados,
  double paso,
) {
  final tramos = <_Tramo>[];
  var numero = 1;
  var inicioDistancia = 0.0;
  var inicioTiempo = Duration.zero;

  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    if (actual.distancia <= anterior.distancia) continue;
    while (actual.distancia >= numero * paso - _epsilonCorteMetros) {
      final limite = numero * paso;
      final fraccion =
          ((limite - anterior.distancia) /
                  (actual.distancia - anterior.distancia))
              .clamp(0.0, 1.0);
      final tiempo = _interpolarTiempo(
        anterior.tiempo,
        actual.tiempo,
        fraccion,
      );
      tramos.add(
        _Tramo(
          numero: numero,
          inicioDistancia: inicioDistancia,
          finDistancia: limite,
          inicioTiempo: inicioTiempo,
          finTiempo: tiempo,
          completo: true,
        ),
      );
      numero += 1;
      inicioDistancia = limite;
      inicioTiempo = tiempo;
    }
  }

  final restante = acumulados.last.distancia - inicioDistancia;
  if (restante > 20) {
    tramos.add(
      _Tramo(
        numero: numero,
        inicioDistancia: inicioDistancia,
        finDistancia: acumulados.last.distancia,
        inicioTiempo: inicioTiempo,
        finTiempo: acumulados.last.tiempo,
        completo: false,
      ),
    );
  }
  return tramos;
}

List<_Tramo> _tramosPorTiempo(
  List<_PuntoAcumulado> acumulados,
  int pasoSegundos,
) {
  final tramos = <_Tramo>[];
  var numero = 1;
  var inicioDistancia = 0.0;
  var inicioTiempo = Duration.zero;

  for (var i = 1; i < acumulados.length; i++) {
    final anterior = acumulados[i - 1];
    final actual = acumulados[i];
    final delta = actual.tiempo - anterior.tiempo;
    if (delta <= Duration.zero) continue;
    while (actual.tiempo.inMilliseconds >= numero * pasoSegundos * 1000) {
      final limite = Duration(seconds: numero * pasoSegundos);
      final fraccion =
          ((limite.inMilliseconds - anterior.tiempo.inMilliseconds) /
                  delta.inMilliseconds)
              .clamp(0.0, 1.0);
      final distancia =
          anterior.distancia +
          (actual.distancia - anterior.distancia) * fraccion;
      tramos.add(
        _Tramo(
          numero: numero,
          inicioDistancia: inicioDistancia,
          finDistancia: distancia,
          inicioTiempo: inicioTiempo,
          finTiempo: limite,
          completo: true,
        ),
      );
      numero += 1;
      inicioDistancia = distancia;
      inicioTiempo = limite;
    }
  }

  final restante = acumulados.last.tiempo - inicioTiempo;
  if (restante >= const Duration(seconds: 10)) {
    tramos.add(
      _Tramo(
        numero: numero,
        inicioDistancia: inicioDistancia,
        finDistancia: acumulados.last.distancia,
        inicioTiempo: inicioTiempo,
        finTiempo: acumulados.last.tiempo,
        completo: false,
      ),
    );
  }
  return tramos;
}

Duration _interpolarTiempo(Duration inicio, Duration fin, double fraccion) {
  final milisegundos =
      inicio.inMilliseconds +
      (fin.inMilliseconds - inicio.inMilliseconds) * fraccion;
  return Duration(milliseconds: milisegundos.round());
}

List<ParcialRuta> _conDestacados(List<ParcialRuta> parciales) {
  final completos = parciales.where((p) => p.completo).toList();
  if (completos.length < 3) return parciales;
  var maximo = 0.0;
  var minimo = double.infinity;
  for (final parcial in completos) {
    if (parcial.velocidadMedia > maximo) maximo = parcial.velocidadMedia;
    if (parcial.velocidadMedia < minimo) minimo = parcial.velocidadMedia;
  }
  if (maximo <= 0 || maximo - minimo < 1e-6) return parciales;
  return [
    for (final parcial in parciales)
      if (!parcial.completo)
        parcial
      else if ((parcial.velocidadMedia - maximo).abs() < 1e-6)
        parcial.copyWith(destacado: DestacadoParcial.masRapido)
      else if ((parcial.velocidadMedia - minimo).abs() < 1e-6)
        parcial.copyWith(destacado: DestacadoParcial.masLento)
      else
        parcial,
  ];
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
