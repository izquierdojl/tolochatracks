import '../models/sesion.dart';
import '../utilidades/formato.dart';

String gpxDeSesion(Sesion sesion) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="TolochaTracks"'
      ' xmlns="http://www.topografix.com/GPX/1/1"'
      ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      ' xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
      'http://www.topografix.com/GPX/1/1/gpx.xsd">',
    )
    ..writeln('  <metadata>')
    ..writeln('    <name>${_escapar(_nombreSesion(sesion))}</name>')
    ..writeln('    <time>${sesion.inicio.toUtc().toIso8601String()}</time>')
    ..writeln('  </metadata>')
    ..writeln('  <trk>')
    ..writeln('    <name>${_escapar(_nombreSesion(sesion))}</name>')
    ..writeln('    <type>${_escapar(sesion.actividad.tipoGpx)}</type>')
    ..writeln('    <trkseg>');
  var segmentoActual = sesion.puntos.isEmpty ? 0 : sesion.puntos.first.segmento;
  for (final punto in sesion.puntos) {
    if (punto.segmento != segmentoActual) {
      buffer
        ..writeln('    </trkseg>')
        ..writeln('    <trkseg>');
      segmentoActual = punto.segmento;
    }
    buffer.writeln(
      '      <trkpt lat="${punto.latitud.toStringAsFixed(7)}" '
      'lon="${punto.longitud.toStringAsFixed(7)}">',
    );
    if (punto.altitud != null) {
      buffer.writeln('        <ele>${punto.altitud!.toStringAsFixed(1)}</ele>');
    }
    buffer.writeln(
      '        <time>${punto.tiempo.toUtc().toIso8601String()}</time>',
    );
    buffer.writeln('      </trkpt>');
  }
  buffer
    ..writeln('    </trkseg>')
    ..writeln('  </trk>')
    ..writeln('</gpx>');
  return buffer.toString();
}

String _nombreSesion(Sesion sesion) =>
    '${sesion.actividad.etiqueta} · ${formatearFechaHora(sesion.inicio)}';

String _escapar(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
