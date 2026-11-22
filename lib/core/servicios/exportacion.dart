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
  const ResultadoExportacion({
    required this.exportados,
    required this.errores,
    this.archivosCorrectos = const [],
    this.sesionesExportadas = const {},
  });

  final int exportados;
  final List<String> errores;
  final List<String> archivosCorrectos;
  final Set<String> sesionesExportadas;

  bool get correcto => errores.isEmpty;
}

class ResultadoBorrado {
  const ResultadoBorrado({
    required this.borrados,
    required this.noEncontrados,
    required this.errores,
  });

  final int borrados;
  final int noEncontrados;
  final List<String> errores;

  bool get correcto => errores.isEmpty && noEncontrados == 0;
}

abstract interface class ServicioExportacion {
  Future<DirectorioExportacion?> elegirDirectorio();

  Future<ResultadoExportacion> exportar({
    required String uri,
    required List<ArchivoExportacion> archivos,
  });

  Future<ResultadoBorrado> borrar({
    required String uri,
    required List<String> nombres,
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
    final nombresRaw = resultado?['nombres'];
    return ResultadoExportacion(
      exportados: exportados is num ? exportados.toInt() : 0,
      errores: erroresRaw is List
          ? [for (final error in erroresRaw) error.toString()]
          : const [],
      archivosCorrectos: nombresRaw is List
          ? [for (final nombre in nombresRaw) nombre.toString()]
          : const [],
    );
  }

  @override
  Future<ResultadoBorrado> borrar({
    required String uri,
    required List<String> nombres,
  }) async {
    final resultado = await canal.invokeMapMethod<String, Object?>('borrar', {
      'uri': uri,
      'nombres': nombres,
    });
    final borrados = resultado?['borrados'];
    final noEncontrados = resultado?['noEncontrados'];
    final erroresRaw = resultado?['errores'];
    return ResultadoBorrado(
      borrados: borrados is num ? borrados.toInt() : 0,
      noEncontrados: noEncontrados is num ? noEncontrados.toInt() : 0,
      errores: erroresRaw is List
          ? [for (final error in erroresRaw) error.toString()]
          : const [],
    );
  }
}
