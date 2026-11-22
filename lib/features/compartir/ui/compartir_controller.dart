import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/models/sesion.dart';
import '../../../core/servicios/compartir.dart';

class CompartirController extends ChangeNotifier {
  CompartirController({required this.servicio});

  final ServicioCompartir servicio;
  bool _compartiendo = false;
  String? _sesionCompartiendoId;
  String? _error;

  bool get compartiendo => _compartiendo;
  String? get sesionCompartiendoId => _sesionCompartiendoId;
  String? get error => _error;

  bool compartiendoSesion(String id) =>
      _compartiendo && _sesionCompartiendoId == id;

  Future<bool> compartir(Sesion sesion) async {
    if (_compartiendo) return false;
    if (sesion.puntos.isEmpty) {
      _error = 'Esta ruta no tiene puntos para compartir.';
      notifyListeners();
      return false;
    }
    _compartiendo = true;
    _sesionCompartiendoId = sesion.id;
    _error = null;
    notifyListeners();
    try {
      await servicio.compartirSesion(sesion);
      return true;
    } on PlatformException catch (excepcion) {
      _error = excepcion.message ?? 'No se pudo compartir la ruta.';
      return false;
    } on Object {
      _error = 'No se pudo compartir la ruta.';
      return false;
    } finally {
      _compartiendo = false;
      _sesionCompartiendoId = null;
      notifyListeners();
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
