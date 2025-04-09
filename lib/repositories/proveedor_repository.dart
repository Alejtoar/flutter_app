import '../models/proveedor.dart';

abstract class ProveedorRepository {
  /// Crea un nuevo proveedor con validación
  Future<Proveedor> crear(Proveedor proveedor);

  /// Obtiene un proveedor por su ID
  Future<Proveedor> obtener(String id);

  /// Obtiene todos los proveedores activos
  Future<List<Proveedor>> obtenerTodos();

  /// Obtiene proveedores por tipo de insumo
  Future<List<Proveedor>> obtenerPorTipoInsumo(String tipoInsumo);

  /// Actualiza un proveedor existente
  Future<void> actualizar(Proveedor proveedor);

  /// Desactiva un proveedor (soft delete)
  Future<void> desactivar(String id);

  /// Elimina permanentemente un proveedor
  Future<void> eliminar(String id);

  /// Busca proveedores por nombre (búsqueda insensible a mayúsculas)
  Future<List<Proveedor>> buscarPorNombre(String query);

  /// Genera un nuevo código autoincremental para proveedores (formato P-001)
  Future<String> generarNuevoCodigo();

  /// Verifica si un código de proveedor ya existe
  Future<bool> existeCodigo(String codigo);

  /// Obtiene proveedores que suministran cierto tipo de insumo
  Future<List<Proveedor>> obtenerPorTiposInsumo(List<String> tipos);

  /// Obtiene la fecha de última actualización del proveedor
  Future<DateTime?> obtenerFechaActualizacion(String id);
}