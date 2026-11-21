import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/perfil_gps.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/core/servicios/ubicacion.dart';
import 'package:tolochatracks/features/grabacion/ui/grabacion_controller.dart';

import '../apoyo/falsos.dart';

class Reloj {
  Reloj(this.valor);

  DateTime valor;

  DateTime ahora() => valor;

  void avanzar(Duration duracion) {
    valor = valor.add(duracion);
  }
}

const _metroPorGradoLatitud = 111195.0;

PuntoGps _gps(
  Reloj reloj,
  double latitud,
  double longitud, {
  double? altitud,
  double precision = 5,
  double? velocidad,
}) => PuntoGps(
  latitud: latitud,
  longitud: longitud,
  tiempo: reloj.ahora(),
  altitud: altitud,
  precision: precision,
  velocidad: velocidad,
);

void main() {
  late Reloj reloj;
  late ServicioUbicacionFalso ubicacion;
  late RepositorioSesionesFalso repositorio;
  late ServicioNotificacionRutaFalso notificacion;
  late GrabacionController controlador;
  late PerfilGps perfilGps;

  setUp(() {
    reloj = Reloj(DateTime(2026, 11, 20, 18));
    ubicacion = ServicioUbicacionFalso();
    repositorio = RepositorioSesionesFalso();
    notificacion = ServicioNotificacionRutaFalso();
    perfilGps = PerfilGps.equilibrada;
    controlador = GrabacionController(
      ubicacion: ubicacion,
      repositorio: repositorio,
      notificacion: notificacion,
      ahora: reloj.ahora,
      perfilGps: () => perfilGps,
    );
  });

  tearDown(() async {
    controlador.dispose();
    await notificacion.dispose();
    await ubicacion.cerrar();
  });

  Future<void> iniciarConPunto() async {
    await controlador.iniciar();
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, altitud: 10));
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, altitud: 10));
  }

  test('usa el perfil vigente al iniciar y lo pasa al servicio', () async {
    perfilGps = PerfilGps.maxima;
    await controlador.iniciar();
    expect(ubicacion.perfiles, [PerfilGps.maxima]);
  });

  test('mantiene el perfil de la grabación al reanudar', () async {
    perfilGps = PerfilGps.maxima;
    await iniciarConPunto();
    await controlador.pausar();
    perfilGps = PerfilGps.ahorro;
    await controlador.reanudar();
    expect(ubicacion.perfiles, [PerfilGps.maxima, PerfilGps.maxima]);
  });

  test('descarta las primeras posiciones hasta dos buenas o 5 s', () async {
    await controlador.iniciar();
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, precision: 25));
    expect(controlador.puntos, isEmpty);
    reloj.avanzar(const Duration(seconds: 1));
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, precision: 25));
    expect(controlador.puntos, hasLength(1));
    expect(controlador.velocidadActual, isNull);
  });

  test(
    'tras 5 s el calentamiento termina aunque la señal sea mejorable',
    () async {
      await controlador.iniciar();
      await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, precision: 35));
      expect(controlador.puntos, isEmpty);
      reloj.avanzar(const Duration(seconds: 6));
      await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, precision: 5));
      expect(controlador.puntos, hasLength(1));
    },
  );

  test('al reanudar no usa los primeros picos de velocidad', () async {
    await iniciarConPunto();
    await controlador.pausar();
    await controlador.reanudar();
    reloj.avanzar(const Duration(seconds: 1));
    await ubicacion.emitir(
      _gps(
        reloj,
        37.3891 + 20 / _metroPorGradoLatitud,
        -5.9845,
        precision: 26.5,
        velocidad: 33.9 / 3.6,
      ),
    );
    expect(controlador.puntos, hasLength(1));
    reloj.avanzar(const Duration(seconds: 2));
    await ubicacion.emitir(
      _gps(
        reloj,
        37.3891 + 50 / _metroPorGradoLatitud,
        -5.9845,
        precision: 17.5,
        velocidad: 21.4 / 3.6,
      ),
    );
    expect(controlador.puntos, hasLength(2));
    expect(controlador.puntos.last.segmento, 1);
    expect(controlador.velocidadActual, isNull);
    reloj.avanzar(const Duration(seconds: 4));
    await ubicacion.emitir(
      _gps(
        reloj,
        37.3891 + 58.5 / _metroPorGradoLatitud,
        -5.9845,
        precision: 10.4,
        velocidad: 11.3 / 3.6,
      ),
    );
    expect(controlador.puntos, hasLength(3));
    expect(controlador.velocidadActual, closeTo(11.3 / 3.6, 0.1));
  });

  test('expone la precisión y avisa de señal débil', () async {
    await iniciarConPunto();
    expect(controlador.precisionActual, 5);
    expect(controlador.senalDebil, isFalse);
    reloj.avanzar(const Duration(seconds: 6));
    expect(controlador.senalDebil, isTrue);
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845, precision: 35));
    expect(controlador.precisionActual, 35);
    expect(controlador.senalDebil, isTrue);
    reloj.avanzar(const Duration(seconds: 1));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 3 / _metroPorGradoLatitud, -5.9845, precision: 5),
    );
    expect(controlador.precisionActual, 5);
    expect(controlador.senalDebil, isFalse);
  });

  test('no inicia si el permiso está denegado', () async {
    ubicacion.permiso = PermisoUbicacion.denegado;
    await controlador.iniciar();
    expect(controlador.estado, EstadoGrabacion.inactivo);
    expect(controlador.mensajeError, isNotNull);
    expect(controlador.puntos, isEmpty);
  });

  test('marca la denegación permanente para ofrecer ajustes', () async {
    ubicacion.permiso = PermisoUbicacion.denegadoSiempre;
    await controlador.iniciar();
    expect(controlador.denegadoSiempre, isTrue);
  });

  test('graba puntos y acumula distancia y tiempo activo', () async {
    await iniciarConPunto();
    expect(controlador.estado, EstadoGrabacion.grabando);
    expect(ubicacion.notificacionesPedidas, 1);
    expect(controlador.puntos, hasLength(1));

    reloj.avanzar(const Duration(seconds: 10));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 80 / _metroPorGradoLatitud, -5.9845, altitud: 14),
    );

    expect(controlador.puntos, hasLength(2));
    expect(controlador.distanciaMetros, closeTo(80, 5));
    expect(controlador.duracionActiva, const Duration(seconds: 10));
    expect(controlador.velocidadMedia, closeTo(8, 1));
    expect(controlador.sinSenal, isFalse);
  });

  test('usa cero como velocidad reportada válida', () async {
    await controlador.iniciar();
    await ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: reloj.ahora(),
        precision: 5,
        velocidad: 0,
      ),
    );
    await ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: reloj.ahora(),
        precision: 5,
        velocidad: 0,
      ),
    );
    reloj.avanzar(const Duration(seconds: 10));
    await ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891 + 80 / _metroPorGradoLatitud,
        longitud: -5.9845,
        tiempo: reloj.ahora(),
        precision: 5,
        velocidad: 0,
      ),
    );
    expect(controlador.velocidadActual, 0);
  });

  test('sin velocidad reportada cae en la derivada', () async {
    await controlador.iniciar();
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845));
    await ubicacion.emitir(_gps(reloj, 37.3891, -5.9845));
    reloj.avanzar(const Duration(seconds: 10));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 80 / _metroPorGradoLatitud, -5.9845),
    );
    expect(controlador.velocidadActual, closeTo(8, 1));
  });

  test('no añade puntos con mala precisión', () async {
    await iniciarConPunto();
    reloj.avanzar(const Duration(seconds: 5));
    await ubicacion.emitir(_gps(reloj, 37.39, -5.98, precision: 150));
    expect(controlador.puntos, hasLength(1));
  });

  test('pausa y reanuda sin contar el tiempo de pausa', () async {
    await iniciarConPunto();
    reloj.avanzar(const Duration(seconds: 10));
    await controlador.pausar();
    expect(controlador.estado, EstadoGrabacion.pausado);
    expect(controlador.duracionActiva, const Duration(seconds: 10));
    final distancia = controlador.distanciaMetros;

    reloj.avanzar(const Duration(minutes: 5));
    expect(controlador.duracionActiva, const Duration(seconds: 10));

    await controlador.reanudar();
    expect(controlador.estado, EstadoGrabacion.grabando);
    reloj.avanzar(const Duration(seconds: 5));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 200 / _metroPorGradoLatitud, -5.9845, altitud: 16),
    );
    expect(controlador.duracionActiva, const Duration(seconds: 15));
    expect(controlador.distanciaMetros, closeTo(distancia, 0.1));
    expect(controlador.puntos.last.segmento, 1);
    expect(controlador.velocidadActual, isNull);

    reloj.avanzar(const Duration(seconds: 5));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 240 / _metroPorGradoLatitud, -5.9845, altitud: 17),
    );
    expect(controlador.duracionActiva, const Duration(seconds: 20));
    expect(controlador.distanciaMetros, closeTo(distancia + 40, 5));
    expect(controlador.puntos.last.segmento, 1);
    expect(controlador.velocidadActual, closeTo(8, 1));
  });

  test(
    'el borrador conserva los segmentos y la reanudación abre otro',
    () async {
      final t0 = DateTime(2026, 11, 20, 17);
      repositorio.borrador = Sesion(
        id: 'borrador-segmentos',
        actividad: Actividad.correr,
        inicio: t0,
        duracionActiva: const Duration(minutes: 2),
        puntos: [
          PuntoRuta(
            latitud: 37.3891,
            longitud: -5.9845,
            tiempo: t0,
            precision: 5,
            segmento: 0,
          ),
          PuntoRuta(
            latitud: 37.3892,
            longitud: -5.9845,
            tiempo: t0.add(const Duration(minutes: 2)),
            precision: 5,
            segmento: 1,
          ),
        ],
      );
      await controlador.inicializar();
      await controlador.recuperarBorrador();
      expect(controlador.puntos.map((p) => p.segmento), [0, 1]);

      await controlador.reanudar();
      reloj.avanzar(const Duration(seconds: 5));
      await ubicacion.emitir(_gps(reloj, 37.3893, -5.9845));
      expect(controlador.puntos.map((p) => p.segmento), [0, 1, 2]);
    },
  );

  test('finaliza y guarda la sesión', () async {
    await iniciarConPunto();
    reloj.avanzar(const Duration(seconds: 20));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 160 / _metroPorGradoLatitud, -5.9845, altitud: 20),
    );

    final sesion = await controlador.finalizar();
    expect(sesion, isNotNull);
    expect(sesion!.puntos, hasLength(2));
    expect(sesion.actividad, Actividad.correr);
    expect(sesion.fin, isNotNull);
    expect(sesion.duracionActiva, const Duration(seconds: 20));
    expect(repositorio.sesiones, hasLength(1));
    expect(repositorio.sesiones.single.id, sesion.id);
    expect(repositorio.borrador, isNull);
    expect(controlador.estado, EstadoGrabacion.inactivo);
    expect(controlador.puntos, isEmpty);
  });

  test('no guarda una sesión sin puntos', () async {
    await controlador.iniciar();
    reloj.avanzar(const Duration(seconds: 5));
    final sesion = await controlador.finalizar();
    expect(sesion, isNull);
    expect(controlador.estado, EstadoGrabacion.inactivo);
    expect(controlador.mensajeError, contains('ninguna posición'));
    expect(repositorio.sesiones, isEmpty);
  });

  test('conserva el borrador si falla el guardado final', () async {
    await iniciarConPunto();
    repositorio.fallarGuardado = true;
    final sesion = await controlador.finalizar();
    expect(sesion, isNull);
    expect(controlador.estado, EstadoGrabacion.error);
    expect(controlador.errorGuardado, isTrue);
    expect(controlador.puntos, hasLength(1));
    expect(repositorio.borrador, isNotNull);
  });

  test('autoguarda el borrador durante la grabación', () async {
    await iniciarConPunto();
    reloj.avanzar(const Duration(seconds: 6));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 10 / _metroPorGradoLatitud, -5.9845),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repositorio.borrador, isNotNull);
    expect(repositorio.borrador!.puntos, isNotEmpty);
  });

  test('recupera un borrador en pausa', () async {
    final borrador = Sesion(
      id: 'borrador',
      actividad: Actividad.bicicleta,
      inicio: DateTime(2026, 11, 20, 17),
      duracionActiva: const Duration(minutes: 12),
      puntos: [
        PuntoRuta(
          latitud: 37.3891,
          longitud: -5.9845,
          tiempo: DateTime(2026, 11, 20, 17),
          precision: 5,
        ),
      ],
    );
    repositorio.borrador = borrador;
    await controlador.inicializar();
    expect(controlador.borrador, isNotNull);

    await controlador.recuperarBorrador();
    expect(controlador.estado, EstadoGrabacion.pausado);
    expect(controlador.actividad, Actividad.bicicleta);
    expect(controlador.puntos, hasLength(1));
    expect(controlador.duracionActiva, const Duration(minutes: 12));
    expect(controlador.borrador, isNull);
  });

  test('descarta el borrador sin tocar las sesiones guardadas', () async {
    final borrador = Sesion(
      id: 'borrador',
      actividad: Actividad.correr,
      inicio: DateTime(2026, 11, 20, 17),
      duracionActiva: const Duration(minutes: 1),
      puntos: const [],
    );
    repositorio.borrador = borrador;
    await controlador.inicializar();
    await controlador.descartarBorrador();
    expect(repositorio.borrador, isNull);
    expect(controlador.borrador, isNull);
  });

  test(
    'un error del stream detiene la grabación y permite reintentar',
    () async {
      await iniciarConPunto();
      reloj.avanzar(const Duration(seconds: 3));
      await ubicacion.emitirError(const FormatException('gps'));
      expect(controlador.estado, EstadoGrabacion.error);
      expect(controlador.puntos, hasLength(1));

      await controlador.reanudar();
      expect(controlador.estado, EstadoGrabacion.grabando);
      reloj.avanzar(const Duration(seconds: 5));
      await ubicacion.emitir(
        _gps(reloj, 37.3891 + 20 / _metroPorGradoLatitud, -5.9845),
      );
      expect(controlador.puntos, hasLength(2));
    },
  );

  test('bloquea el inicio mientras hay un borrador pendiente', () async {
    repositorio.borrador = Sesion(
      id: 'pendiente',
      actividad: Actividad.correr,
      inicio: DateTime(2026, 11, 20, 17),
      duracionActiva: Duration.zero,
      puntos: const [],
    );
    await controlador.inicializar();
    expect(controlador.bloqueadoPorBorrador, isTrue);
    await controlador.iniciar();
    expect(controlador.mensajeError, contains('sesión pendiente'));
    expect(controlador.estado, EstadoGrabacion.inactivo);
  });

  test('sincroniza el servicio de notificación con el estado', () async {
    await iniciarConPunto();
    expect(notificacion.inicios, 1);
    await controlador.pausar();
    expect(notificacion.ultimoPausado, isTrue);
    await controlador.reanudar();
    expect(notificacion.inicios, 2);
    await controlador.finalizar();
    expect(notificacion.detenciones, 1);
  });

  test('avisa si el permiso de notificaciones se deniega', () async {
    ubicacion.notificacionesConcedidas = false;
    await iniciarConPunto();
    expect(controlador.avisoNotificaciones, isTrue);
    expect(controlador.estado, EstadoGrabacion.grabando);
  });

  test('cambia de actividad solo cuando está inactivo', () async {
    controlador.cambiarActividad(Actividad.senderismo);
    expect(controlador.actividad, Actividad.senderismo);
    await controlador.iniciar();
    controlador.cambiarActividad(Actividad.bicicleta);
    expect(controlador.actividad, Actividad.senderismo);
  });
}
