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
      _ultimoResultado = resultado;
      if (!resultado.correcto) {
        _error =
            'Se exportaron ${resultado.exportados} archivos, pero '
            '${resultado.errores.length} fallaron.';
      }
      return resultado;
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

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
