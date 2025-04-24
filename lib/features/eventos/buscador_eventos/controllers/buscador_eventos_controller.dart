import 'package:flutter/material.dart';
import 'package:golo_app/models/plato_evento.dart';
import '../../../../models/evento.dart';
import '../../../../models/insumo_evento.dart';
import '../../../../models/intermedio_evento.dart';
import '../../../../repositories/evento_repository_impl.dart';
import '../../../../repositories/plato_evento_repository_impl.dart';
import '../../../../repositories/insumo_evento_repository_impl.dart';
import '../../../../repositories/intermedio_evento_repository_impl.dart';

class BuscadorEventosController extends ChangeNotifier {
  // --- Estado principal ---
  List<Evento> _eventos = [];
  List<Evento> get eventos => _eventos;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // Relaciones actuales cargadas para edición
  List<PlatoEvento> _platosEvento = [];
  List<PlatoEvento> get platosEvento => _platosEvento;
  List<InsumoEvento> _insumosEvento = [];
  List<InsumoEvento> get insumosEvento => _insumosEvento;
  List<IntermedioEvento> _intermediosEvento = [];
  List<IntermedioEvento> get intermediosEvento => _intermediosEvento;

  final EventoFirestoreRepository repository;
  final PlatoEventoFirestoreRepository platoEventoRepository;
  final InsumoEventoFirestoreRepository insumoEventoRepository;
  final IntermedioEventoFirestoreRepository intermedioEventoRepository;

  String searchText = '';
  bool? facturableFiltro;
  EstadoEvento? estadoFiltro;
  TipoEvento? tipoFiltro;
  DateTimeRange? fechaRangoFiltro;

  BuscadorEventosController({
    required this.repository,
    required this.platoEventoRepository,
    required this.insumoEventoRepository,
    required this.intermedioEventoRepository,
  });

  Future<void> cargarEventos() async {
    _loading = true;
    notifyListeners();
    try {
      _eventos =
          await repository.obtenerTodos(); // Implementa este método en el repo
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> eliminarEvento(String id) async {
    try {
      await repository.eliminar(id);
      await platoEventoRepository.eliminarPorEvento(id);
      await insumoEventoRepository.eliminarPorEvento(id);
      await intermedioEventoRepository.eliminarPorEvento(id);
      _eventos.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crear un evento y sus relaciones
  Future<Evento?> crearEventoConRelaciones(
    Evento evento,
    List<PlatoEvento> platosEvento,
    List<InsumoEvento> insumosEvento,
    List<IntermedioEvento> intermediosEvento,
  ) async {
    _loading = true;
    notifyListeners();
    try {
      final creado = await repository.crear(evento);
      final platosConId =
          platosEvento.map((p) => p.copyWith(eventoId: creado.id!)).toList();
      final insumosConId =
          insumosEvento.map((i) => i.copyWith(eventoId: creado.id!)).toList();
      final intermediosConId =
          intermediosEvento
              .map((i) => i.copyWith(eventoId: creado.id!))
              .toList();
      await platoEventoRepository.reemplazarPlatosDeEvento(
        creado.id!,
        platosConId,
      );
      await insumoEventoRepository.eliminarPorEvento(creado.id!);
      if (insumosConId.isNotEmpty) {
        await insumoEventoRepository.crearMultiples(insumosConId);
      }
      await intermedioEventoRepository.reemplazarIntermediosDeEvento(
        creado.id!,
        intermediosConId.map((i) => i.intermedioId).toList(),
      );
      _eventos.add(creado);
      _error = null;
      notifyListeners();
      return creado;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Actualizar un evento y sus relaciones
  Future<bool> actualizarEventoConRelaciones(
    Evento evento,
    List<PlatoEvento> nuevosPlatosEvento,
    List<InsumoEvento> nuevosInsumosEvento,
    List<IntermedioEvento> nuevosIntermediosEvento,
  ) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.actualizar(evento);
      await platoEventoRepository.reemplazarPlatosDeEvento(
        evento.id!,
        nuevosPlatosEvento,
      );
      await insumoEventoRepository.eliminarPorEvento(evento.id!);
      if (nuevosInsumosEvento.isNotEmpty) {
        await insumoEventoRepository.crearMultiples(nuevosInsumosEvento);
      }
      await intermedioEventoRepository.reemplazarIntermediosDeEvento(
        evento.id!,
        nuevosIntermediosEvento.map((i) => i.intermedioId).toList(),
      );
      final idx = _eventos.indexWhere((e) => e.id == evento.id);
      if (idx != -1) _eventos[idx] = evento;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cargar relaciones de un evento específico
  Future<void> cargarRelacionesPorEvento(String eventoId) async {
    _loading = true;
    notifyListeners();
    try {
      _platosEvento = await platoEventoRepository.obtenerPorEvento(eventoId);
      _insumosEvento = await insumoEventoRepository.obtenerPorEvento(eventoId);
      _intermediosEvento = await intermedioEventoRepository.obtenerPorEvento(
        eventoId,
      );
      _error = null;
    } catch (e) {
      _platosEvento = [];
      _insumosEvento = [];
      _intermediosEvento = [];
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  void setFacturableFiltro(bool? value) {
    facturableFiltro = value;
    notifyListeners();
  }

  void setEstadoFiltro(EstadoEvento? value) {
    estadoFiltro = value;
    notifyListeners();
  }

  void setTipoFiltro(TipoEvento? value) {
    tipoFiltro = value;
    notifyListeners();
  }

  void setFechaRangoFiltro(DateTimeRange? value) {
    fechaRangoFiltro = value;
    notifyListeners();
  }
}
