import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/calculos/calculos_ruta.dart';
import '../../../core/data/repositorio_sesiones.dart';
import '../../../core/models/actividad.dart';
import '../../../core/models/filtro_ruta.dart';
import '../../../core/models/perfil_gps.dart';
import '../../../core/models/punto_ruta.dart';
import '../../../core/models/sesion.dart';
import '../../../core/servicios/notificacion_ruta.dart';
import '../../../core/servicios/ubicacion.dart';

enum EstadoGrabacion {
  inactivo,
  iniciando,
  grabando,
  pausado,
  guardando,
  error,
}

class GrabacionController extends ChangeNotifier {
  GrabacionController({
    required this.ubicacion,
    required this.repositorio,
    this.notificacion,
    DateTime Function()? ahora,
    PerfilGps Function()? perfilGps,
  }) : _ahora = ahora ?? DateTime.now,
       _perfilGps = perfilGps ?? (() => PerfilGps.equilibrada);

  final ServicioUbicacion ubicacion;
  final RepositorioSesiones repositorio;
  final ServicioNotificacionRuta? notificacion;
  final DateTime Function() _ahora;
  final PerfilGps Function() _perfilGps;

  EstadoGrabacion _estado = EstadoGrabacion.inactivo;
  Actividad _actividad = Actividad.correr;
  PerfilGps _perfilActivo = PerfilGps.equilibrada;
  DateTime? _inicio;
  DateTime? _inicioTramo;
  Duration _duracionAcumulada = Duration.zero;
  final List<PuntoRuta> _puntos = [];
  final AcumuladorRuta _acumulador = AcumuladorRuta();
  int _segmentoActual = 0;
  PuntoGps? _ultimaPosicion;
  DateTime? _ultimoPuntoRecibido;
  DateTime? _ultimoAutoguardado;
  StreamSubscription<PuntoGps>? _suscripcion;
  Timer? _temporizador;
  Sesion? _borrador;
  Sesion? _ultimaSesion;
  String? _mensajeError;
  bool _denegadoSiempre = false;
  bool _servicioDesactivado = false;
  bool _sinSenal = false;
  bool _avisoNotificaciones = false;
  bool _errorGuardado = false;
  bool _guardandoBorrador = false;
  bool _disposed = false;
  bool _calentando = false;
  DateTime? _inicioCalentamiento;
  int _puntosBuenos = 0;

  FiltroRuta get _filtroActivo => FiltroRuta(
    precisionMaxima: _perfilActivo.precisionMaxima,
    velocidadMaxima: _actividad.velocidadMaximaPlausible,
    calentamiento: Duration.zero,
  );

  EstadoGrabacion get estado => _estado;
  Actividad get actividad => _actividad;
  DateTime? get inicio => _inicio;
  Sesion? get borrador => _borrador;
  Sesion? get ultimaSesion => _ultimaSesion;
  String? get mensajeError => _mensajeError;
  bool get denegadoSiempre => _denegadoSiempre;
  bool get servicioDesactivado => _servicioDesactivado;
  bool get sinSenal => _sinSenal;
  bool get avisoNotificaciones => _avisoNotificaciones;
  bool get errorGuardado => _errorGuardado;
  double? get precisionActual => _ultimaPosicion?.precision;
  bool get senalDebil {
    final posicion = _ultimaPosicion;
    if (posicion == null) return false;
    final ultimo = _ultimoPuntoRecibido;
    if (ultimo == null) return true;
    final sinPunto = _ahora().difference(ultimo) > const Duration(seconds: 5);
    final precisionMala =
        posicion.precision != null &&
        posicion.precision! > _perfilActivo.precisionMaxima;
    return sinPunto || precisionMala;
  }

  List<PuntoRuta> get puntos => List.unmodifiable(_puntos);
  PuntoGps? get ultimaPosicion => _ultimaPosicion;
  double get distanciaMetros => _acumulador.distanciaMetros;
  double get desnivelPositivo => _acumulador.desnivelPositivo;
  double get desnivelNegativo => _acumulador.desnivelNegativo;
  double? get altitudActual =>
      _puntos.isEmpty ? _ultimaPosicion?.altitud : _puntos.last.altitud;

