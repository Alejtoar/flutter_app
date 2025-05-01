import '../models/intermedio_evento.dart';

abstract class IntermedioEventoRepository {
  /// Crea una nueva relación intermedio-evento
  Future<IntermedioEvento> crear(IntermedioEvento relacion);

  /// Obtiene una relación por su ID
  Future<IntermedioEvento> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(IntermedioEvento relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los intermedios de un evento
  Future<List<IntermedioEvento>> obtenerPorEvento(String eventoId);

  /// Obtiene todos los eventos de un intermedio
  Future<List<IntermedioEvento>> obtenerPorIntermedio(String intermedioId);

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> reemplazarIntermediosDeEvento(String eventoId, List<IntermedioEvento> nuevosIntermedios);

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String intermedioId, String eventoId);

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId);
}
