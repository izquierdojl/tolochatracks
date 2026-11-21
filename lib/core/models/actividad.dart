enum Actividad {
  correr('correr', 'Correr', 'running'),
  caminar('caminar', 'Caminar', 'walking'),
  senderismo('senderismo', 'Senderismo', 'hiking'),
  bicicleta('bicicleta', 'Bicicleta', 'cycling'),
  otras('otras', 'Otras', 'other');

  const Actividad(this.clave, this.etiqueta, this.tipoGpx);

  final String clave;
  final String etiqueta;
  final String tipoGpx;

  bool get usaRitmo =>
      this == Actividad.correr ||
      this == Actividad.caminar ||
      this == Actividad.senderismo;

  double get velocidadMaximaPlausible => switch (this) {
    Actividad.correr => 30 / 3.6,
    Actividad.caminar => 12 / 3.6,
    Actividad.senderismo => 15 / 3.6,
    Actividad.bicicleta => 80 / 3.6,
    Actividad.otras => 120 / 3.6,
  };

  static Actividad desdeClave(String? clave) {
    for (final actividad in values) {
      if (actividad.clave == clave) return actividad;
    }
    return Actividad.otras;
  }
}
