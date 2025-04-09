import '../models/insumo_utilizado.dart';

abstract class InsumoUtilizadoRepository {
  /// Crea una nueva relación insumo-intermedio
  Future<InsumoUtilizado> crear(InsumoUtilizado relacion);

  /// Obtiene una relación por su ID
  Future<InsumoUtilizado> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoUtilizado relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los insumos utilizados por un intermedio
  Future<List<InsumoUtilizado>> obtenerPorIntermedio(String intermedioId);

  /// Obtiene todos los intermedios que usan un insumo específico
  Future<List<InsumoUtilizado>> obtenerPorInsumo(String insumoId);

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> crearMultiples(List<InsumoUtilizado> relaciones);

  /// Actualiza las cantidades de varios insumos para un intermedio
  Future<void> actualizarCantidades(
    String intermedioId, 
    Map<String, double> cantidadesPorInsumo
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String insumoId, String intermedioId);

  /// Elimina todas las relaciones de un intermedio
  Future<void> eliminarPorIntermedio(String intermedioId);
}