  bool get bloqueadoPorBorrador =>
      _borrador != null && _estado == EstadoGrabacion.inactivo;

  bool get tienePuntos => _puntos.isNotEmpty;

  Duration get duracionActiva {
    if (_inicioTramo == null) return _duracionAcumulada;
    final tramo = _ahora().difference(_inicioTramo!);
    return _duracionAcumulada + (tramo.isNegative ? Duration.zero : tramo);
  }

  double get velocidadMedia {
    final segundos = duracionActiva.inMilliseconds / 1000;
    if (segundos <= 0) return 0;
    return _acumulador.distanciaMetros / segundos;
  }

  double? get velocidadActual {
    final ultimo = _puntos.isEmpty ? null : _puntos.last;
    if (ultimo == null || _puntos.length < 2) return null;
    final anterior = _puntos[_puntos.length - 2];
    if (anterior.segmento != ultimo.segmento) return null;
    if (ultimo.velocidad != null) {
      return ultimo.velocidad;
    }
    final segundos =
        ultimo.tiempo.difference(anterior.tiempo).inMilliseconds / 1000;
    if (segundos <= 0) return ultimo.velocidad;
    return distanciaHaversine(anterior, ultimo) / segundos;
  }

  Future<void> inicializar() async {
    try {
      _borrador = await repositorio.cargarBorrador();
    } on Object {
      _borrador = null;
    }
    if (!_disposed) notifyListeners();
  }

  void cambiarActividad(Actividad actividad) {
    if (_estado != EstadoGrabacion.inactivo || _actividad == actividad) return;
    _actividad = actividad;
    notifyListeners();
  }

