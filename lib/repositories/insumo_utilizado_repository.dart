import '../models/insumo_utilizado.dart';

abstract class InsumoUtilizadoRepository {
  /// Crea una nueva relación insumo-intermedio
  Future<InsumoUtilizado> crear(InsumoUtilizado relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<InsumoUtilizado> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoUtilizado relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los insumos utilizados por un intermedio
  Future<List<InsumoUtilizado>> obtenerPorIntermedio(String intermedioId, {String? uid});

  /// Obtiene todos los intermedios que usan un insumo específico
  Future<List<InsumoUtilizado>> obtenerPorInsumo(String insumoId, {String? uid});

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> crearMultiples(List<InsumoUtilizado> relaciones, {String? uid});

  /// Actualiza las cantidades de varios insumos para un intermedio
  Future<void> actualizarCantidades(
    String intermedioId, 
    Map<String, double> cantidadesPorInsumo,
    {String? uid}
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String insumoId, String intermedioId, {String? uid});

  /// Elimina todas las relaciones de un intermedio
  Future<void> eliminarPorIntermedio(String intermedioId, {String? uid});
}