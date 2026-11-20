import 'package:flutter/material.dart';

import '../../../core/servicios/exportacion.dart';
import '../data/configuracion_repositorio.dart';

class ConfiguracionController extends ChangeNotifier {
  ConfiguracionController({
    required this.repositorio,
    required this.exportacion,
  });

  final ConfiguracionRepositorio repositorio;
  final ServicioExportacion exportacion;
  Ajustes _ajustes = const Ajustes();
  String? _ultimoError;

  ThemeMode get tema => _ajustes.tema;
  String? get directorioExportacionUri => _ajustes.directorioExportacionUri;
  String? get directorioExportacionNombre =>
      _ajustes.directorioExportacionNombre;
  bool get tieneDirectorio => _ajustes.directorioExportacionUri != null;
  String? get ultimoError => _ultimoError;

  Future<void> cargar() async {
    try {
      _ajustes = await repositorio.cargar();
    } on Object {
      _ajustes = const Ajustes();
    }
    notifyListeners();
  }

  Future<void> cambiarTema(ThemeMode tema) async {
    if (_ajustes.tema == tema) return;
    _ajustes = _ajustes.copyWith(tema: tema);
    notifyListeners();
    await repositorio.guardar(_ajustes);
  }

  Future<DirectorioExportacion?> elegirDirectorioExportacion() async {
    _ultimoError = null;
    try {
      final directorio = await exportacion.elegirDirectorio();
      if (directorio == null) {
        notifyListeners();
        return null;
      }
      _ajustes = _ajustes.copyWith(
        directorioExportacionUri: directorio.uri,
        directorioExportacionNombre: directorio.nombre,
      );
      notifyListeners();
      await repositorio.guardar(_ajustes);
      return directorio;
    } on Object {
      _ultimoError =
          'No se pudo guardar la carpeta. Vuelve a intentarlo o elige otra.';
      notifyListeners();
      return null;
    }
  }

  Future<void> quitarDirectorioExportacion() async {
    _ajustes = _ajustes.copyWith(limpiarDirectorio: true);
    _ultimoError = null;
    notifyListeners();
    await repositorio.guardar(_ajustes);
  }
}
