import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/calculos/calculos_ruta.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/features/sesiones/ui/historial_controller.dart';

import '../apoyo/falsos.dart';

Sesion sesion(
  String id,
  Actividad actividad,
  DateTime inicio, {
  double metros = 1000,
}) {
  final fin = inicio.add(const Duration(minutes: 30));
  return Sesion(
    id: id,
    actividad: actividad,
    inicio: inicio,
    fin: fin,
    duracionActiva: const Duration(minutes: 29),
    puntos: [
      PuntoRuta(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: inicio,
        altitud: 10,
        precision: 5,
      ),
      PuntoRuta(
        latitud: 37.3891 + metros / 111195.0,
        longitud: -5.9845,
        tiempo: fin,
        altitud: 30,
        precision: 5,
      ),
    ],
  );
}

Sesion sesionConPico() {
  final inicio = DateTime(2026, 11, 20, 18);
  const latitud = 37.3891;
  const longitud = -5.9845;
  const metrosPorGradoLatitud = 111195.0;
  final metrosPorGradoLongitud =
      metrosPorGradoLatitud * cos(latitud * pi / 180);
  PuntoRuta punto(double norte, double este, int segundos) => PuntoRuta(
    latitud: latitud + norte / metrosPorGradoLatitud,
    longitud: longitud + este / metrosPorGradoLongitud,
    tiempo: inicio.add(Duration(seconds: segundos)),
    precision: 5,
  );
  return Sesion(
    id: 'pico',
    actividad: Actividad.caminar,
    inicio: inicio,
    fin: inicio.add(const Duration(seconds: 21)),
    duracionActiva: const Duration(seconds: 21),
    puntos: [
      punto(0, 0, 0),
      punto(30, 0, 1),
      punto(30, 50, 11),
      punto(30, 60, 21),
    ],
  );
}

