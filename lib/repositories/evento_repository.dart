import '../models/evento.dart';

abstract class EventoRepository {
  /// Crea un nuevo evento
  Future<Evento> crear(Evento evento, {String? uid} );

  /// Obtiene un evento por su ID
  Future<Evento> obtener(String id, {String? uid});

  /// Actualiza un evento existente
  Future<void> actualizar(Evento evento, {String? uid});

  /// Elimina un evento
  Future<void> eliminar(String id, {String? uid});

  /// Busca eventos por nombre (case insensitive)
  Future<List<Evento>> buscarPorNombre(String nombre, {String? uid});

  /// Obtiene eventos por tipo
  Future<List<Evento>> obtenerPorTipo(TipoEvento tipo, {String? uid});

  /// Obtiene eventos por estado
  Future<List<Evento>> obtenerPorEstado(EstadoEvento estado, {String? uid});

  /// Obtiene eventos por rango de fechas
  Future<List<Evento>> obtenerPorRangoFechas(DateTime desde, DateTime hasta, {String? uid});

  /// Obtiene todos los eventos activos
  Future<List<Evento>> obtenerTodos({String? uid});

  /// Verifica si existe un evento con un nombre específico
  Future<bool> existeEventoConNombre(String nombre, {String? uid});

  /// Genera un nuevo código único para eventos (ej: "EV-001")
  Future<String> generarNuevoCodigo({String? uid});

  /// Obtiene un evento por su código (ej: "EV-001")
  Future<Evento> obtenerPorCodigo(String codigo, {String? uid});

  /// Verifica si un código de evento ya existe
  Future<bool> existeCodigo(String codigo, {String? uid});
}
