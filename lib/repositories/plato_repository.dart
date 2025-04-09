import '../models/plato.dart';

abstract class PlatoRepository {
  /// Crea un nuevo plato con validación
  Future<Plato> crear(Plato plato);

  /// Obtiene un plato por su ID
  Future<Plato> obtener(String id);

  /// Obtiene todos los platos activos, opcionalmente filtrados por categoría
  Future<List<Plato>> obtenerTodos({String? categoria});

  /// Obtiene múltiples platos por sus IDs
  Future<List<Plato>> obtenerVarios(List<String> ids);

  /// Actualiza un plato existente
  Future<void> actualizar(Plato plato);

  /// Desactiva un plato (soft delete)
  Future<void> desactivar(String id);

  /// Elimina permanentemente un plato
  Future<void> eliminar(String id);

  /// Busca platos por nombre (búsqueda insensible a mayúsculas)
  Future<List<Plato>> buscarPorNombre(String query);

  /// Genera un nuevo código autoincremental para platos (formato PC-001)
  Future<String> generarNuevoCodigo();

  /// Verifica si un código de plato ya existe
  Future<bool> existeCodigo(String codigo);

  /// Obtiene platos por categoría específica
  Future<List<Plato>> obtenerPorCategoria(String categoria);

  /// Obtiene platos que contengan todas las categorías especificadas
  Future<List<Plato>> obtenerPorCategorias(List<String> categorias);

  /// Obtiene la fecha de última actualización del plato
  Future<DateTime?> obtenerFechaActualizacion(String id);
}