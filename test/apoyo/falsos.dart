import 'dart:async';

import 'package:tolochatracks/core/data/repositorio_sesiones.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/core/servicios/ubicacion.dart';

class RepositorioSesionesFalso implements RepositorioSesiones {
  RepositorioSesionesFalso({List<Sesion>? sesiones, this.borrador})
    : _sesiones = [...?sesiones];

  final List<Sesion> _sesiones;
  Sesion? borrador;
  bool fallarGuardado = false;
  bool fallarListado = false;
  bool fallarEliminar = false;

  List<Sesion> get sesiones => List.unmodifiable(_sesiones);

  @override
  Future<List<Sesion>> listar() async {
    if (fallarListado) throw const FileSystemExceptionFalso();
    final copia = [..._sesiones];
    copia.sort((a, b) => b.inicio.compareTo(a.inicio));
    return copia;
  }

  @override
  Future<Sesion?> cargar(String id) async {
    for (final sesion in _sesiones) {
      if (sesion.id == id) return sesion;
    }
    return null;
  }

  @override
  Future<void> guardar(Sesion sesion) async {
    if (fallarGuardado) throw const FileSystemExceptionFalso();
    _sesiones.removeWhere((otra) => otra.id == sesion.id);
    _sesiones.add(sesion);
  }

  @override
  Future<void> eliminar(String id) async {
    if (fallarEliminar) throw const FileSystemExceptionFalso();
    _sesiones.removeWhere((sesion) => sesion.id == id);
  }

  @override
  Future<void> guardarBorrador(Sesion sesion) async {
    borrador = sesion;
  }

  @override
  Future<Sesion?> cargarBorrador() async => borrador;

  @override
  Future<void> borrarBorrador() async {
    borrador = null;
  }
}

class FileSystemExceptionFalso implements Exception {
  const FileSystemExceptionFalso();
}

class ServicioUbicacionFalso implements ServicioUbicacion {
  ServicioUbicacionFalso({
    this.permiso = PermisoUbicacion.concedido,
    this.activo = true,
  });

  PermisoUbicacion permiso;
  bool activo;
  int ajustesPermisoAbiertos = 0;
  int ajustesUbicacionAbiertos = 0;
  final StreamController<PuntoGps> _posiciones =
      StreamController<PuntoGps>.broadcast();

  Stream<PuntoGps> get flujo => _posiciones.stream;

  Future<void> emitir(PuntoGps punto) async {
    _posiciones.add(punto);
    await Future<void>.value();
  }

  Future<void> emitirError(Object error) async {
    _posiciones.addError(error);
    await Future<void>.value();
  }

  @override
  Future<PermisoUbicacion> asegurarPermiso() async => permiso;

  @override
  Future<bool> servicioActivo() async => activo;

  @override
  Future<PuntoGps?> posicionActual() async => null;

  @override
  Stream<PuntoGps> posiciones() => _posiciones.stream;

  @override
  Future<void> abrirAjustesPermiso() async {
    ajustesPermisoAbiertos += 1;
  }

  @override
  Future<void> abrirAjustesUbicacion() async {
    ajustesUbicacionAbiertos += 1;
  }

  Future<void> cerrar() => _posiciones.close();
}
