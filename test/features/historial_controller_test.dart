import 'package:flutter_test/flutter_test.dart';
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
}
