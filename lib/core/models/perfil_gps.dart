enum CalidadGps { alta, media }

enum PerfilGps {
  ahorro(
    clave: 'ahorro',
    etiqueta: 'Ahorro',
    descripcion:
        'Un punto cada 5 s y posiciones de hasta 40 m. Menos detalle y, '
        'previsiblemente, menos consumo.',
    intervalo: Duration(seconds: 5),
    distanciaMinima: 10,
    precisionMaxima: 40,
    calidad: CalidadGps.media,
  ),
  equilibrada(
    clave: 'equilibrada',
    etiqueta: 'Equilibrada',
    descripcion:
        'Un punto cada 2 s y posiciones de hasta 30 m. La opción '
        'recomendada para la mayoría de rutas.',
    intervalo: Duration(seconds: 2),
    distanciaMinima: 3,
    precisionMaxima: 30,
    calidad: CalidadGps.alta,
  ),
  maxima(
    clave: 'maxima',
    etiqueta: 'Máxima',
    descripcion:
        'Un punto por segundo y posiciones de hasta 20 m. Más detalle y más '
        'consumo de batería.',
    intervalo: Duration(seconds: 1),
    distanciaMinima: 1,
    precisionMaxima: 20,
    calidad: CalidadGps.alta,
  );

  const PerfilGps({
    required this.clave,
    required this.etiqueta,
    required this.descripcion,
    required this.intervalo,
    required this.distanciaMinima,
    required this.precisionMaxima,
    required this.calidad,
  });

  final String clave;
  final String etiqueta;
  final String descripcion;
  final Duration intervalo;
  final int distanciaMinima;
  final double precisionMaxima;
  final CalidadGps calidad;

  static PerfilGps desdeClave(String? clave) {
    for (final perfil in values) {
      if (perfil.clave == clave) return perfil;
    }
    return PerfilGps.equilibrada;
  }
}
