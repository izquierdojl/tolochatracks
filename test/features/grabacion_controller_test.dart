import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
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
}) => PuntoGps(
  latitud: latitud,
  longitud: longitud,
  tiempo: reloj.ahora(),
  altitud: altitud,
  precision: precision,
);

void main() {
  late Reloj reloj;
  late ServicioUbicacionFalso ubicacion;
  late RepositorioSesionesFalso repositorio;
  late ServicioNotificacionRutaFalso notificacion;
  late GrabacionController controlador;

  setUp(() {
    reloj = Reloj(DateTime(2026, 11, 20, 18));
    ubicacion = ServicioUbicacionFalso();
    repositorio = RepositorioSesionesFalso();
    notificacion = ServicioNotificacionRutaFalso();
    controlador = GrabacionController(
      ubicacion: ubicacion,
      repositorio: repositorio,
      notificacion: notificacion,
      ahora: reloj.ahora,
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
  }

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
      _gps(reloj, 37.3891 + 100 / _metroPorGradoLatitud, -5.9845, altitud: 14),
    );

    expect(controlador.puntos, hasLength(2));
    expect(controlador.distanciaMetros, closeTo(100, 5));
    expect(controlador.duracionActiva, const Duration(seconds: 10));
    expect(controlador.velocidadMedia, closeTo(10, 1));
    expect(controlador.sinSenal, isFalse);
  });

  test('calcula la velocidad actual si el GPS la envía a cero', () async {
    await ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: reloj.ahora(),
        precision: 5,
        velocidad: 0,
      ),
    );
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
    reloj.avanzar(const Duration(seconds: 10));
    await ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891 + 100 / _metroPorGradoLatitud,
        longitud: -5.9845,
        tiempo: reloj.ahora(),
        precision: 5,
        velocidad: 0,
      ),
    );
    expect(controlador.velocidadActual, closeTo(10, 1));
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
      _gps(reloj, 37.3891 + 250 / _metroPorGradoLatitud, -5.9845, altitud: 17),
    );
    expect(controlador.duracionActiva, const Duration(seconds: 20));
    expect(controlador.distanciaMetros, closeTo(distancia + 50, 5));
    expect(controlador.puntos.last.segmento, 1);
    expect(controlador.velocidadActual, closeTo(10, 1));
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
      reloj.avanzar(const Duration(seconds: 3));
      await ubicacion.emitir(_gps(reloj, 37.3893, -5.9845));
      expect(controlador.puntos.map((p) => p.segmento), [0, 1, 2]);
    },
  );

  test('finaliza y guarda la sesión', () async {
    await iniciarConPunto();
    reloj.avanzar(const Duration(seconds: 20));
    await ubicacion.emitir(
      _gps(reloj, 37.3891 + 300 / _metroPorGradoLatitud, -5.9845, altitud: 20),
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
      reloj.avanzar(const Duration(seconds: 2));
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
