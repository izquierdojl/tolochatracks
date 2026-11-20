import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/data/repositorio_sesiones.dart';
import '../../../core/models/sesion.dart';

class SesionesRepositorio implements RepositorioSesiones {
  SesionesRepositorio({
    this.directorioBase,
    this.nombreCarpeta = 'sesiones',
    this.nombreBorrador = 'borrador.json',
  });

  final Directory? directorioBase;
  final String nombreCarpeta;
  final String nombreBorrador;
  Future<Directory>? _carpetaCache;

  Future<Directory> _carpeta() {
    return _carpetaCache ??= _resolverCarpeta();
  }

  Future<Directory> _resolverCarpeta() async {
    final base = directorioBase ?? await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(base.path, nombreCarpeta));
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return carpeta;
  }

  File _archivoSesion(Directory carpeta, String id) {
    final seguro = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File(p.join(carpeta.path, '$seguro.json'));
  }

  File _archivoBorrador(Directory carpeta) {
    return File(p.join(carpeta.path, nombreBorrador));
  }

  Future<void> _escribirAtomico(File destino, String contenido) async {
    final temporal = File('${destino.path}.tmp');
    await temporal.writeAsString(contenido, flush: true);
    if (await destino.exists()) {
      await destino.delete();
    }
    await temporal.rename(destino.path);
  }

  @override
  Future<List<Sesion>> listar() async {
    final carpeta = await _carpeta();
    final sesiones = <Sesion>[];
    await for (final entrada in carpeta.list()) {
      if (entrada is! File) continue;
      final nombre = p.basename(entrada.path);
      if (!nombre.endsWith('.json') || nombre == nombreBorrador) continue;
      try {
        final texto = await entrada.readAsString();
        final json = jsonDecode(texto);
        if (json is Map) {
          sesiones.add(Sesion.desdeJson(Map<String, Object?>.from(json)));
        }
      } on Object {
        continue;
      }
    }
    sesiones.sort((a, b) => b.inicio.compareTo(a.inicio));
    return sesiones;
  }

  @override
  Future<Sesion?> cargar(String id) async {
    final carpeta = await _carpeta();
    final archivo = _archivoSesion(carpeta, id);
    if (!await archivo.exists()) return null;
    try {
      final json = jsonDecode(await archivo.readAsString());
      if (json is! Map) return null;
      return Sesion.desdeJson(Map<String, Object?>.from(json));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> guardar(Sesion sesion) async {
    final carpeta = await _carpeta();
    final archivo = _archivoSesion(carpeta, sesion.id);
    await _escribirAtomico(archivo, jsonEncode(sesion.aJson()));
  }

  @override
  Future<void> eliminar(String id) async {
    final carpeta = await _carpeta();
    final archivo = _archivoSesion(carpeta, id);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  }

  @override
  Future<void> guardarBorrador(Sesion sesion) async {
    final carpeta = await _carpeta();
    await _escribirAtomico(
      _archivoBorrador(carpeta),
      jsonEncode(sesion.aJson()),
    );
  }

  @override
  Future<Sesion?> cargarBorrador() async {
    final carpeta = await _carpeta();
    final archivo = _archivoBorrador(carpeta);
    if (!await archivo.exists()) return null;
    try {
      final json = jsonDecode(await archivo.readAsString());
      if (json is! Map) return null;
      return Sesion.desdeJson(Map<String, Object?>.from(json));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> borrarBorrador() async {
    final carpeta = await _carpeta();
    final archivo = _archivoBorrador(carpeta);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  }
}
