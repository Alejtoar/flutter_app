import '../models/proveedor.dart';

abstract class ProveedorRepository {
  /// Crea un nuevo proveedor con validación
  Future<Proveedor> crear(Proveedor proveedor, {String? uid});

  /// Obtiene un proveedor por su ID
  Future<Proveedor> obtener(String id, {String? uid});

  /// Obtiene todos los proveedores activos
  Future<List<Proveedor>> obtenerTodos({String? uid});

  /// Obtiene proveedores por tipo de insumo
  Future<List<Proveedor>> obtenerPorTipoInsumo(String tipoInsumo, {String? uid});

  /// Actualiza un proveedor existente
  Future<void> actualizar(Proveedor proveedor, {String? uid});

  /// Desactiva un proveedor (soft delete)
  Future<void> desactivar(String id, {String? uid});

  /// Elimina permanentemente un proveedor
  Future<void> eliminar(String id, {String? uid});

  /// Busca proveedores por nombre (búsqueda insensible a mayúsculas)
  Future<List<Proveedor>> buscarPorNombre(String query, {String? uid});

  /// Genera un nuevo código autoincremental para proveedores (formato P-001)
  Future<String> generarNuevoCodigo({String? uid});

  /// Verifica si un código de proveedor ya existe
  Future<bool> existeCodigo(String codigo, {String? uid});

  /// Obtiene proveedores que suministran cierto tipo de insumo
  Future<List<Proveedor>> obtenerPorTiposInsumo(List<String> tipos, {String? uid});

  /// Obtiene la fecha de última actualización del proveedor
  Future<DateTime?> obtenerFechaActualizacion(String id, {String? uid});
}