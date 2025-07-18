import '../models/insumo_evento.dart';

abstract class InsumoEventoRepository {
  /// Crea una nueva relación insumo-evento
  Future<InsumoEvento> crear(InsumoEvento relacion, {String? uid});

  /// Obtiene una relación por su ID
  Future<InsumoEvento> obtener(String id, {String? uid});

  /// Actualiza una relación existente
  Future<void> actualizar(InsumoEvento relacion, {String? uid});

  /// Elimina una relación
  Future<void> eliminar(String id, {String? uid});

  /// Obtiene todos los insumos de un evento
  Future<List<InsumoEvento>> obtenerPorEvento(String eventoId, {String? uid});

  /// Obtiene todos los eventos de un insumo
  Future<List<InsumoEvento>> obtenerPorInsumo(String insumoId, {String? uid});

  /// Crea múltiples relaciones en una sola operación atómica
  Future<void> reemplazarInsumosDeEvento(String eventoId, List<InsumoEvento> nuevosInsumos, {String? uid});

  /// Verifica si existe una relación específica
  Future<bool> existeRelacion(String insumoId, String eventoId, {String? uid});

  /// Elimina todas las relaciones de un evento
  Future<void> eliminarPorEvento(String eventoId, {String? uid});
}
