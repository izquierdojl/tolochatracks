enum ProveedorMapas {
  osm(
    clave: 'osm',
    etiqueta: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxNativeZoom: 19,
    atribucion: '© OpenStreetMap contributors',
    urlLicencia: 'https://www.openstreetmap.org/copyright',
  ),
  openTopoMap(
    clave: 'topo',
    etiqueta: 'OpenTopoMap',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdominios: ['a', 'b', 'c'],
    maxNativeZoom: 17,
    atribucion: '© OpenTopoMap · © OpenStreetMap contributors',
    urlLicencia: 'https://opentopomap.org/about',
  ),
  cyclosm(
    clave: 'cyclosm',
    etiqueta: 'CyclOSM',
    urlTemplate:
        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    subdominios: ['a', 'b', 'c'],
    maxNativeZoom: 19,
    atribucion: '© CyclOSM · © OpenStreetMap contributors',
    urlLicencia: 'https://www.cyclosm.org',
  ),
  ninguno(
    clave: 'ninguno',
    etiqueta: 'Sin mapas',
    urlTemplate: null,
    maxNativeZoom: 0,
    atribucion: 'Mapas desactivados',
    urlLicencia: null,
  );

  const ProveedorMapas({
    required this.clave,
    required this.etiqueta,
    required this.urlTemplate,
    required this.maxNativeZoom,
    required this.atribucion,
    required this.urlLicencia,
    this.subdominios = const [],
  });

  final String clave;
  final String etiqueta;
  final String? urlTemplate;
  final List<String> subdominios;
  final int maxNativeZoom;
  final String atribucion;
  final String? urlLicencia;

  bool get activo => urlTemplate != null;

  static ProveedorMapas desdeClave(Object? clave) {
    for (final proveedor in values) {
      if (proveedor.clave == clave) return proveedor;
    }
    return ProveedorMapas.osm;
  }
}
