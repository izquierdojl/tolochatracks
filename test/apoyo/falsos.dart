import 'dart:async';

import 'package:tolochatracks/core/data/repositorio_sesiones.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/core/servicios/compartir.dart';
import 'package:tolochatracks/core/servicios/exportacion.dart';
import 'package:tolochatracks/core/servicios/notificacion_ruta.dart';
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
  int notificacionesPedidas = 0;
  bool notificacionesConcedidas = true;
  int ajustesPermisoAbiertos = 0;
  int ajustesUbicacionAbiertos = 0;
  final List<PerfilGps> perfiles = [];
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
  Future<bool> prepararNotificaciones() async {
    notificacionesPedidas += 1;
    return notificacionesConcedidas;
  }

  @override
  Future<PermisoUbicacion> asegurarPermiso() async => permiso;

  @override
  Future<bool> servicioActivo() async => activo;

  @override
  Future<PuntoGps?> posicionActual() async => null;

  @override
  Stream<PuntoGps> posiciones(PerfilGps perfil) {
    perfiles.add(perfil);
    return _posiciones.stream;
  }

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

class ServicioExportacionFalso implements ServicioExportacion {
  ServicioExportacionFalso({
    this.directorio = const DirectorioExportacion(
      uri: 'content://com.android.providers.downloads.documents/tree/rutas',
      nombre: 'Rutas',
    ),
  });

  DirectorioExportacion? directorio;
  List<ArchivoExportacion> archivos = [];
  bool fallar = false;
  final Set<String> fallarNombres = {};
  final List<String> nombresBorrados = [];
  int noEncontrados = 0;
  final List<String> erroresBorrado = [];
  Object? errorBorrado;

  @override
  Future<DirectorioExportacion?> elegirDirectorio() async => directorio;

  @override
  Future<ResultadoExportacion> exportar({
    required String uri,
    required List<ArchivoExportacion> archivos,
  }) async {
    if (fallar) throw StateError('fallo simulado');
    this.archivos = [...archivos];
    final correctos = <String>[];
    final errores = <String>[];
    for (final archivo in archivos) {
      if (fallarNombres.contains(archivo.nombre)) {
        errores.add('${archivo.nombre}: fallo simulado');
      } else {
        correctos.add(archivo.nombre);
      }
    }
    return ResultadoExportacion(
      exportados: correctos.length,
      errores: errores,
      archivosCorrectos: correctos,
    );
  }

  @override
  Future<ResultadoBorrado> borrar({
    required String uri,
    required List<String> nombres,
  }) async {
    if (errorBorrado != null) throw errorBorrado!;
    nombresBorrados.addAll(nombres);
    final borrados = nombres.length - noEncontrados - erroresBorrado.length;
    return ResultadoBorrado(
      borrados: borrados < 0 ? 0 : borrados,
      noEncontrados: noEncontrados,
      errores: [...erroresBorrado],
    );
  }
}

class ServicioCompartirFalso implements ServicioCompartir {
  final List<Sesion> compartidas = [];
  bool fallar = false;
  Completer<void>? espera;

  @override
  Future<void> compartirSesion(Sesion sesion) async {
    if (fallar) throw StateError('fallo simulado');
    if (espera != null) await espera!.future;
    compartidas.add(sesion);
  }
}

class ServicioNotificacionRutaFalso implements ServicioNotificacionRuta {
  final StreamController<AccionNotificacion> _acciones =
      StreamController<AccionNotificacion>.broadcast();
  int inicios = 0;
  int actualizaciones = 0;
  int detenciones = 0;
  bool? ultimoPausado;

  @override
  Stream<AccionNotificacion> get acciones => _acciones.stream;

  @override
  Future<void> iniciar() async {
    inicios += 1;
  }

  @override
  Future<void> actualizar({required bool pausado}) async {
    actualizaciones += 1;
    ultimoPausado = pausado;
  }

  @override
  Future<void> detener() async {
    detenciones += 1;
  }

  @override
  Future<void> dispose() async {
    await _acciones.close();
  }
}
