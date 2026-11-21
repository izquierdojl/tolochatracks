import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/exportacion/exportacion_sesion.dart';
import '../../../core/models/sesion.dart';
import '../../../core/servicios/exportacion.dart';
import '../../configuracion/ui/configuracion_controller.dart';

class ExportacionController extends ChangeNotifier {
  ExportacionController({required this.servicio, required this.configuracion});

  final ServicioExportacion servicio;
  final ConfiguracionController configuracion;
  bool _exportando = false;
  String? _error;
  ResultadoExportacion? _ultimoResultado;

  bool get exportando => _exportando;
  String? get error => _error;
  ResultadoExportacion? get ultimoResultado => _ultimoResultado;
  bool get sinDirectorio => !configuracion.tieneDirectorio;

  Future<ResultadoExportacion?> exportar(List<Sesion> sesiones) async {
    if (sesiones.isEmpty) {
      _error = 'No hay rutas que exportar.';
      notifyListeners();
      return null;
    }
    final uri = configuracion.directorioExportacionUri;
    if (uri == null || uri.isEmpty) {
      _error = 'Elige una carpeta de exportación antes de continuar.';
      notifyListeners();
      return null;
    }
    _exportando = true;
    _error = null;
    notifyListeners();
    try {
      final archivos = <ArchivoExportacion>[
        for (final sesion in sesiones) ...archivosDeSesion(sesion),
      ];
      final resultado = await servicio.exportar(uri: uri, archivos: archivos);
      final correctos = resultado.archivosCorrectos.toSet();
      final sesionesExportadas = <String>{
        for (final sesion in sesiones)
          if (correctos.contains(nombreGpx(sesion)) &&
              correctos.contains(nombreJson(sesion)))
            sesion.id,
      };
      final resultadoFinal = ResultadoExportacion(
        exportados: resultado.exportados,
        errores: resultado.errores,
        archivosCorrectos: resultado.archivosCorrectos,
        sesionesExportadas: sesionesExportadas,
      );
      _ultimoResultado = resultadoFinal;
      if (!resultadoFinal.correcto) {
        _error =
            'Se exportaron ${resultadoFinal.exportados} archivos, pero '
            '${resultadoFinal.errores.length} fallaron.';
      }
      return resultadoFinal;
    } on PlatformException catch (excepcion) {
      _error = excepcion.message ?? 'No se pudo exportar a la carpeta elegida.';
      return null;
    } on Object {
      _error = 'No se pudo exportar a la carpeta elegida.';
      return null;
    } finally {
      _exportando = false;
      notifyListeners();
    }
  }

  Future<ResultadoBorrado?> borrarArchivosDeSesion(Sesion sesion) async {
    final uri = configuracion.directorioExportacionUri;
    if (uri == null || uri.isEmpty) {
      _error = 'No hay carpeta de exportación configurada.';
      notifyListeners();
      return null;
    }
    _error = null;
    try {
      return await servicio.borrar(
        uri: uri,
        nombres: [nombreGpx(sesion), nombreJson(sesion)],
      );
    } on PlatformException catch (excepcion) {
      _error =
          excepcion.message ?? 'No se pudieron borrar los archivos exportados.';
      notifyListeners();
      return null;
    } on Object {
      _error = 'No se pudieron borrar los archivos exportados.';
      notifyListeners();
      return null;
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
