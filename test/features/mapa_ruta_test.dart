import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Mapa OSM · conexión'), findsOneWidget);
  });
}
