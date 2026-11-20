import 'package:flutter/foundation.dart';

import '../../../core/calculos/calculos_ruta.dart';
import '../../../core/data/repositorio_sesiones.dart';
import '../../../core/models/actividad.dart';
import '../../../core/models/estadisticas_ruta.dart';
import '../../../core/models/sesion.dart';

enum EstadoHistorial { cargando, datos, vacio, error }

class HistorialController extends ChangeNotifier {
  HistorialController({required this.repositorio});

  final RepositorioSesiones repositorio;
  EstadoHistorial _estado = EstadoHistorial.cargando;
  List<Sesion> _sesiones = [];
  Actividad? _filtro;
  String? _error;
  final Map<String, EstadisticasRuta> _cacheEstadisticas = {};

  EstadoHistorial get estado => _estado;
  List<Sesion> get sesiones => List.unmodifiable(_sesiones);
  Actividad? get filtro => _filtro;
  String? get error => _error;

  List<Sesion> get sesionesFiltradas => _filtro == null
      ? List.unmodifiable(_sesiones)
      : List.unmodifiable(
          _sesiones.where((sesion) => sesion.actividad == _filtro),
        );

  bool get filtroSinResultados =>
      _filtro != null && sesionesFiltradas.isEmpty && _sesiones.isNotEmpty;

  void cambiarFiltro(Actividad? actividad) {
    if (_filtro == actividad) return;
    _filtro = actividad;
    notifyListeners();
  }

  Future<void> cargar() async {
    _estado = EstadoHistorial.cargando;
    _error = null;
    notifyListeners();
    try {
      final sesiones = await repositorio.listar();
      _sesiones = sesiones;
      _cacheEstadisticas.clear();
      _estado = sesiones.isEmpty
          ? EstadoHistorial.vacio
          : EstadoHistorial.datos;
    } on Object {
      _sesiones = [];
      _estado = EstadoHistorial.error;
      _error = 'No se pudo leer el historial de rutas.';
    }
    notifyListeners();
  }

  EstadisticasRuta estadisticas(Sesion sesion) {
    return _cacheEstadisticas.putIfAbsent(
      sesion.id,
      () => calcularEstadisticas(
        sesion.puntos,
        duracionActiva: sesion.duracionActiva,
        inicio: sesion.inicio,
        fin: sesion.fin,
      ),
    );
  }

  double get distanciaTotalMetros => sesionesFiltradas.fold(
    0,
    (total, sesion) => total + estadisticas(sesion).distanciaMetros,
  );

  Duration get duracionTotal => sesionesFiltradas.fold(
    Duration.zero,
    (total, sesion) => total + sesion.duracionActiva,
  );

  Future<bool> eliminar(Sesion sesion) async {
    try {
      await repositorio.eliminar(sesion.id);
      _sesiones = _sesiones.where((otra) => otra.id != sesion.id).toList();
      _cacheEstadisticas.remove(sesion.id);
      _estado = _sesiones.isEmpty
          ? EstadoHistorial.vacio
          : EstadoHistorial.datos;
      notifyListeners();
      return true;
    } on Object {
      _error = 'No se pudo eliminar la sesión.';
      notifyListeners();
      return false;
    }
  }
}
