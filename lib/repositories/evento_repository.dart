import '../models/evento.dart';

abstract class EventoRepository {
  /// Crea un nuevo evento
  Future<Evento> crear(Evento evento);

  /// Obtiene un evento por su ID
  Future<Evento> obtener(String id);

  /// Actualiza un evento existente
  Future<void> actualizar(Evento evento);

  /// Elimina un evento
  Future<void> eliminar(String id);

  /// Busca eventos por nombre (case insensitive)
  Future<List<Evento>> buscarPorNombre(String nombre);

  /// Obtiene eventos por tipo
  Future<List<Evento>> obtenerPorTipo(TipoEvento tipo);

  /// Obtiene eventos por estado
  Future<List<Evento>> obtenerPorEstado(EstadoEvento estado);

  /// Obtiene eventos por rango de fechas
  Future<List<Evento>> obtenerPorRangoFechas(DateTime desde, DateTime hasta);

  /// Obtiene todos los eventos activos
  Future<List<Evento>> obtenerTodos();

  /// Verifica si existe un evento con un nombre específico
  Future<bool> existeEventoConNombre(String nombre);

  /// Genera un nuevo código único para eventos (ej: "EV-001")
  Future<String> generarNuevoCodigo();

  /// Obtiene un evento por su código (ej: "EV-001")
  Future<Evento> obtenerPorCodigo(String codigo);

  /// Verifica si un código de evento ya existe
  Future<bool> existeCodigo(String codigo);
}
