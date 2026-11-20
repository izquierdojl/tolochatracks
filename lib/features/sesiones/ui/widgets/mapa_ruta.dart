import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/proveedor_mapas.dart';
import '../../../../core/models/punto_ruta.dart';

const _paqueteApp = 'com.izquierdojl.tolochatracks';

class MapaRuta extends StatefulWidget {
  const MapaRuta({
    super.key,
    required this.puntos,
    this.altura = 260,
    this.seguir = false,
    this.proveedor = ProveedorMapas.osm,
  });

  final List<PuntoRuta> puntos;
  final double altura;
  final bool seguir;
  final ProveedorMapas proveedor;

  @override
  State<MapaRuta> createState() => _MapaRutaState();
}

class _MapaRutaState extends State<MapaRuta> {
  final MapController _controlador = MapController();

  List<LatLng> get _coordenadas => [
    for (final punto in widget.puntos) LatLng(punto.latitud, punto.longitud),
  ];

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapaRuta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.puntos.length == oldWidget.puntos.length) return;
    if (widget.puntos.isEmpty || !widget.seguir) return;
    final ultimo = _coordenadas.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controlador.move(ultimo, 16);
    });
  }

  void _ajustarVista() {
    final coordenadas = _coordenadas;
    if (coordenadas.isEmpty) return;
    if (coordenadas.length == 1) {
      _controlador.move(coordenadas.first, 16);
      return;
    }
    _controlador.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(coordenadas),
        padding: const EdgeInsets.all(28),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _abrirCopyright() async {
    final url = widget.proveedor.urlLicencia;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      // Si no hay navegador, la atribución sigue visible en el mapa.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (!widget.proveedor.activo) {
      return Container(
        height: widget.altura,
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 36,
                color: tema.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Mapas desactivados en Ajustes',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (widget.puntos.isEmpty) {
      return Container(
        height: widget.altura,
        decoration: BoxDecoration(
          color: tema.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 36,
                color: tema.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Sin puntos GPS que mostrar',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final coordenadas = _coordenadas;
    final colores = context.coloresRuta;
    final inicio = coordenadas.first;
    final fin = coordenadas.last;
    final marcadores = <Marker>[
      Marker(
        point: inicio,
        width: 32,
        height: 32,
        child: _Marcador(
          color: colores.inicio,
          icono: Icons.play_arrow_rounded,
        ),
      ),
      if (widget.seguir && coordenadas.length > 1)
        Marker(
          point: fin,
          width: 36,
          height: 36,
          child: _Marcador(color: colores.fin, icono: Icons.my_location),
        )
      else if (!widget.seguir && coordenadas.length > 1)
        Marker(
          point: fin,
          width: 34,
          height: 34,
          child: _Marcador(color: colores.fin, icono: Icons.flag),
        ),
    ];

    return SizedBox(
      height: widget.altura,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controlador,
              options: MapOptions(
                initialCenter: inicio,
                initialZoom: coordenadas.length > 1 ? 14 : 16,
                minZoom: 2,
                maxZoom: 19,
                backgroundColor: tema.colorScheme.surfaceContainerHigh,
                onMapReady: _ajustarVista,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: widget.proveedor.urlTemplate!,
                  subdomains: widget.proveedor.subdominios,
                  userAgentPackageName: _paqueteApp,
                  maxNativeZoom: widget.proveedor.maxNativeZoom,
                ),
                if (coordenadas.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: coordenadas,
                        strokeWidth: 4.5,
                        color: colores.ruta,
                        borderStrokeWidth: 1.5,
                        borderColor: tema.colorScheme.surface,
                      ),
                    ],
                  ),
                MarkerLayer(markers: marcadores),
              ],
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: _EtiquetaMapa(
                        texto: '${widget.proveedor.etiqueta} · conexión',
                        icono: Icons.wifi_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: tema.colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _abrirCopyright,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          widget.proveedor.atribucion,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.color, required this.icono});

  final Color color;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.26),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icono,
        size: 18,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class _EtiquetaMapa extends StatelessWidget {
  const _EtiquetaMapa({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: tema.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.labelSmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
