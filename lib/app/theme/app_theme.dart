import 'package:material_ui/material_ui.dart';

abstract final class Paleta {
  static const pine950 = Color(0xFF08100B);
  static const pine900 = Color(0xFF0F1A12);
  static const pine800 = Color(0xFF17291C);
  static const pine700 = Color(0xFF203A28);
  static const pine600 = Color(0xFF2C4F38);
  static const pine500 = Color(0xFF3C6A4D);
  static const pine400 = Color(0xFF5F8F73);
  static const pine300 = Color(0xFF8CB29A);
  static const pine200 = Color(0xFFBCD2C4);
  static const pine100 = Color(0xFFDEEAE2);
  static const pine50 = Color(0xFFF0F5F1);
  static const ochre600 = Color(0xFFA67430);
  static const ochre500 = Color(0xFFC0883E);
  static const ochre400 = Color(0xFFD3A568);
  static const ochre300 = Color(0xFFE2C091);
  static const moss500 = Color(0xFF9AAE63);
  static const moss400 = Color(0xFFB4C47E);
}

@immutable
class ColoresRuta extends ThemeExtension<ColoresRuta> {
  const ColoresRuta({
    required this.ruta,
    required this.inicio,
    required this.fin,
    required this.altitud,
    required this.velocidad,
    required this.ritmo,
  });

  final Color ruta;
  final Color inicio;
  final Color fin;
  final Color altitud;
  final Color velocidad;
  final Color ritmo;

  @override
  ColoresRuta copyWith({
    Color? ruta,
    Color? inicio,
    Color? fin,
    Color? altitud,
    Color? velocidad,
    Color? ritmo,
  }) => ColoresRuta(
    ruta: ruta ?? this.ruta,
    inicio: inicio ?? this.inicio,
    fin: fin ?? this.fin,
    altitud: altitud ?? this.altitud,
    velocidad: velocidad ?? this.velocidad,
    ritmo: ritmo ?? this.ritmo,
  );

  @override
  ColoresRuta lerp(ThemeExtension<ColoresRuta>? other, double t) {
    if (other is! ColoresRuta) return this;
    return ColoresRuta(
      ruta: Color.lerp(ruta, other.ruta, t)!,
      inicio: Color.lerp(inicio, other.inicio, t)!,
      fin: Color.lerp(fin, other.fin, t)!,
      altitud: Color.lerp(altitud, other.altitud, t)!,
      velocidad: Color.lerp(velocidad, other.velocidad, t)!,
      ritmo: Color.lerp(ritmo, other.ritmo, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get oscuro => _construir(Brightness.dark);
  static ThemeData get claro => _construir(Brightness.light);

  static ThemeData _construir(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    final esquema = ColorScheme.fromSeed(
      seedColor: Paleta.ochre500,
      brightness: brillo,
    );
    final superficie = oscuro ? Paleta.pine950 : Paleta.pine50;
    final texto = oscuro ? Paleta.pine100 : Paleta.pine900;
    final colores = esquema.copyWith(
      surface: superficie,
      onSurface: texto,
      surfaceContainer: oscuro ? Paleta.pine900 : Colors.white,
      surfaceContainerHigh: oscuro ? Paleta.pine800 : Paleta.pine100,
      tertiary: oscuro ? Paleta.pine300 : Paleta.pine600,
    );
    return ThemeData(
      colorScheme: colores,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: superficie,
      appBarTheme: AppBarTheme(
        backgroundColor: superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colores.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colores.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colores.surfaceContainer,
        indicatorColor: colores.secondaryContainer,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [
        ColoresRuta(
          ruta: oscuro ? Paleta.moss400 : Paleta.pine600,
          inicio: Paleta.moss500,
          fin: Paleta.ochre400,
          altitud: oscuro ? Paleta.ochre400 : Paleta.ochre600,
          velocidad: oscuro ? Paleta.pine300 : Paleta.pine500,
          ritmo: Paleta.moss500,
        ),
      ],
    );
  }
}

extension ColoresRutaContexto on BuildContext {
  ColoresRuta get coloresRuta => Theme.of(this).extension<ColoresRuta>()!;
}
