import '../models/sesion.dart';

abstract interface class RepositorioSesiones {
  Future<List<Sesion>> listar();
  Future<Sesion?> cargar(String id);
  Future<void> guardar(Sesion sesion);
  Future<void> eliminar(String id);
  Future<void> guardarBorrador(Sesion sesion);
  Future<Sesion?> cargarBorrador();
  Future<void> borrarBorrador();
}
