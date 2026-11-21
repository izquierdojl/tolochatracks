import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/core/models/proveedor_mapas.dart';
import 'package:tolochatracks/core/models/punto_ruta.dart';
import 'package:tolochatracks/features/sesiones/ui/widgets/mapa_ruta.dart';
import 'package:tolochatracks/app/theme/app_theme.dart';

void main() {
  testWidgets('sin puntos muestra un aviso y no dibuja el mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: const Scaffold(body: MapaRuta(puntos: [])),
      ),
    );
    await tester.pump();

    expect(find.text('Sin puntos GPS que mostrar'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsNothing);
  });

  testWidgets('con mapas desactivados no dibuja ni pide teselas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: const Scaffold(
          body: MapaRuta(puntos: [], proveedor: ProveedorMapas.ninguno),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Mapas desactivados en Ajustes'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsNothing);
  });

  testWidgets('con puntos muestra la atribución de OpenStreetMap', (
    tester,
  ) async {
    final inicio = DateTime(2026, 11, 20, 18);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: MapaRuta(
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
                tiempo: inicio.add(const Duration(minutes: 10)),
                precision: 5,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('OpenStreetMap · conexión'), findsOneWidget);
  });

  testWidgets('dibuja una polilínea por segmento', (tester) async {
    final inicio = DateTime(2026, 11, 20, 18);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: MapaRuta(
            puntos: [
              PuntoRuta(
                latitud: 37.3891,
                longitud: -5.9845,
                tiempo: inicio,
                precision: 5,
                segmento: 0,
              ),
              PuntoRuta(
                latitud: 37.3895,
                longitud: -5.9845,
                tiempo: inicio.add(const Duration(minutes: 5)),
                precision: 5,
                segmento: 0,
              ),
              PuntoRuta(
                latitud: 37.3899,
                longitud: -5.9845,
                tiempo: inicio.add(const Duration(minutes: 10)),
                precision: 5,
                segmento: 1,
              ),
              PuntoRuta(
                latitud: 37.3903,
                longitud: -5.9845,
                tiempo: inicio.add(const Duration(minutes: 15)),
                precision: 5,
                segmento: 1,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final capa = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(capa.polylines, hasLength(2));
  });
}
