import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../exportacion/exportacion_sesion.dart';
import '../exportacion/gpx.dart';
import '../models/sesion.dart';
import '../utilidades/formato.dart';

abstract interface class ServicioCompartir {
  Future<void> compartirSesion(Sesion sesion);
}

class ServicioCompartirCanal implements ServicioCompartir {
  const ServicioCompartirCanal();

  static const canal = MethodChannel('com.izquierdojl.tolochatracks/compartir');

  @override
  Future<void> compartirSesion(Sesion sesion) async {
    final temporal = await getTemporaryDirectory();
    final carpeta = Directory(p.join(temporal.path, 'compartir'));
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    await _limpiarAntiguos(carpeta);
    final archivo = File(p.join(carpeta.path, nombreGpx(sesion)));
    await archivo.writeAsString(gpxDeSesion(sesionValida(sesion)), flush: true);
    await canal.invokeMethod<void>('compartirArchivo', {
      'ruta': archivo.path,
      'mime': 'application/gpx+xml',
      'asunto':
          'Ruta ${sesion.actividad.etiqueta} · '
          '${formatearFechaHora(sesion.inicio)}',
    });
  }

  Future<void> _limpiarAntiguos(Directory carpeta) async {
    final limite = DateTime.now().subtract(const Duration(days: 1));
    try {
      await for (final entrada in carpeta.list()) {
        if (entrada is! File || !entrada.path.endsWith('.gpx')) continue;
        final modificado = await entrada.lastModified();
        if (modificado.isBefore(limite)) {
          await entrada.delete();
        }
      }
    } on Object {
      return;
    }
  }
}
