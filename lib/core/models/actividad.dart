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

  static Actividad desdeClave(String? clave) {
    for (final actividad in values) {
      if (actividad.clave == clave) return actividad;
    }
    return Actividad.otras;
  }
}
