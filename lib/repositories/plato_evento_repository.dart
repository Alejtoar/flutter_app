import '../models/plato_evento.dart';

abstract class PlatoEventoRepository {
  /// Crea una nueva relación plato-evento
  Future<PlatoEvento> crear(PlatoEvento relacion);

  /// Obtiene una relación por su ID
  Future<PlatoEvento> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(PlatoEvento relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los platos de un evento
  Future<List<PlatoEvento>> obtenerPorEvento(String eventoId);

  /// Obtiene todos los eventos de un plato
  Future<List<PlatoEvento>> obtenerPorPlato(String platoId);

  /// Reemplaza completamente los platos de un evento
  Future<void> reemplazarPlatosDeEvento(
    String eventoId, 
    List<String> nuevosPlatosIds
  );

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String platoId, String eventoId);

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId);
}
