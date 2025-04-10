import '../models/insumo.dart';

abstract class InsumoRepository {
  Future<List<Insumo>> obtenerInsumos();
  Future<void> eliminarInsumo(String id);

  Future<Insumo> crear(Insumo insumo);
  Future<Insumo> obtener(String id);
  Future<List<Insumo>> obtenerTodos({String? proveedorId});
  Future<List<Insumo>> obtenerVarios(List<String> ids);
  Future<void> actualizar(Insumo insumo);
  Future<void> desactivar(String id);
  Future<List<Insumo>> buscarPorNombre(String query);
  Future<String> generarNuevoCodigo();
  Future<void> desactivarPorProveedor(String proveedorId);
  Future<int> contarActivosPorProveedor(String proveedorId);
  Future<Insumo> obtenerPorCodigo(String codigo);

  /// Verifica si un código de insumo ya existe en la base de datos
  /// [codigo]: Código a verificar (ej: "I-001")
  /// Retorna `true` si el código ya existe, `false` si está disponible
  Future<bool> existeCodigo(String codigo);

  // Métodos para filtrar insumos
  Future<List<Insumo>> filtrarInsumosPorCategoria(String categoria);
  Future<List<Insumo>> filtrarInsumosPorCategorias(List<String> categorias);
  Future<List<Insumo>> filtrarInsumosPorProveedor(String proveedorId);
}