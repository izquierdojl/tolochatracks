import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/actividad.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/core/models/sesion.dart';
import 'package:tolochatracks/core/servicios/ubicacion.dart';
import 'package:tolochatracks/features/grabacion/ui/grabacion_controller.dart';
import 'package:tolochatracks/features/sesiones/ui/historial_controller.dart';
import 'package:tolochatracks/main.dart';

import 'apoyo/falsos.dart';

class ControllersApp {
  ControllersApp({
    required this.historial,
    required this.grabacion,
    required this.repositorio,
    required this.ubicacion,
  });

  final HistorialController historial;
  final GrabacionController grabacion;
  final RepositorioSesionesFalso repositorio;
  final ServicioUbicacionFalso ubicacion;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    grabacion.dispose();
    historial.dispose();
    await ubicacion.cerrar();
  }
}

void main() {
  Future<ControllersApp> bombearApp(
    WidgetTester tester, {
    RepositorioSesionesFalso? repositorio,
    ServicioUbicacionFalso? ubicacion,
  }) async {
    final repo = repositorio ?? RepositorioSesionesFalso();
    final servicio = ubicacion ?? ServicioUbicacionFalso();
    final historial = HistorialController(repositorio: repo);
    final grabacion = GrabacionController(
      ubicacion: servicio,
      repositorio: repo,
      ahora: () => DateTime(2026, 11, 20, 21, 30),
    );
    await historial.cargar();
    await grabacion.inicializar();
    final app = ControllersApp(
      historial: historial,
      grabacion: grabacion,
      repositorio: repo,
      ubicacion: servicio,
    );
    addTearDown(app.dispose);
    await tester.pumpWidget(
      TolochaTracksApp(historial: historial, grabacion: grabacion),
    );
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('el shell arranca en Grabar y permite abrir Historial', (
    tester,
  ) async {
    await bombearApp(tester);

    expect(find.text('Nueva ruta'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay rutas'), findsOneWidget);
  });

  testWidgets('la cabecera muestra la marca TolochaTracks', (tester) async {
    await bombearApp(tester);

    expect(find.text('TolochaTracks'), findsOneWidget);
  });

  testWidgets('el selector de actividad está disponible al empezar', (
    tester,
  ) async {
    await bombearApp(tester);

    expect(find.text('Correr'), findsWidgets);
    expect(find.text('Senderismo'), findsOneWidget);
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('la pantalla pasa a grabando con un punto', (tester) async {
    final app = await bombearApp(tester);

    await tester.ensureVisible(find.text('Empezar'));
    await tester.tap(find.text('Empezar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(app.grabacion.estado, EstadoGrabacion.grabando);
    await app.ubicacion.emitir(
      PuntoGps(
        latitud: 37.3891,
        longitud: -5.9845,
        tiempo: DateTime(2026, 11, 20, 21, 30),
        altitud: 12,
        precision: 5,
      ),
    );
    await tester.pump();
    expect(find.text('Grabando'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(app.grabacion.estado, EstadoGrabacion.grabando);

    expect(find.text('Pausar'), findsOneWidget);
    await tester.ensureVisible(find.text('Pausar'));
    expect(find.text('Finalizar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await app.dispose();
  });

  testWidgets('muestra el borrador pendiente y permite recuperarlo', (
    tester,
  ) async {
    final repositorio = RepositorioSesionesFalso(
      borrador: Sesion(
        id: 'borrador',
        actividad: Actividad.senderismo,
        inicio: DateTime(2026, 11, 20, 18),
        duracionActiva: const Duration(minutes: 25),
        puntos: const [],
      ),
    );
    final app = await bombearApp(tester, repositorio: repositorio);

    expect(find.text('Sesión sin terminar'), findsOneWidget);
    expect(find.text('Recuperar'), findsOneWidget);

    await tester.tap(find.text('Recuperar'));
    await tester.pumpAndSettle();
    expect(app.grabacion.estado, EstadoGrabacion.pausado);
    expect(find.text('En pausa'), findsOneWidget);
  });

  testWidgets('el historial muestra una sesión guardada', (tester) async {
    final inicio = DateTime(2026, 11, 20, 18);
    final sesion = Sesion(
      id: 'sesion',
      actividad: Actividad.correr,
      inicio: inicio,
      fin: inicio.add(const Duration(minutes: 30)),
      duracionActiva: const Duration(minutes: 29),
      puntos: [
        PuntoRuta(
          latitud: 37.3891,
          longitud: -5.9845,
          tiempo: inicio,
          precision: 5,
        ),
        PuntoRuta(
          latitud: 37.3981,
          longitud: -5.9845,
          tiempo: inicio.add(const Duration(minutes: 29)),
          precision: 5,
        ),
      ],
    );
    final repositorio = RepositorioSesionesFalso(sesiones: [sesion]);
    await bombearApp(tester, repositorio: repositorio);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Correr'), findsWidgets);
    expect(find.text('1,0 km'), findsWidgets);
  });

  testWidgets('abre el detalle con las estadísticas de la sesión', (
    tester,
  ) async {
    final inicio = DateTime(2026, 11, 20, 18);
    final sesion = Sesion(
      id: 'detalle',
      actividad: Actividad.senderismo,
      inicio: inicio,
      fin: inicio.add(const Duration(minutes: 40)),
      duracionActiva: const Duration(minutes: 38),
      puntos: [
        PuntoRuta(
          latitud: 37.3891,
          longitud: -5.9845,
          tiempo: inicio,
          altitud: 100,
          precision: 5,
        ),
        PuntoRuta(
          latitud: 37.3981,
          longitud: -5.9845,
          tiempo: inicio.add(const Duration(minutes: 38)),
          altitud: 160,
          precision: 5,
        ),
      ],
    );
    await bombearApp(
      tester,
      repositorio: RepositorioSesionesFalso(sesiones: [sesion]),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('20 nov 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Tiempo activo'), findsOneWidget);
    expect(find.text('Desnivel positivo'), findsOneWidget);
    expect(find.text('Altitud mínima'), findsOneWidget);
    expect(find.byTooltip('Eliminar ruta'), findsOneWidget);
  });

  testWidgets('muestra — cuando la sesión no tiene altitudes', (tester) async {
    final inicio = DateTime(2026, 11, 20, 18);
    final sesion = Sesion(
      id: 'sin-altitud',
      actividad: Actividad.correr,
      inicio: inicio,
      duracionActiva: const Duration(minutes: 20),
      puntos: [
        PuntoRuta(
          latitud: 37.3891,
          longitud: -5.9845,
          tiempo: inicio,
          precision: 5,
        ),
      ],
    );
    await bombearApp(
      tester,
      repositorio: RepositorioSesionesFalso(sesiones: [sesion]),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('20 nov 2026'));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
  });

  testWidgets('elimina una ruta desde el detalle', (tester) async {
    final inicio = DateTime(2026, 11, 20, 18);
    final sesion = Sesion(
      id: 'eliminar',
      actividad: Actividad.correr,
      inicio: inicio,
      duracionActiva: const Duration(minutes: 20),
      puntos: [
        PuntoRuta(
          latitud: 37.3891,
          longitud: -5.9845,
          tiempo: inicio,
          precision: 5,
        ),
      ],
    );
    await bombearApp(
      tester,
      repositorio: RepositorioSesionesFalso(sesiones: [sesion]),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('20 nov 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eliminar ruta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay rutas'), findsOneWidget);
  });
}
