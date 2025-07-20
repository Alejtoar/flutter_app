// buscador_eventos_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
// Repositorios Principales
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
// Repositorios de Relaciones
import 'package:golo_app/repositories/plato_evento_repository.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';

/// Controlador que gestiona la búsqueda, filtrado y gestión de eventos.
///
/// Este controlador maneja las operaciones CRUD para eventos, incluyendo
/// la gestión de sus relaciones con platos, insumos e intermedios.
/// También se encarga de la generación de códigos únicos para nuevos eventos.
class BuscadorEventosController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _eventoRepository.generarNuevoCodigo(uid: _uid);
  }

  // --- Repositorios ---

  /// Repositorio principal para operaciones CRUD de eventos
  final EventoRepository _eventoRepository;

  /// Repositorio para gestionar la relación entre platos y eventos
  final PlatoEventoRepository _platoEventoRepository;

  /// Repositorio para gestionar la relación entre insumos y eventos
  final InsumoEventoRepository _insumoEventoRepository;

  /// Repositorio para gestionar la relación entre intermedios y eventos
  final IntermedioEventoRepository _intermedioEventoRepository;

  // --- Estado Principal ---

  /// Lista interna de eventos cargados
  List<Evento> _eventos = [];

  /// Lista pública de eventos, puede incluir filtros aplicados
  List<Evento> get eventos => _eventos;

  /// Indica si se está realizando una operación de carga
  bool _loading = false;

  /// Estado de carga actual
  bool get loading => _loading;

  /// Último mensaje de error ocurrido, si existe
  String? _error;

  /// Mensaje de error actual, si existe
  String? get error => _error;

  // --- Estado para Filtros y Búsqueda ---

  /// Texto de búsqueda actual
  String searchText = '';

  /// Filtro de facturación actual
  bool? facturableFiltro;

  /// Filtro de estado de evento actual
  EstadoEvento? estadoFiltro;

  /// Filtro de tipo de evento actual
  TipoEvento? tipoFiltro;

  /// Rango de fechas para filtrar eventos
  DateTimeRange? fechaRangoFiltro;

  // --- Estado para Edición (Relaciones del Evento Seleccionado) ---

  /// Lista de relaciones plato-evento para el evento actual
  List<PlatoEvento> _platosEvento = [];

  /// Obtiene las relaciones plato-evento actuales
  List<PlatoEvento> get platosEvento => _platosEvento;

  /// Lista de relaciones insumo-evento para el evento actual
  List<InsumoEvento> _insumosEvento = [];

  /// Obtiene las relaciones insumo-evento actuales
  List<InsumoEvento> get insumosEvento => _insumosEvento;

  /// Lista de relaciones intermedio-evento para el evento actual
  List<IntermedioEvento> _intermediosEvento = [];

  /// Obtiene las relaciones intermedio-evento actuales
  List<IntermedioEvento> get intermediosEvento => _intermediosEvento;

  // --- Estado para UI (Objetos Base Relacionados al Evento Seleccionado) ---

  /// Lista de platos relacionados con el evento actual
  List<Plato> _platosRelacionados = [];

  /// Obtiene los platos relacionados con el evento actual
  List<Plato> get platosRelacionados => _platosRelacionados;

  /// Lista de intermedios relacionados con el evento actual
  List<Intermedio> _intermediosRelacionados = [];

  /// Obtiene los intermedios relacionados con el evento actual
  List<Intermedio> get intermediosRelacionados => _intermediosRelacionados;

  /// Lista de insumos relacionados con el evento actual
  List<Insumo> _insumosRelacionados = [];

  /// Obtiene los insumos relacionados con el evento actual
  List<Insumo> get insumosRelacionados => _insumosRelacionados;

  // --- Autenticación ---

  /// Instancia de FirebaseAuth para la autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el UID del usuario actualmente autenticado
  String? get _uid => _auth.currentUser?.uid;

  /// Crea una nueva instancia del controlador de búsqueda de eventos
  ///
  /// [eventoRepository] Repositorio para operaciones CRUD de eventos
  /// [platoEventoRepository] Repositorio para gestionar relaciones plato-evento
  /// [insumoEventoRepository] Repositorio para gestionar relaciones insumo-evento
  /// [intermedioEventoRepository] Repositorio para gestionar relaciones intermedio-evento
  BuscadorEventosController(
    this._eventoRepository,
    this._platoEventoRepository,
    this._insumoEventoRepository,
    this._intermedioEventoRepository,
  );

  // --- Métodos CRUD y Carga ---

  /// Carga todos los eventos del usuario actual
  ///
  /// Actualiza la lista interna de eventos y notifica a los listeners.
  /// Maneja automáticamente los estados de carga y errores.
  ///
  /// Lanza una excepción si ocurre un error durante la carga.
  Future<void> cargarEventos() async {
    _setLoading(true);
    try {
      _eventos = await _eventoRepository.obtenerTodos(uid: _uid);
      _clearError();
    } catch (e, st) {
      _setError('Error al cargar eventos: $e', st);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un evento individual y todas sus relaciones de forma atómica
  ///
  /// [id] ID del evento a eliminar
  ///
  /// Retorna `true` si la eliminación fue exitosa, `false` en caso contrario.
  /// Este método es privado y no notifica a los listeners.
  Future<bool> _eliminarUnEventoIndividual(String id) async {
    try {
      // Eliminar relaciones en paralelo para mejorar el rendimiento
      await Future.wait([
        _platoEventoRepository.eliminarPorEvento(id, uid: _uid),
        _insumoEventoRepository.eliminarPorEvento(id, uid: _uid),
        _intermedioEventoRepository.eliminarPorEvento(id, uid: _uid),
      ]);

      // Eliminar el documento principal del evento después de sus relaciones
      await _eventoRepository.eliminar(id, uid: _uid);

      debugPrint(
        "[BuscadorCtrl] Evento $id y sus relaciones eliminados de la BD.",
      );
      return true;
    } catch (e, st) {
      _error = 'Error al eliminar evento $id: $e';
      debugPrint("[BuscadorCtrl][ERROR] $_error\n$st");
      return false;
    }
  }

  /// Elimina un único evento y actualiza la UI
  ///
  /// [id] ID del evento a eliminar
  ///
  /// Este método es el punto de entrada público para eliminar un evento.
  /// Maneja la actualización del estado y notificación a los listeners.
  Future<void> eliminarUnEvento(String id) async {
    _error = null;
    final success = await _eliminarUnEventoIndividual(id);

    if (success) {
      _eventos.removeWhere((e) => e.id == id);
    }

    notifyListeners();
  }

  /// Elimina múltiples eventos en una operación por lotes
  ///
  /// [ids] Conjunto de IDs de eventos a eliminar
  ///
  /// Este método es eficiente para eliminar múltiples eventos a la vez.
  /// Notifica a los listeners una sola vez al finalizar todas las eliminaciones.
  ///
  /// No hace nada si la lista de IDs está vacía.
  Future<void> eliminarEventosEnLote(Set<String> ids) async {
    if (ids.isEmpty) return;
    _error = null;

    // Procesar eliminaciones en paralelo
    final results = await Future.wait(
      ids.map((id) => _eliminarUnEventoIndividual(id)).toList(),
    );

    final int exitoCount = results.where((success) => success).length;
    final int falloCount = ids.length - exitoCount;

    debugPrint(
      "[BuscadorCtrl] Eliminación en lote finalizada. Éxitos: $exitoCount, Fallos: $falloCount",
    );

    if (falloCount > 0) {
      _error = "No se pudieron eliminar $falloCount de ${ids.length} eventos.";
    }

    // Actualizar la lista local solo si hubo eliminaciones exitosas
    if (exitoCount > 0) {
      _eventos.removeWhere((evento) => ids.contains(evento.id));
    }

    notifyListeners();
  }

  /// Crea un nuevo evento junto con todas sus relaciones
  ///
  /// [evento] El evento a crear (sin ID)
  /// [platosEvento] Lista de relaciones plato-evento a crear
  /// [insumosEvento] Lista de relaciones insumo-evento a crear
  /// [intermediosEvento] Lista de relaciones intermedio-evento a crear
  ///
  /// Retorna el evento creado con su ID asignado, o `null` si ocurrió un error.
  ///
  /// Este método maneja la creación atómica de un evento y todas sus relaciones.
  /// Es importante que el evento ya tenga asignado un código único antes de llamar a este método.
  ///
  /// Nota: Este método actualiza el estado de carga y notifica a los listeners.
  Future<Evento?> crearEventoConRelaciones(
    Evento evento,
    List<PlatoEvento> platosEvento,
    List<InsumoEvento> insumosEvento,
    List<IntermedioEvento> intermediosEvento,
  ) async {
    _setLoading(true);
    Evento? eventoCreado;
    try {
      // 1. Crear el evento principal
      eventoCreado = await _eventoRepository.crear(evento, uid: _uid);
      final eventoId = eventoCreado.id!;

      // 2. Crear relaciones en paralelo para mejorar el rendimiento
      await Future.wait([
        _platoEventoRepository.reemplazarPlatosDeEvento(
          eventoId,
          platosEvento,
          uid: _uid,
        ),
        _insumoEventoRepository.reemplazarInsumosDeEvento(
          eventoId,
          insumosEvento,
          uid: _uid,
        ),
        _intermedioEventoRepository.reemplazarIntermediosDeEvento(
          eventoId,
          intermediosEvento,
          uid: _uid,
        ),
      ]);

      // 3. Actualizar estado local
      _eventos.add(eventoCreado); // Añadir a la lista
      _clearError();
      notifyListeners(); // Notificar UI
      return eventoCreado;
    } catch (e, st) {
      _setError('Error al crear evento con relaciones: $e', st);
      // Considerar rollback manual si la creación del evento fue exitosa pero las relaciones fallaron
      // if (eventoCreado?.id != null) {
      //   try { await eventoRepository.eliminar(eventoCreado!.id!); } catch (_) {}
      // }
      return null; // Indicar fallo
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar un evento y sus relaciones usando los métodos `reemplazar...` atómicos.
  Future<bool> actualizarEventoConRelaciones(
    Evento evento, // Evento con ID y datos actualizados
    List<PlatoEvento>
    nuevosPlatosEvento, // Lista COMPLETA y actualizada de relaciones
    List<InsumoEvento> nuevosInsumosEvento,
    List<IntermedioEvento> nuevosIntermediosEvento,
  ) async {
    _setLoading(true);
    if (evento.id == null) {
      _setError("No se puede actualizar un evento sin ID.", null);
      _setLoading(false);
      return false;
    }
    final eventoId = evento.id!;

    try {
      // 1. Actualizar el documento principal del evento
      // El repo se encarga de añadir FieldValue.serverTimestamp() para fechaActualizacion
      await _eventoRepository.actualizar(evento, uid: _uid);

      // 2. Reemplazar atómicamente TODAS las relaciones para este evento
      // Los métodos reemplazar... eliminarán las viejas y añadirán las nuevas en un batch
      await Future.wait([
        _platoEventoRepository.reemplazarPlatosDeEvento(
          eventoId,
          nuevosPlatosEvento,
          uid: _uid,
        ),
        _insumoEventoRepository.reemplazarInsumosDeEvento(
          eventoId,
          nuevosInsumosEvento,
          uid: _uid,
        ),
        _intermedioEventoRepository.reemplazarIntermediosDeEvento(
          eventoId,
          nuevosIntermediosEvento,
          uid: _uid,
        ),
      ]);

      // 3. Actualizar la lista local
      final idx = _eventos.indexWhere((e) => e.id == eventoId);
      if (idx != -1) {
        // Para reflejar la fecha de actualización, obtenemos la del servidor o usamos DateTime.now()
        // Es mejor recargar el evento si quieres la fecha exacta, pero esto es más simple.
        _eventos[idx] = evento.copyWith(
          fechaActualizacion: DateTime.now(),
        ); // Actualización local
      }
      _clearError();
      notifyListeners(); // Notificar UI del éxito y cambio en la lista
      return true; // Indicar éxito
    } catch (e, st) {
      _setError('Error al actualizar evento $eventoId con relaciones: $e', st);
      return false; // Indicar fallo
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar relaciones (PlatoEvento, InsumoEvento, IntermedioEvento) para un evento específico.
  /// Usado típicamente al abrir la pantalla de edición.
  Future<void> cargarRelacionesPorEvento(String eventoId) async {
    _setLoading(
      true,
    ); // Puedes tener un loading específico para relaciones si prefieres
    try {
      // Cargar todas las relaciones en paralelo
      final results = await Future.wait([
        _platoEventoRepository.obtenerPorEvento(eventoId, uid: _uid),
        _insumoEventoRepository.obtenerPorEvento(eventoId, uid: _uid),
        _intermedioEventoRepository.obtenerPorEvento(eventoId, uid: _uid),
      ]);

      _platosEvento = results[0] as List<PlatoEvento>;
      _insumosEvento = results[1] as List<InsumoEvento>;
      _intermediosEvento = results[2] as List<IntermedioEvento>;

      if (kDebugMode) {
        print('Relaciones cargadas para evento $eventoId:');
        print('  Platos: ${_platosEvento.length}');
        print('  Insumos: ${_insumosEvento.length}');
        print('  Intermedios: ${_intermediosEvento.length}');
      }

      _clearError();
      // No notificamos aquí necesariamente, la pantalla de edición puede escuchar directamente
      // los getters (_platosEvento, etc.) o podemos notificar si es necesario.
      // notifyListeners();
    } catch (e, st) {
      _platosEvento = [];
      _insumosEvento = [];
      _intermediosEvento = [];
      _setError('Error al cargar relaciones para evento $eventoId: $e', st);
      // Notificar el error si la UI depende de este estado
      // notifyListeners();
    } finally {
      _setLoading(false); // Desactivar loading general
    }
  }

  /// Obtiene los objetos base (Plato, Intermedio, Insumo) a partir de las relaciones
  /// cargadas previamente con `cargarRelacionesPorEvento`.
  /// Requiere inyectar los repositorios base (PlatoRepository, etc.).
  Future<void> fetchDatosRelacionadosEvento({
    required PlatoRepository
    platoRepository, // Necesita ser inyectado o accesible
    required IntermedioRepository intermedioRepository,
    required InsumoRepository insumoRepository,
  }) async {
    // Asegurarse de que las relaciones (_platosEvento, etc.) estén cargadas
    if (_platosEvento.isEmpty &&
        _intermediosEvento.isEmpty &&
        _insumosEvento.isEmpty) {
      if (kDebugMode) {
        debugPrint('No hay relaciones cargadas para buscar datos base.');
      }
      _platosRelacionados = [];
      _intermediosRelacionados = [];
      _insumosRelacionados = [];
      notifyListeners();
      return;
    }

    // Podríamos añadir un loading específico para esto si es necesario
    // _setLoadingDatosRelacionados(true);

    try {
      // Obtener IDs únicos de las relaciones cargadas
      final platosIds =
          _platosEvento
              .map((pe) => pe.platoId)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
      final intermediosIds =
          _intermediosEvento
              .map((ie) => ie.intermedioId)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
      final insumosIds =
          _insumosEvento
              .map((ie) => ie.insumoId)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

      // Cargar los objetos base en paralelo
      final results = await Future.wait([
        if (platosIds.isNotEmpty)
          platoRepository.obtenerVarios(platosIds, uid: _uid)
        else
          Future.value(<Plato>[]),
        if (intermediosIds.isNotEmpty)
          intermedioRepository.obtenerPorIds(intermediosIds, uid: _uid)
        else
          Future.value(<Intermedio>[]), // Asumiendo que existe obtenerPorIds
        if (insumosIds.isNotEmpty)
          insumoRepository.obtenerVarios(insumosIds, uid: _uid)
        else
          Future.value(<Insumo>[]), // Asumiendo que existe obtenerVarios
      ]);

      _platosRelacionados = results[0] as List<Plato>;
      _intermediosRelacionados = results[1] as List<Intermedio>;
      _insumosRelacionados = results[2] as List<Insumo>;

      if (kDebugMode) {
        print('Datos base relacionados cargados:');
        print('  Platos: ${_platosRelacionados.length}');
        print('  Intermedios: ${_intermediosRelacionados.length}');
        print('  Insumos: ${_insumosRelacionados.length}');
      }
      _clearError(); // Limpiar error si la carga fue exitosa
      notifyListeners(); // Notificar a la UI que los datos base están listos
    } catch (e, st) {
      // Si hay error, limpiar las listas y notificar
      _platosRelacionados = [];
      _intermediosRelacionados = [];
      _insumosRelacionados = [];
      _setError('Error al cargar datos base relacionados: $e', st);
      notifyListeners(); // Notificar el error y las listas vacías
    } finally {
      // _setLoadingDatosRelacionados(false);
    }
  }

  // --- Métodos para Filtros ---

  void setSearchText(String value) {
    if (searchText != value) {
      searchText = value;
      notifyListeners(); // Notificar solo si cambia
    }
  }

  void setFacturableFiltro(bool? value) {
    if (facturableFiltro != value) {
      facturableFiltro = value;
      notifyListeners();
    }
  }

  void setEstadoFiltro(EstadoEvento? value) {
    if (estadoFiltro != value) {
      estadoFiltro = value;
      notifyListeners();
    }
  }

  void setTipoFiltro(TipoEvento? value) {
    if (tipoFiltro != value) {
      tipoFiltro = value;
      notifyListeners();
    }
  }

  void setFechaRangoFiltro(DateTimeRange? value) {
    if (fechaRangoFiltro != value) {
      fechaRangoFiltro = value;
      notifyListeners();
    }
  }

  // --- Helpers Internos ---

  void _setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      Future.microtask(() {
        // <--- DESACOPLAR
        if (hasListeners) notifyListeners();
      });
    }
  }

  void _setError(String message, StackTrace? stackTrace) {
    if (_error != message) {
      _error = message;
      // ... (debugPrint) ...
      Future.microtask(() {
        // <--- DESACOPLAR
        if (hasListeners) notifyListeners();
      });
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      Future.microtask(() {
        // <--- DESACOPLAR
        if (hasListeners) notifyListeners();
      });
    }
  }
}