  Future<void> iniciar() async {
    if (_estado != EstadoGrabacion.inactivo || bloqueadoPorBorrador) {
      if (bloqueadoPorBorrador) {
        _mensajeError =
            'Recupera o descarta la sesión pendiente antes de empezar otra.';
        notifyListeners();
      }
      return;
    }
    _estado = EstadoGrabacion.iniciando;
    _mensajeError = null;
    _denegadoSiempre = false;
    _servicioDesactivado = false;
    _errorGuardado = false;
    _avisoNotificaciones = false;
    _sinSenal = true;
    notifyListeners();

    final notificaciones = await ubicacion.prepararNotificaciones();
    if (_disposed) return;
    _avisoNotificaciones = !notificaciones;
    final permiso = await ubicacion.asegurarPermiso();
    if (_disposed) return;
    if (permiso != PermisoUbicacion.concedido) {
      _estado = EstadoGrabacion.inactivo;
      _denegadoSiempre = permiso == PermisoUbicacion.denegadoSiempre;
      _servicioDesactivado = permiso == PermisoUbicacion.servicioDesactivado;
      _mensajeError = switch (permiso) {
        PermisoUbicacion.denegadoSiempre => 'El permiso de ubicación está bloqueado. Ábrelo en los ajustes de la app para grabar rutas.',
        PermisoUbicacion.denegado => 'Sin permiso de ubicación no se pueden grabar rutas. Puedes concederlo al volver a intentarlo.',
        PermisoUbicacion.servicioDesactivado => 'La ubicación del dispositivo está desactivada. Actívala para empezar a grabar.',
        PermisoUbicacion.error =>
          'No se pudo comprobar la ubicación. Inténtalo de nuevo.',
        PermisoUbicacion.concedido => null,
      };
      notifyListeners();
      return;
    }

    _inicio = _ahora();
    _inicioTramo = _inicio;
    _duracionAcumulada = Duration.zero;
    _segmentoActual = 0;
    _perfilActivo = _perfilGps();
    _puntos.clear();
    _acumulador.reiniciar();
    _acumulador.filtro = _filtroActivo;
    _iniciarCalentamiento();
    _ultimaPosicion = null;
    _ultimoPuntoRecibido = null;
    _ultimoAutoguardado = null;
    _sinSenal = true;
    _estado = EstadoGrabacion.grabando;
    await notificacion?.iniciar();
    _iniciarTemporizador();
    try {
      _suscribir();
    } on Object {
      _cerrarTramo();
      _temporizador?.cancel();
      _estado = EstadoGrabacion.error;
      _mensajeError =
          'No se pudo iniciar el servicio de ubicación. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<void> pausar() async {
    if (_estado != EstadoGrabacion.grabando) return;
    _cerrarTramo();
    _temporizador?.cancel();
    _temporizador = null;
    await _suscripcion?.cancel();
    _suscripcion = null;
    _sinSenal = false;
    _estado = EstadoGrabacion.pausado;
    notifyListeners();
    await notificacion?.actualizar(pausado: true);
    await _guardarBorrador();
  }

  Future<void> reanudar() async {
    if (_estado != EstadoGrabacion.pausado &&
        _estado != EstadoGrabacion.error) {
      return;
    }
    _estado = EstadoGrabacion.iniciando;
    _mensajeError = null;
    _errorGuardado = false;
    notifyListeners();
    final notificaciones = await ubicacion.prepararNotificaciones();
    if (_disposed) return;
    _avisoNotificaciones = !notificaciones;
    final permiso = await ubicacion.asegurarPermiso();
    if (_disposed) return;
    if (permiso != PermisoUbicacion.concedido) {
      _estado = EstadoGrabacion.pausado;
      _denegadoSiempre = permiso == PermisoUbicacion.denegadoSiempre;
      _servicioDesactivado = permiso == PermisoUbicacion.servicioDesactivado;
      _mensajeError = _mensajePermiso(permiso);
      notifyListeners();
      return;
    }
    _abrirTramo();
    _segmentoActual += 1;
    _iniciarCalentamiento();
    _sinSenal = true;
    _estado = EstadoGrabacion.grabando;
    await notificacion?.iniciar();
    _iniciarTemporizador();
    try {
      _suscribir();
    } on Object {
      _cerrarTramo();
      _temporizador?.cancel();
      _temporizador = null;
      _estado = EstadoGrabacion.error;
      _mensajeError = 'No se pudo reanudar la ubicación. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<Sesion?> finalizar() async {
    if (_estado != EstadoGrabacion.grabando &&
        _estado != EstadoGrabacion.pausado &&
        _estado != EstadoGrabacion.error) {
      return null;
    }
    _estado = EstadoGrabacion.guardando;
    _sinSenal = false;
    notifyListeners();
    _temporizador?.cancel();
    _temporizador = null;
    await _suscripcion?.cancel();
    _suscripcion = null;
    _cerrarTramo();

    if (_puntos.isEmpty || _inicio == null) {
      await _borrarBorradorSilencioso();
      await notificacion?.detener();
      _resetear();
      _mensajeError =
          'No se ha registrado ninguna posición. No hay ruta que guardar.';
      notifyListeners();
      return null;
    }

    final sesion = Sesion(
      id: Sesion.generarId(_inicio!),
      actividad: _actividad,
      inicio: _inicio!,
      fin: _ahora(),
      duracionActiva: _duracionAcumulada,
      puntos: List<PuntoRuta>.unmodifiable(_puntos),
    );
    try {
      await repositorio.guardar(sesion);
      await repositorio.borrarBorrador();
      await notificacion?.detener();
      _borrador = null;
      _ultimaSesion = sesion;
      _resetear();
      notifyListeners();
      return sesion;
    } on Object {
      _estado = EstadoGrabacion.error;
      _errorGuardado = true;
      _mensajeError = 'No se pudo guardar la sesión. El borrador se conserva; inténtalo de nuevo.';
      await _guardarBorrador();
      notifyListeners();
      return null;
    }
  }

  Future<void> descartar() async {
    if (_estado == EstadoGrabacion.guardando) return;
    _temporizador?.cancel();
    _temporizador = null;
    await _suscripcion?.cancel();
    _suscripcion = null;
    await _borrarBorradorSilencioso();
    await notificacion?.detener();
    _resetear();
    _borrador = null;
    notifyListeners();
  }

  Future<void> recuperarBorrador() async {
    final borrador = _borrador;
    if (borrador == null) return;
    _actividad = borrador.actividad;
    _inicio = borrador.inicio;
    _duracionAcumulada = borrador.duracionActiva;
    _inicioTramo = null;
    _puntos
      ..clear()
      ..addAll(borrador.puntos);
    _segmentoActual = borrador.puntos.isEmpty
        ? 0
        : borrador.puntos.last.segmento;
    _perfilActivo = _perfilGps();
    _acumulador.reiniciar();
    _acumulador.filtro = _filtroActivo;
    for (final punto in borrador.puntos) {
      _acumulador.agregar(punto);
    }
    _ultimoPuntoRecibido = borrador.puntos.isEmpty
        ? null
        : borrador.puntos.last.tiempo;
    _ultimaPosicion = borrador.puntos.isEmpty
        ? null
        : PuntoGps(
            latitud: borrador.puntos.last.latitud,
            longitud: borrador.puntos.last.longitud,
            tiempo: borrador.puntos.last.tiempo,
            altitud: borrador.puntos.last.altitud,
            precision: borrador.puntos.last.precision,
            velocidad: borrador.puntos.last.velocidad,
          );
    _borrador = null;
    _sinSenal = false;
    _estado = EstadoGrabacion.pausado;
    _mensajeError = null;
    notifyListeners();
  }

  Future<void> descartarBorrador() async {
    if (_borrador == null) return;
    await _borrarBorradorSilencioso();
    _borrador = null;
    notifyListeners();
  }

  Future<void> abrirAjustesPermiso() => ubicacion.abrirAjustesPermiso();

  Future<void> abrirAjustesUbicacion() => ubicacion.abrirAjustesUbicacion();

  void limpiarAviso() {
    _mensajeError = null;
    _denegadoSiempre = false;
    _servicioDesactivado = false;
    notifyListeners();
  }

  void _suscribir() {
    _suscripcion?.cancel();
    _suscripcion = ubicacion
        .posiciones(_perfilActivo)
        .listen(
          _alRecibirPunto,
          onError: _alErrorUbicacion,
          cancelOnError: false,
        );
  }

  void _alRecibirPunto(PuntoGps posicion) {
    if (_estado != EstadoGrabacion.grabando) return;
    _ultimaPosicion = posicion;
    if (!_pasaCalentamiento(posicion)) return;
    final punto = PuntoRuta(
      latitud: posicion.latitud,
      longitud: posicion.longitud,
      tiempo: posicion.tiempo,
      altitud: posicion.altitud,
      precision: posicion.precision,
      velocidad: posicion.velocidad,
      rumbo: posicion.rumbo,
      segmento: _segmentoActual,
    );
    final anterior = _puntos.isEmpty || _puntos.last.segmento != _segmentoActual
        ? null
        : _puntos.last;
    if (!puntoAceptable(anterior, punto, filtro: _filtroActivo)) return;
    _puntos.add(punto);
    _acumulador.agregar(punto);
    _ultimoPuntoRecibido = _ahora();
    _sinSenal = false;
    _talVezAutoguardar();
    notifyListeners();
  }

  void _iniciarCalentamiento() {
    _calentando = true;
    _inicioCalentamiento = _ahora();
    _puntosBuenos = 0;
  }

  bool _pasaCalentamiento(PuntoGps posicion) {
    if (!_calentando) return true;
    final buena =
        posicion.precision == null ||
        posicion.precision! <= _perfilActivo.precisionMaxima;
    _puntosBuenos = buena ? _puntosBuenos + 1 : 0;
    final inicio = _inicioCalentamiento;
    final pasaron5s =
        inicio == null ||
        _ahora().difference(inicio) >= const Duration(seconds: 5);
    if (_puntosBuenos >= 2 || pasaron5s) {
      _calentando = false;
      _inicioCalentamiento = null;
      _puntosBuenos = 0;
      return true;
    }
    return false;
  }

  void _alErrorUbicacion(Object error) {
    if (_estado != EstadoGrabacion.grabando) return;
    _cerrarTramo();
    _temporizador?.cancel();
    _temporizador = null;
    _suscripcion?.cancel();
    _suscripcion = null;
    _sinSenal = false;
    _estado = EstadoGrabacion.error;
    _mensajeError = 'Se ha perdido el servicio de ubicación. Los puntos grabados se conservan.';
    notifyListeners();
  }

  void _iniciarTemporizador() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_estado != EstadoGrabacion.grabando) return;
      final ultimo = _ultimoPuntoRecibido;
      final sinSenal =
          ultimo == null ||
          _ahora().difference(ultimo) > const Duration(seconds: 15);
      if (sinSenal != _sinSenal) {
        _sinSenal = sinSenal;
      }
      notifyListeners();
    });
  }

  void _talVezAutoguardar() {
    final ahora = _ahora();
    if (_puntos.length < 2) return;
    final ultimo = _ultimoAutoguardado;
    if (ultimo != null &&
        ahora.difference(ultimo) < const Duration(seconds: 5)) {
      return;
    }
    _ultimoAutoguardado = ahora;
    unawaited(_guardarBorrador());
  }

  Future<void> _guardarBorrador() async {
    if (_guardandoBorrador || _inicio == null) return;
    _guardandoBorrador = true;
    try {
      final borrador = Sesion(
        id: Sesion.generarId(_inicio!),
        actividad: _actividad,
        inicio: _inicio!,
        duracionActiva: duracionActiva,
        puntos: List<PuntoRuta>.unmodifiable(_puntos),
      );
      await repositorio.guardarBorrador(borrador);
    } on Object {
      // El autoguardado es best-effort; el guardado final sí notifica errores.
    } finally {
      _guardandoBorrador = false;
    }
  }

  Future<void> _borrarBorradorSilencioso() async {
    try {
      await repositorio.borrarBorrador();
    } on Object {
      // No hay nada que hacer si el borrador ya no existe.
    }
  }

  void _cerrarTramo() {
    if (_inicioTramo == null) return;
    final tramo = _ahora().difference(_inicioTramo!);
    if (!tramo.isNegative) {
      _duracionAcumulada += tramo;
    }
    _inicioTramo = null;
  }

  void _abrirTramo() {
    _inicioTramo = _ahora();
  }

  void _resetear() {
    _estado = EstadoGrabacion.inactivo;
    _inicio = null;
    _inicioTramo = null;
    _duracionAcumulada = Duration.zero;
    _segmentoActual = 0;
    _perfilActivo = PerfilGps.equilibrada;
    _calentando = false;
    _inicioCalentamiento = null;
    _puntosBuenos = 0;
    _puntos.clear();
    _acumulador.reiniciar();
    _ultimaPosicion = null;
    _ultimoPuntoRecibido = null;
    _ultimoAutoguardado = null;
    _sinSenal = false;
    _avisoNotificaciones = false;
    _mensajeError = null;
    _denegadoSiempre = false;
    _servicioDesactivado = false;
    _errorGuardado = false;
  }

  String? _mensajePermiso(PermisoUbicacion permiso) => switch (permiso) {
    PermisoUbicacion.denegadoSiempre => 'El permiso de ubicación está bloqueado. Ábrelo en los ajustes de la app.',
    PermisoUbicacion.denegado =>
      'Sin permiso de ubicación no se pueden grabar rutas.',
    PermisoUbicacion.servicioDesactivado =>
      'La ubicación del dispositivo está desactivada.',
    PermisoUbicacion.error =>
      'No se pudo comprobar la ubicación. Inténtalo de nuevo.',
    PermisoUbicacion.concedido => null,
  };

  @override
  void dispose() {
    _disposed = true;
    _temporizador?.cancel();
    _suscripcion?.cancel();
    if (_estado == EstadoGrabacion.grabando ||
        _estado == EstadoGrabacion.pausado ||
        _estado == EstadoGrabacion.error) {
      unawaited(notificacion?.detener());
    }
    super.dispose();
  }
}