void main() {
  late RepositorioSesionesFalso repositorio;
  late HistorialController controlador;

  setUp(() {
    repositorio = RepositorioSesionesFalso(
      sesiones: [
        sesion('correr', Actividad.correr, DateTime(2026, 11, 20, 18)),
        sesion('bici', Actividad.bicicleta, DateTime(2026, 11, 19, 18)),
        sesion('andar', Actividad.caminar, DateTime(2026, 11, 18, 18)),
      ],
    );
    controlador = HistorialController(repositorio: repositorio);
  });

  tearDown(() => controlador.dispose());

  test('carga y ordena de la más reciente a la más antigua', () async {
    await controlador.cargar();
    expect(controlador.estado, EstadoHistorial.datos);
    expect(controlador.sesiones.map((s) => s.id), ['correr', 'bici', 'andar']);
  });

  test('filtra por actividad y recalcula los totales', () async {
    await controlador.cargar();
    final distanciaTodas = controlador.distanciaTotalMetros;
    controlador.cambiarFiltro(Actividad.bicicleta);
    expect(controlador.filtro, Actividad.bicicleta);
    expect(controlador.sesionesFiltradas.map((s) => s.id), ['bici']);
    expect(controlador.distanciaTotalMetros, lessThan(distanciaTodas));
    expect(controlador.filtroSinResultados, isFalse);

    controlador.cambiarFiltro(Actividad.senderismo);
    expect(controlador.sesionesFiltradas, isEmpty);
    expect(controlador.filtroSinResultados, isTrue);
    expect(controlador.distanciaTotalMetros, 0);
  });

  test('elimina una sesión, invalida su caché y recalcula', () async {
    await controlador.cargar();
    final bici = controlador.sesiones.firstWhere((s) => s.id == 'bici');
    controlador.estadisticas(bici);
    expect(await controlador.eliminar(bici), isTrue);
    expect(controlador.sesiones.map((s) => s.id), ['correr', 'andar']);
    expect(controlador.distanciaTotalMetros, lessThan(3000));
  });

  test('eliminar la única sesión deja el estado vacío', () async {
    repositorio = RepositorioSesionesFalso(
      sesiones: [sesion('unica', Actividad.correr, DateTime(2026, 11, 20, 18))],
    );
    controlador = HistorialController(repositorio: repositorio);
    await controlador.cargar();
    final unica = controlador.sesiones.single;
    expect(await controlador.eliminar(unica), isTrue);
    expect(controlador.estado, EstadoHistorial.vacio);
    expect(controlador.sesiones, isEmpty);
  });

  test('un error de listado se refleja y se puede reintentar', () async {
    repositorio.fallarListado = true;
    await controlador.cargar();
    expect(controlador.estado, EstadoHistorial.error);
    expect(controlador.error, isNotNull);

    repositorio.fallarListado = false;
    await controlador.cargar();
    expect(controlador.estado, EstadoHistorial.datos);
  });

  test('un error al eliminar conserva la sesión', () async {
    await controlador.cargar();
    repositorio.fallarEliminar = true;
    final sesion = controlador.sesiones.first;
    expect(await controlador.eliminar(sesion), isFalse);
    expect(controlador.sesiones, hasLength(3));
    expect(controlador.error, isNotNull);
  });

  test('marca las sesiones exportadas y conserva las no intentadas', () async {
    await controlador.cargar();

    final guardado = await controlador.actualizarExportadas(
      intentadas: {'correr', 'bici'},
      correctas: {'correr'},
    );

    expect(guardado, isTrue);
    expect(controlador.sesionPorId('correr')!.exportada, isTrue);
    expect(controlador.sesionPorId('bici')!.exportada, isFalse);
    expect(controlador.sesionPorId('andar')!.exportada, isFalse);
    expect(
      repositorio.sesiones
          .firstWhere((sesion) => sesion.id == 'correr')
          .exportada,
      isTrue,
    );
  });

  test('una reexportación fallida desmarca solo las intentadas', () async {
    await controlador.cargar();
    await controlador.actualizarExportadas(
      intentadas: {'correr', 'bici'},
      correctas: {'correr', 'bici'},
    );

    final guardado = await controlador.actualizarExportadas(
      intentadas: {'correr'},
      correctas: {},
    );

    expect(guardado, isTrue);
    expect(controlador.sesionPorId('correr')!.exportada, isFalse);
    expect(controlador.sesionPorId('bici')!.exportada, isTrue);
    expect(controlador.sesionPorId('andar')!.exportada, isFalse);
  });

  test('un fallo al guardar mantiene la marca en memoria y avisa', () async {
    await controlador.cargar();
    repositorio.fallarGuardado = true;

    final guardado = await controlador.actualizarExportadas(
      intentadas: {'correr'},
      correctas: {'correr'},
    );

    expect(guardado, isFalse);
    expect(controlador.sesionPorId('correr')!.exportada, isTrue);
  });

  test('el historial aplica la actividad de la sesión', () async {
    final pico = sesionConPico();
    repositorio = RepositorioSesionesFalso(sesiones: [pico]);
    controlador = HistorialController(repositorio: repositorio);
    await controlador.cargar();

    final historial = controlador.estadisticas(pico).distanciaMetros;
    final comoOtras = calcularEstadisticas(
      pico.puntos,
      duracionActiva: pico.duracionActiva,
      inicio: pico.inicio,
      fin: pico.fin,
      actividad: Actividad.otras,
    ).distanciaMetros;

    expect(historial, lessThan(comoOtras));
  });

  test('historial, detalle y resumen coinciden', () async {
    final pico = sesionConPico();
    repositorio = RepositorioSesionesFalso(sesiones: [pico]);
    controlador = HistorialController(repositorio: repositorio);
    await controlador.cargar();

    final historial = controlador.estadisticas(pico).distanciaMetros;
    final detalle = calcularEstadisticas(
      pico.puntos,
      duracionActiva: pico.duracionActiva,
      inicio: pico.inicio,
      fin: pico.fin,
      actividad: pico.actividad,
    ).distanciaMetros;
    final resumen = calcularEstadisticas(
      pico.puntos,
      duracionActiva: pico.duracionActiva,
      inicio: pico.inicio,
      fin: pico.fin,
      actividad: pico.actividad,
    ).distanciaMetros;

    expect(historial, closeTo(detalle, 0.01));
    expect(resumen, closeTo(historial, 0.01));
  });
}
