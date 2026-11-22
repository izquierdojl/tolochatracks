import 'dart:convert';

import '../calculos/calculos_ruta.dart';
import '../models/sesion.dart';
import '../servicios/exportacion.dart';
import 'gpx.dart';

String jsonDeSesion(Sesion sesion) =>
    const JsonEncoder.withIndent('  ').convert(sesion.aJson());

String nombreBaseSesion(Sesion sesion) {
  final fecha = sesion.inicio.toLocal();
  String dos(int valor) => valor.toString().padLeft(2, '0');
  final marca =
      '${fecha.year}${dos(fecha.month)}${dos(fecha.day)}_'
      '${dos(fecha.hour)}${dos(fecha.minute)}';
  final actividad = _ascii(sesion.actividad.clave);
  final id = _ascii(sesion.id);
  return 'tolochatracks_${marca}_${actividad}_$id';
}

String nombreGpx(Sesion sesion) => '${nombreBaseSesion(sesion)}.gpx';

String nombreJson(Sesion sesion) => '${nombreBaseSesion(sesion)}.json';

List<ArchivoExportacion> archivosDeSesion(Sesion sesion) {
  final valida = sesionValida(sesion);
  return [
    ArchivoExportacion(
      nombre: nombreGpx(sesion),
      contenido: gpxDeSesion(valida),
      mime: 'application/gpx+xml',
    ),
    ArchivoExportacion(
      nombre: nombreJson(sesion),
      contenido: jsonDeSesion(valida),
      mime: 'application/json',
    ),
  ];
}

Sesion sesionValida(Sesion sesion) {
  final puntos = puntosValidosDeSesion(
    sesion.puntos,
    actividad: sesion.actividad,
  );
  if (puntos.length == sesion.puntos.length) return sesion;
  return Sesion(
    id: sesion.id,
    actividad: sesion.actividad,
    inicio: sesion.inicio,
    fin: sesion.fin,
    duracionActiva: sesion.duracionActiva,
    puntos: puntos,
    exportada: sesion.exportada,
  );
}

String _ascii(String texto) {
  const reemplazos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'Ñ': 'N',
  };
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final caracter = String.fromCharCode(rune);
    final reemplazo = reemplazos[caracter];
    if (reemplazo != null) {
      buffer.write(reemplazo);
    } else if (RegExp(r'[A-Za-z0-9._-]').hasMatch(caracter)) {
      buffer.write(caracter);
    } else {
      buffer.write('-');
    }
  }
  final resultado = buffer.toString().replaceAll(RegExp(r'-+'), '-');
  return resultado.replaceAll(RegExp(r'^-|-$'), '');
}
