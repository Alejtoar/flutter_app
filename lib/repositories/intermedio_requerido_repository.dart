import '../models/intermedio_requerido.dart';

abstract class IntermedioRequeridoRepository {
  /// Crea una nueva relación plato-intermedio
  Future<IntermedioRequerido> crear(IntermedioRequerido relacion);

  /// Obtiene una relación por su ID
  Future<IntermedioRequerido> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(IntermedioRequerido relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los intermedios requeridos por un plato
  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId);

  /// Obtiene todos los platos que requieren un intermedio específico
  Future<List<IntermedioRequerido>> obtenerPorIntermedio(String intermedioId);

  /// Reemplaza completamente los intermedios de un plato
  Future<void> reemplazarIntermediosDePlato(
    String platoId, 
    Map<String, double> nuevosIntermedios
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String intermedioId);

  /// Elimina todas las relaciones de un plato
  Future<void> eliminarPorPlato(String platoId);
}