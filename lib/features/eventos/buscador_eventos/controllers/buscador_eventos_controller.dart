// buscador_eventos_controller.dart
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
import 'package:golo_app/repositories/evento_repository_impl.dart';
import 'package:golo_app/repositories/plato_repository.dart'; // Asegúrate que la interfaz abstracta exista
import 'package:golo_app/repositories/intermedio_repository.dart'; // Asegúrate que la interfaz abstracta exista
import 'package:golo_app/repositories/insumo_repository.dart'; // Asegúrate que la interfaz abstracta exista
// Repositorios de Relaciones (usaremos las implementaciones directamente aquí)
import 'package:golo_app/repositories/plato_evento_repository_impl.dart';
import 'package:golo_app/repositories/insumo_evento_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_evento_repository_impl.dart';

class BuscadorEventosController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await eventoRepository.generarNuevoCodigo();
  }

  // --- Repositorios ---
  final EventoFirestoreRepository eventoRepository; // Repositorio principal
  // Repositorios de Relaciones
  final PlatoEventoFirestoreRepository platoEventoRepository;
  final InsumoEventoFirestoreRepository insumoEventoRepository;
  final IntermedioEventoFirestoreRepository intermedioEventoRepository;
  // Repositorios para obtener datos base (Plato, Insumo, Intermedio) - Inyectar si es necesario
  // final PlatoRepository _platoRepository;
  // final IntermedioRepository _intermedioRepository;
  // final InsumoRepository _insumoRepository;

  // --- Estado Principal ---
  List<Evento> _eventos = [];
  List<Evento> get eventos => _eventos; // Lista completa de eventos cargados

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // --- Estado para Filtros y Búsqueda ---
  String searchText = '';
  bool? facturableFiltro;
  EstadoEvento? estadoFiltro;
  TipoEvento? tipoFiltro;
  DateTimeRange? fechaRangoFiltro;

  // --- Estado para Edición (Relaciones del Evento Seleccionado) ---
  List<PlatoEvento> _platosEvento = [];
  List<PlatoEvento> get platosEvento => _platosEvento;

  List<InsumoEvento> _insumosEvento = [];
  List<InsumoEvento> get insumosEvento => _insumosEvento;

  List<IntermedioEvento> _intermediosEvento = [];
  List<IntermedioEvento> get intermediosEvento => _intermediosEvento;

  // --- Estado para UI (Objetos Base Relacionados al Evento Seleccionado) ---
  List<Plato> _platosRelacionados = [];
  List<Plato> get platosRelacionados => _platosRelacionados;

  List<Intermedio> _intermediosRelacionados = [];
  List<Intermedio> get intermediosRelacionados => _intermediosRelacionados;

  List<Insumo> _insumosRelacionados = [];
  List<Insumo> get insumosRelacionados => _insumosRelacionados;

  // --- Constructor ---
  BuscadorEventosController({
    required this.eventoRepository,
    required this.platoEventoRepository,
    required this.insumoEventoRepository,
    required this.intermedioEventoRepository,
    // Descomenta y requiere estos si usas fetchDatosRelacionadosEvento
    // required PlatoRepository platoRepository,
    // required IntermedioRepository intermedioRepository,
    // required InsumoRepository insumoRepository,
  }) /* : _platoRepository = platoRepository, // Asignar si se inyectan
         _intermedioRepository = intermedioRepository,
         _insumoRepository = insumoRepository */;

  // --- Métodos CRUD y Carga ---

  Future<void> cargarEventos() async {
    _setLoading(true);
    try {
      _eventos = await eventoRepository.obtenerTodos();
      _clearError();
    } catch (e, st) {
      _setError('Error al cargar eventos: $e', st);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarEvento(String id) async {
    // No establecer loading aquí para que la UI no parpadee por una operación rápida
    try {
      // Eliminar el evento principal
      await eventoRepository.eliminar(id);

      // Eliminar relaciones asociadas (en paralelo si es posible y seguro)
      // Usar los métodos eliminarPorEvento que usan batch internamente
      await Future.wait([
        platoEventoRepository.eliminarPorEvento(id),
        insumoEventoRepository.eliminarPorEvento(id),
        intermedioEventoRepository.eliminarPorEvento(id),
      ]);

      // Actualizar la lista local
      _eventos.removeWhere((e) => e.id == id);
      _clearError();
      notifyListeners(); // Notificar cambio en la lista
    } catch (e, st) {
      _setError('Error al eliminar evento $id: $e', st);
      // No notificamos aquí para no ocultar el error inmediatamente
    }
  }

  /// Crear un evento y sus relaciones usando los métodos `reemplazar...` atómicos.
  Future<Evento?> crearEventoConRelaciones(
    Evento evento, // Evento sin ID, listo para crear
    List<PlatoEvento> platosEvento, // Relaciones a crear
    List<InsumoEvento> insumosEvento,
    List<IntermedioEvento> intermediosEvento,
  ) async {
    _setLoading(true);
    Evento? eventoCreado; // Para almacenar el evento con su ID
    try {
      // 1. Crear el evento principal para obtener su ID
      // Asegurarse de que venga con código generado si es necesario
      // final eventoConCodigo = evento.codigo.isEmpty
      //     ? evento.copyWith(codigo: await eventoRepository.generarNuevoCodigo())
      //     : evento;
      // El código se genera ANTES de llamar a este método ahora.

      eventoCreado = await eventoRepository.crear(evento);
      final eventoId = eventoCreado.id!; // ¡Importante! Usar el ID asignado

      // 2. Reemplazar (añadir) las relaciones de forma atómica
      // Los métodos reemplazar... manejarán la creación ya que no hay relaciones previas
      await Future.wait([
        platoEventoRepository.reemplazarPlatosDeEvento(eventoId, platosEvento),
        insumoEventoRepository.reemplazarInsumosDeEvento(
          eventoId,
          insumosEvento,
        ),
        intermedioEventoRepository.reemplazarIntermediosDeEvento(
          eventoId,
          intermediosEvento,
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
      await eventoRepository.actualizar(evento);

      // 2. Reemplazar atómicamente TODAS las relaciones para este evento
      // Los métodos reemplazar... eliminarán las viejas y añadirán las nuevas en un batch
      await Future.wait([
        platoEventoRepository.reemplazarPlatosDeEvento(
          eventoId,
          nuevosPlatosEvento,
        ),
        insumoEventoRepository.reemplazarInsumosDeEvento(
          eventoId,
          nuevosInsumosEvento,
        ),
        intermedioEventoRepository.reemplazarIntermediosDeEvento(
          eventoId,
          nuevosIntermediosEvento,
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
        platoEventoRepository.obtenerPorEvento(eventoId),
        insumoEventoRepository.obtenerPorEvento(eventoId),
        intermedioEventoRepository.obtenerPorEvento(eventoId),
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
      if (kDebugMode)
        print('No hay relaciones cargadas para buscar datos base.');
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
          platoRepository.obtenerVarios(platosIds)
        else
          Future.value(<Plato>[]),
        if (intermediosIds.isNotEmpty)
          intermedioRepository.obtenerPorIds(intermediosIds)
        else
          Future.value(<Intermedio>[]), // Asumiendo que existe obtenerPorIds
        if (insumosIds.isNotEmpty)
          insumoRepository.obtenerVarios(insumosIds)
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
