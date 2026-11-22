import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/proveedor_mapas.dart';
import 'configuracion_controller.dart';

const _urlRepositorio = 'https://github.com/izquierdojl/tolochatracks';

class AcercaDePantalla extends StatefulWidget {
  const AcercaDePantalla({super.key});

  @override
  State<AcercaDePantalla> createState() => _AcercaDePantallaState();
}

class _AcercaDePantallaState extends State<AcercaDePantalla> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  Future<void> _abrir(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final configuracion = context.watch<ConfiguracionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de TolochaTracks')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/tolocha_tracks.svg',
                  width: 72,
                  height: 72,
                ),
                const SizedBox(height: 12),
                Text(
                  'TolochaTracks',
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: _info,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final texto = info == null
                        ? snapshot.hasError
                              ? 'Versión no disponible'
                              : 'Cargando versión…'
                        : 'Versión ${info.version} (${info.buildNumber})';
                    return Text(
                      texto,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: tema.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacidad',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las rutas se guardan únicamente en este dispositivo. No hay '
                    'cuentas, telemetría ni servidores propios. Solo se accede a '
                    'la red para descargar las teselas del mapa que elijas, y los '
                    'mapas se pueden desactivar en Ajustes.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Seccion(titulo: 'Mapas y datos'),
          Card(
            child: Column(
              children: [
                for (final proveedor in ProveedorMapas.values)
                  if (proveedor.activo && proveedor.urlLicencia != null)
                    ListTile(
                      leading: Icon(
                        configuracion.proveedorMapas == proveedor
                            ? Icons.check_circle_outline
                            : Icons.public,
                        color: configuracion.proveedorMapas == proveedor
                            ? tema.colorScheme.primary
                            : null,
                      ),
                      title: Text(proveedor.etiqueta),
                      subtitle: Text(
                        '${proveedor.atribucion}. Datos de OpenStreetMap bajo '
                        'ODbL.',
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _abrir(proveedor.urlLicencia!),
                    ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Repositorio del proyecto'),
                  subtitle: const Text('github.com/izquierdojl/tolochatracks'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrir(_urlRepositorio),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Seccion(titulo: 'Licencias'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.article_outlined),
                  title: Text('Código con licencia MIT'),
                  subtitle: Text(
                    'El código de TolochaTracks se distribuye bajo licencia MIT. '
                    'Consulta el archivo LICENSE del repositorio.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.text_fields),
                  title: Text('Tipografía Inter'),
                  subtitle: Text(
                    'Inter, de Rasmus Andersson, bajo SIL Open Font License 1.1.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.map_outlined),
                  title: Text('Datos de mapas'),
                  subtitle: Text(
                    '© OpenStreetMap contributors (ODbL). OpenTopoMap y CyclOSM '
                    'se atribuyen en el propio mapa.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hecho con Flutter y cariño por las rutas. '
            'TolochaTracks no está afiliado a Google ni a MyTracks.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        titulo.toUpperCase(),
        style: tema.textTheme.labelSmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
