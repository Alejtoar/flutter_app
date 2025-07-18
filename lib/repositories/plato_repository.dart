import '../models/plato.dart';

abstract class PlatoRepository {
  /// Crea un nuevo plato con validación
  Future<Plato> crear(Plato plato, {String? uid});

  /// Obtiene un plato por su ID
  Future<Plato> obtener(String id, {String? uid});

  /// Obtiene todos los platos activos, opcionalmente filtrados por categoría
  Future<List<Plato>> obtenerTodos({String? categoria, String? uid});

  /// Obtiene múltiples platos por sus IDs
  Future<List<Plato>> obtenerVarios(List<String> ids, {String? uid});

  /// Actualiza un plato existente
  Future<void> actualizar(Plato plato, {String? uid});

  /// Desactiva un plato (soft delete)
  Future<void> desactivar(String id, {String? uid});

  /// Elimina permanentemente un plato
  Future<void> eliminar(String id, {String? uid});

  /// Busca platos por nombre (búsqueda insensible a mayúsculas)
  Future<List<Plato>> buscarPorNombre(String query, {String? uid});

  /// Genera un nuevo código autoincremental para platos (formato PC-001)
  Future<String> generarNuevoCodigo({String? uid});

  /// Verifica si un código de plato ya existe
  Future<bool> existeCodigo(String codigo, {String? uid});

  /// Obtiene platos por categoría específica
  Future<List<Plato>> obtenerPorCategoria(String categoria, {String? uid});

  /// Obtiene platos que contengan todas las categorías especificadas
  Future<List<Plato>> obtenerPorCategorias(List<String> categorias, {String? uid});

  /// Obtiene la fecha de última actualización del plato
  Future<DateTime?> obtenerFechaActualizacion(String id, {String? uid});
}