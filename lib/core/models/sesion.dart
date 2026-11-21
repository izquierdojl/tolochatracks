import 'dart:math';

import 'package:flutter/foundation.dart';

import 'actividad.dart';
import 'punto_ruta.dart';

const formatoSesionActual = 2;

@immutable
class Sesion {
  const Sesion({
    required this.id,
    required this.actividad,
    required this.inicio,
    required this.duracionActiva,
    required this.puntos,
    this.fin,
    this.formato = formatoSesionActual,
    this.exportada = false,
  });

  final String id;
  final int formato;
  final Actividad actividad;
  final DateTime inicio;
  final DateTime? fin;
  final Duration duracionActiva;
  final List<PuntoRuta> puntos;
  final bool exportada;

  bool get abierta => fin == null;

  Sesion copiaCon({bool? exportada}) => Sesion(
    id: id,
    formato: formatoSesionActual,
    actividad: actividad,
    inicio: inicio,
    fin: fin,
    duracionActiva: duracionActiva,
    puntos: puntos,
    exportada: exportada ?? this.exportada,
  );

  static String generarId(DateTime inicio) {
    final local = inicio.toLocal();
    String dos(int valor) => valor.toString().padLeft(2, '0');
    final base =
        '${local.year}${dos(local.month)}${dos(local.day)}'
        'T${dos(local.hour)}${dos(local.minute)}${dos(local.second)}';
    final sufijo = Random().nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    return '$base-$sufijo';
  }

  Map<String, Object?> aJson() => {
    'formato': formato,
    'id': id,
    'actividad': actividad.clave,
    'inicio': inicio.toUtc().toIso8601String(),
    if (fin != null) 'fin': fin!.toUtc().toIso8601String(),
    'duracionSegundos': duracionActiva.inSeconds,
    'exportada': exportada,
    'puntos': [for (final punto in puntos) punto.aJson()],
  };

  factory Sesion.desdeJson(Map<String, Object?> json) {
    final id = json['id']?.toString();
    final inicio = _fecha(json['inicio']);
    if (id == null || id.isEmpty || inicio == null) {
      throw const FormatException('Sesión sin id o fecha de inicio');
    }
    final formato = json['formato'];
    final duracion = json['duracionSegundos'];
    final puntosJson = json['puntos'];
    final puntos = <PuntoRuta>[];
    if (puntosJson is List) {
      for (final elemento in puntosJson) {
        if (elemento is Map) {
          try {
            puntos.add(
              PuntoRuta.desdeJson(Map<String, Object?>.from(elemento)),
            );
          } on FormatException {
            continue;
          }
        }
      }
    }
    puntos.sort((a, b) => a.tiempo.compareTo(b.tiempo));
    return Sesion(
      id: id,
      formato: formato is num ? formato.toInt() : formatoSesionActual,
      actividad: Actividad.desdeClave(json['actividad']?.toString()),
      inicio: inicio,
      fin: _fecha(json['fin']),
      duracionActiva: Duration(seconds: duracion is num ? duracion.toInt() : 0),
      puntos: List.unmodifiable(puntos),
      exportada: json['exportada'] == true,
    );
  }

  static DateTime? _fecha(Object? valor) {
    if (valor is! String) return null;
    return DateTime.tryParse(valor)?.toLocal();
  }
}
