import '../models/intermedio_evento.dart';

abstract class IntermedioEventoRepository {
  /// Crea una nueva relación intermedio-evento
  Future<IntermedioEvento> crear(IntermedioEvento relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<IntermedioEvento> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(IntermedioEvento relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los intermedios de un evento
  Future<List<IntermedioEvento>> obtenerPorEvento(String eventoId, {String? uid});

  /// Obtiene todos los eventos de un intermedio
  Future<List<IntermedioEvento>> obtenerPorIntermedio(String intermedioId, {String? uid});

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> reemplazarIntermediosDeEvento(String eventoId, List<IntermedioEvento> nuevosIntermedios, {String? uid});

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String intermedioId, String eventoId, {String? uid});

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId, {String? uid});
}
