import 'package:flutter_test/flutter_test.dart';
import 'package:tolochatracks/main.dart';

void main() {
  testWidgets('el shell arranca en Grabar y permite abrir Historial', (
    tester,
  ) async {
    await tester.pumpWidget(const TolochaTracksApp());
    await tester.pumpAndSettle();

    expect(find.text('Grabación GPS'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('Historial de rutas'), findsOneWidget);
  });

  testWidgets('la cabecera muestra la marca TolochaTracks', (tester) async {
    await tester.pumpWidget(const TolochaTracksApp());
    await tester.pumpAndSettle();

    expect(find.text('TolochaTracks'), findsOneWidget);
  });
}
