import '../models/insumo_evento.dart';

abstract class InsumoEventoRepository {
  /// Crea una nueva relación insumo-evento
  Future<InsumoEvento> crear(InsumoEvento relacion);

  /// Obtiene una relación por su ID
  Future<InsumoEvento> obtener(String id);

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoEvento relacion);

  /// Elimina una relación
  Future<void> eliminar(String id);

  /// Obtiene todos los insumos de un evento
  Future<List<InsumoEvento>> obtenerPorEvento(String eventoId);

  /// Obtiene todos los eventos de un insumo
  Future<List<InsumoEvento>> obtenerPorInsumo(String insumoId);

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> reemplazarInsumosDeEvento(String eventoId, List<InsumoEvento> nuevosInsumos);

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String insumoId, String eventoId);

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId);
}
