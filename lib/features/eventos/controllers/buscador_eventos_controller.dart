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
import 'package:golo_app/repositories/plato_repository.dart'; // Asegúrate que la interfaz abstracta exista
import 'package:golo_app/repositories/intermedio_repository.dart'; // Asegúrate que la interfaz abstracta exista
import 'package:golo_app/repositories/insumo_repository.dart'; // Asegúrate que la interfaz abstracta exista
// Repositorios de Relaciones (usaremos las implementaciones directamente aquí)
import 'package:golo_app/repositories/plato_evento_repository.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';


class BuscadorEventosController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _eventoRepository.generarNuevoCodigo(uid: _uid);
  }

  // --- Repositorios ---
  final EventoRepository _eventoRepository; // Repositorio principal
  // Repositorios de Relaciones
  final PlatoEventoRepository _platoEventoRepository;
  final InsumoEventoRepository _insumoEventoRepository;
  final IntermedioEventoRepository _intermedioEventoRepository;

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _uid => _auth.currentUser?.uid;

  // --- Constructor ---
  BuscadorEventosController(
    this._eventoRepository,
    this._platoEventoRepository,
    this._insumoEventoRepository,
    this._intermedioEventoRepository,
  );

  // --- Métodos CRUD y Carga ---

  Future<void> cargarEventos() async {
    _setLoading(true);
    try {
      _eventos = await _eventoRepository.obtenerTodos(uid: _uid);
      _clearError();
    } catch (e, st) {
      _setError('Error al cargar eventos: $e', st);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _eliminarUnEventoIndividual(String id) async {
    try {
      // Usar Future.wait para eliminar relaciones en paralelo.
      // Cada uno de estos métodos ya usa un batch de Firestore, por lo que son eficientes.
      await Future.wait([
        _platoEventoRepository.eliminarPorEvento(id, uid: _uid),
        _insumoEventoRepository.eliminarPorEvento(id, uid: _uid),
        _intermedioEventoRepository.eliminarPorEvento(id, uid: _uid),
      ]);

      // Eliminar el documento principal del evento DESPUÉS de sus relaciones
      await _eventoRepository.eliminar(id, uid: _uid);

      debugPrint(
        "[BuscadorCtrl] Evento $id y sus relaciones eliminados de la BD.",
      );
      return true;
    } catch (e, st) {
      // Guardar el error para poder mostrarlo en la UI
      _error = 'Error al eliminar evento $id: $e';
      debugPrint("[BuscadorCtrl][ERROR] $_error\n$st");
      return false; // Indicar que esta eliminación específica falló
    }
  }

  /// Método PÚBLICO para eliminar un solo evento desde la UI. Notifica.
  Future<void> eliminarUnEvento(String id) async {
    _error = null; // Limpiar error anterior
    final success = await _eliminarUnEventoIndividual(id);

    if (success) {
      // Si la eliminación en la BD fue exitosa, quitarlo de la lista local
      _eventos.removeWhere((e) => e.id == id);
    }

    // Notificar siempre para que la UI se actualice, ya sea para quitar el item
    // o para mostrar un posible error que se haya guardado en _error.
    notifyListeners();
  }

  /// Método PÚBLICO para eliminar MÚLTIPLES eventos en lote. Notifica una vez al final.
  Future<void> eliminarEventosEnLote(Set<String> ids) async {
    if (ids.isEmpty) return;
    _error = null;

    // Llama al método de eliminación individual para cada ID y espera a que todos terminen
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

    // Actualizar la lista local _eventos quitando todos los que se intentaron eliminar
    // (o podrías quitar solo los exitosos si lo prefieres, pero esto limpia la selección)
    if (exitoCount > 0) {
      // Solo modificar la lista si algo se borró
      _eventos.removeWhere((evento) => ids.contains(evento.id));
    }

    // Notificar a la UI UNA SOLA VEZ con el estado final
    notifyListeners();
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

      eventoCreado = await _eventoRepository.crear(evento, uid: _uid);
      final eventoId = eventoCreado.id!; // ¡Importante! Usar el ID asignado

      // 2. Reemplazar (añadir) las relaciones de forma atómica
      // Los métodos reemplazar... manejarán la creación ya que no hay relaciones previas
      await Future.wait([
        _platoEventoRepository.reemplazarPlatosDeEvento(eventoId, platosEvento, uid: _uid),
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
