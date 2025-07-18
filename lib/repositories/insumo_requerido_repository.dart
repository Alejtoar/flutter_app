import '../models/insumo_requerido.dart';

abstract class InsumoRequeridoRepository {
  /// Crea una nueva relación plato-insumo
  Future<InsumoRequerido> crear(InsumoRequerido relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<InsumoRequerido> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoRequerido relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los insumos requeridos por un plato
  Future<List<InsumoRequerido>> obtenerPorPlato(String platoId, {String? uid});

  /// Obtiene todos los platos que requieren un insumo específico
  Future<List<InsumoRequerido>> obtenerPorInsumo(String insumoId, {String? uid});

  /// Reemplaza completamente los insumos de un plato
  Future<void> reemplazarInsumosDePlato(
    String platoId,
    Map<String, double> nuevosInsumos,
    {String? uid}
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String insumoId, {String? uid});

  /// Elimina todas las relaciones de un plato
  Future<void> eliminarPorPlato(String platoId, {String? uid});
}
