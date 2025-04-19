import '../models/insumo_requerido.dart';

abstract class InsumoRequeridoRepository {
  /// Crea una nueva relación plato-insumo
  Future<InsumoRequerido> crear(InsumoRequerido relacion);

  /// Obtiene una relación por su ID
  Future<InsumoRequerido> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoRequerido relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los insumos requeridos por un plato
  Future<List<InsumoRequerido>> obtenerPorPlato(String platoId);

  /// Obtiene todos los platos que requieren un insumo específico
  Future<List<InsumoRequerido>> obtenerPorInsumo(String insumoId);

  /// Reemplaza completamente los insumos de un plato
  Future<void> reemplazarInsumosDePlato(
    String platoId,
    Map<String, double> nuevosInsumos
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String insumoId);

  /// Elimina todas las relaciones de un plato
  Future<void> eliminarPorPlato(String platoId);
}
