import 'package:flutter/services.dart';

class DirectorioExportacion {
  const DirectorioExportacion({required this.uri, required this.nombre});

  final String uri;
  final String nombre;
}

class ArchivoExportacion {
  const ArchivoExportacion({
    required this.nombre,
    required this.contenido,
    required this.mime,
  });

  final String nombre;
  final String contenido;
  final String mime;

  Map<String, Object?> aMapa() => {
    'nombre': nombre,
    'contenido': contenido,
    'mime': mime,
  };
}

class ResultadoExportacion {
  const ResultadoExportacion({required this.exportados, required this.errores});

  final int exportados;
  final List<String> errores;

  bool get correcto => errores.isEmpty;
}

abstract interface class ServicioExportacion {
  Future<DirectorioExportacion?> elegirDirectorio();

  Future<ResultadoExportacion> exportar({
    required String uri,
    required List<ArchivoExportacion> archivos,
  });
}

class ServicioExportacionCanal implements ServicioExportacion {
  const ServicioExportacionCanal();

  static const canal = MethodChannel(
    'com.izquierdojl.tolochatracks/exportacion',
  );

  @override
  Future<DirectorioExportacion?> elegirDirectorio() async {
    final resultado = await canal.invokeMapMethod<String, Object?>(
      'elegirDirectorio',
    );
    if (resultado == null) return null;
    final uri = resultado['uri']?.toString();
    final nombre = resultado['nombre']?.toString();
    if (uri == null || uri.isEmpty || nombre == null || nombre.isEmpty) {
      return null;
    }
    return DirectorioExportacion(uri: uri, nombre: nombre);
  }

  @override
  Future<ResultadoExportacion> exportar({
    required String uri,
    required List<ArchivoExportacion> archivos,
  }) async {
    final resultado = await canal.invokeMapMethod<String, Object?>('exportar', {
      'uri': uri,
      'archivos': [for (final archivo in archivos) archivo.aMapa()],
    });
    final exportados = resultado?['exportados'];
    final erroresRaw = resultado?['errores'];
    return ResultadoExportacion(
      exportados: exportados is num ? exportados.toInt() : 0,
      errores: erroresRaw is List
          ? [for (final error in erroresRaw) error.toString()]
          : const [],
    );
  }
}
