import '../models/plato_evento.dart';

abstract class PlatoEventoRepository {
  /// Crea una nueva relación plato-evento
  Future<PlatoEvento> crear(PlatoEvento relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<PlatoEvento> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(PlatoEvento relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los platos de un evento
  Future<List<PlatoEvento>> obtenerPorEvento(String eventoId, {String? uid});

  /// Obtiene todos los eventos de un plato
  Future<List<PlatoEvento>> obtenerPorPlato(String platoId, {String? uid});

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> reemplazarPlatosDeEvento(String eventoId, List<PlatoEvento> nuevosPlatos, {String? uid});

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String eventoId, {String? uid});

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId, {String? uid});
}
