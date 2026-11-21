import 'package:material_ui/material_ui.dart';

enum SeccionApp {
  grabar('grabar', 'Grabar'),
  historial('historial', 'Historial'),
  configuracion('configuracion', 'Ajustes');

  const SeccionApp(this.clave, this.titulo);

  final String clave;
  final String titulo;

  static SeccionApp desdeClave(String? clave) {
    for (final seccion in values) {
      if (seccion.clave == clave) return seccion;
    }
    return SeccionApp.grabar;
  }

  static IconData icono(SeccionApp seccion) => switch (seccion) {
    SeccionApp.grabar => Icons.fiber_manual_record_outlined,
    SeccionApp.historial => Icons.route_outlined,
    SeccionApp.configuracion => Icons.settings_outlined,
  };
}
