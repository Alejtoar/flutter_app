import '../models/insumo.dart';

abstract class InsumoRepository {
  Future<List<Insumo>> obtenerInsumos({String? uid});
  Future<void> eliminarInsumo(String id, {String? uid});

  Future<Insumo> crear(Insumo insumo, {String? uid});
  Future<Insumo> obtener(String id, {String? uid});
  Future<List<Insumo>> obtenerTodos({String? uid});
  Future<List<Insumo>> obtenerVarios(List<String> ids, {String? uid});
  Future<void> actualizar(Insumo insumo, {String? uid});
  Future<void> desactivar(String id, {String? uid});
  Future<List<Insumo>> buscarPorNombre(String query, {String? uid});
  Future<String> generarNuevoCodigo({String? uid});
  Future<void> desactivarPorProveedor(String proveedorId, {String? uid});
  Future<int> contarActivosPorProveedor(String proveedorId, {String? uid});
  Future<Insumo> obtenerPorCodigo(String codigo, {String? uid});

  /// Verifica si un código de insumo ya existe en la base de datos
  /// [codigo]: Código a verificar (ej: "I-001")
  /// Retorna `true` si el código ya existe, `false` si está disponible
  Future<bool> existeCodigo(String codigo, {String? uid});

  // Métodos para filtrar insumos
  Future<List<Insumo>> filtrarInsumosPorCategoria(String categoria, {String? uid});
  Future<List<Insumo>> filtrarInsumosPorCategorias(List<String> categorias, {String? uid});
  Future<List<Insumo>> filtrarInsumosPorProveedor(String proveedorId, {String? uid});
}