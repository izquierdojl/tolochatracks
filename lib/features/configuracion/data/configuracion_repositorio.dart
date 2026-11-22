import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/configuracion_parciales.dart';
import '../../../core/models/perfil_gps.dart';
import '../../../core/models/proveedor_mapas.dart';

class Ajustes {
  const Ajustes({
    this.tema = ThemeMode.system,
    this.proveedorMapas = ProveedorMapas.osm,
    this.perfilGps = PerfilGps.equilibrada,
    this.parciales = ConfiguracionParciales.porDefecto,
    this.directorioExportacionUri,
    this.directorioExportacionNombre,
  });

  final ThemeMode tema;
  final ProveedorMapas proveedorMapas;
  final PerfilGps perfilGps;
  final ConfiguracionParciales parciales;
  final String? directorioExportacionUri;
  final String? directorioExportacionNombre;

  Ajustes copyWith({
    ThemeMode? tema,
    ProveedorMapas? proveedorMapas,
    PerfilGps? perfilGps,
    ConfiguracionParciales? parciales,
    String? directorioExportacionUri,
    String? directorioExportacionNombre,
    bool limpiarDirectorio = false,
  }) => Ajustes(
    tema: tema ?? this.tema,
    proveedorMapas: proveedorMapas ?? this.proveedorMapas,
    perfilGps: perfilGps ?? this.perfilGps,
    parciales: parciales ?? this.parciales,
    directorioExportacionUri: limpiarDirectorio
        ? null
        : directorioExportacionUri ?? this.directorioExportacionUri,
    directorioExportacionNombre: limpiarDirectorio
        ? null
        : directorioExportacionNombre ?? this.directorioExportacionNombre,
  );
}

class ConfiguracionRepositorio {
  static const claveTema = 'config.tema';
  static const claveMapa = 'config.mapa';
  static const clavePerfilGps = 'config.gps.perfil';
  static const claveParcialesModo = 'config.parciales.modo';
  static const claveParcialesValor = 'config.parciales.valor';
  static const claveDirectorioUri = 'config.directorioExportacion.uri';
  static const claveDirectorioNombre = 'config.directorioExportacion.nombre';

  Future<Ajustes> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return Ajustes(
      tema: _leerTema(prefs.get(claveTema)),
      proveedorMapas: ProveedorMapas.desdeClave(prefs.get(claveMapa)),
      perfilGps: PerfilGps.desdeClave(prefs.getString(clavePerfilGps)),
      parciales: ConfiguracionParciales.desdeClaves(
        prefs.getString(claveParcialesModo),
        prefs.get(claveParcialesValor),
      ),
      directorioExportacionUri: prefs.get(claveDirectorioUri) is String
          ? prefs.get(claveDirectorioUri) as String
          : null,
      directorioExportacionNombre: prefs.get(claveDirectorioNombre) is String
          ? prefs.get(claveDirectorioNombre) as String
          : null,
    );
  }

  Future<void> guardar(Ajustes ajustes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(claveTema, _claveTema(ajustes.tema));
    await prefs.setString(claveMapa, ajustes.proveedorMapas.clave);
    await prefs.setString(clavePerfilGps, ajustes.perfilGps.clave);
    await prefs.setString(claveParcialesModo, ajustes.parciales.modo.name);
    await prefs.setInt(claveParcialesValor, ajustes.parciales.valor);
    final uri = ajustes.directorioExportacionUri;
    final nombre = ajustes.directorioExportacionNombre;
    if (uri == null || uri.isEmpty) {
      await prefs.remove(claveDirectorioUri);
      await prefs.remove(claveDirectorioNombre);
    } else {
      await prefs.setString(claveDirectorioUri, uri);
      if (nombre != null) {
        await prefs.setString(claveDirectorioNombre, nombre);
      }
    }
  }

  static ThemeMode _leerTema(Object? valor) => switch (valor) {
    'claro' => ThemeMode.light,
    'oscuro' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _claveTema(ThemeMode tema) => switch (tema) {
    ThemeMode.system => 'sistema',
    ThemeMode.light => 'claro',
    ThemeMode.dark => 'oscuro',
  };
}
