import '../models/intermedio.dart';

abstract class IntermedioRepository {
  /// Crea un nuevo intermedio en Firestore
  /// Devuelve el intermedio con el ID asignado
  Future<Intermedio> crear(Intermedio intermedio);

  /// Obtiene un intermedio por su ID
  /// Lanza excepción si no lo encuentra
  Future<Intermedio> obtener(String id);

  /// Obtiene todos los intermedios activos
  /// Opcionalmente filtrados por tipo
  Future<List<Intermedio>> obtenerTodos();

  /// Obtiene múltiples intermedios por sus IDs
  /// Retorna lista vacía si no encuentra ninguno
  Future<List<Intermedio>> obtenerPorIds(List<String> ids);

  /// Actualiza un intermedio existente
  Future<void> actualizar(Intermedio intermedio);

  /// Desactiva un intermedio (soft delete)
  /// Actualiza el campo 'activo' a false
  Future<void> desactivar(String id);

  /// Elimina permanentemente un intermedio
  Future<void> eliminar(String id);

  /// Busca intermedios por nombre (búsqueda insensible a mayúsculas)
  /// Usa RegExp internamente para coincidencias parciales
  Future<List<Intermedio>> buscarPorNombre(String query);

  /// Genera un nuevo código autoincremental para intermedios
  /// Formato: INT-001, INT-002, etc.
  Future<String> generarNuevoCodigo();

  /// Filtra intermedios por tipo
  Future<List<Intermedio>> filtrarPorTipo(String tipo);

  /// Verifica si un código de intermedio ya existe
  Future<bool> existeCodigo(String codigo);

}