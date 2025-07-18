import '../models/intermedio_requerido.dart';

abstract class IntermedioRequeridoRepository {
  /// Crea una nueva relación plato-intermedio
  Future<IntermedioRequerido> crear(IntermedioRequerido relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<IntermedioRequerido> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(IntermedioRequerido relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los intermedios requeridos por un plato
  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId, {String? uid});

  /// Obtiene todos los platos que requieren un intermedio específico
  Future<List<IntermedioRequerido>> obtenerPorIntermedio(String intermedioId, {String? uid});

  /// Reemplaza completamente los intermedios de un plato
  Future<void> reemplazarIntermediosDePlato(
    String platoId, 
    Map<String, double> nuevosIntermedios, {String? uid}
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String intermedioId, {String? uid});

  /// Elimina todas las relaciones de un plato
  Future<void> eliminarPorPlato(String platoId, {String? uid});
}