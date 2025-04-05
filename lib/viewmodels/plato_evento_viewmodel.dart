import 'package:flutter/foundation.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/services/plato_evento_service.dart';

class PlatoEventoViewModel extends ChangeNotifier {
  final PlatoEventoService _service;
  
  List<PlatoEvento> _platosEvento = [];
  bool _isLoading = false;
  String? _error;

  PlatoEventoViewModel({PlatoEventoService? service})
      : _service = service ?? PlatoEventoService();

  List<PlatoEvento> get platosEvento => _platosEvento;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarPlatosEvento(String eventoId) async {
    _setLoading(true);
    try {
      _platosEvento = await _service.obtenerPlatosEvento(eventoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platosEvento = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> agregarPlatoEvento(PlatoEvento platoEvento, String eventoId) async {
    _setLoading(true);
    try {
      await _service.crearPlatoEvento(platoEvento, eventoId);
      await cargarPlatosEvento(eventoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarPlatoEvento(
    String eventoId,
    String platoEventoId,
    PlatoEvento platoEvento,
  ) async {
    _setLoading(true);
    try {
      await _service.actualizarPlatoEvento(eventoId, platoEventoId, platoEvento);
      await cargarPlatosEvento(eventoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarPlatoEvento(String eventoId, String platoEventoId) async {
    _setLoading(true);
    try {
      await _service.eliminarPlatoEvento(eventoId, platoEventoId);
      await cargarPlatosEvento(eventoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<PlatoEvento>> buscarPlatosEvento(String eventoId, String query) async {
    _setLoading(true);
    try {
      final resultados = await _service.buscarPlatosEvento(eventoId, query);
      _error = null;
      return resultados;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Cálculos de totales
  double get costoTotal => _platosEvento.fold(
        0,
        (total, plato) => total + plato.costoTotal,
      );

  double get ventaTotal => _platosEvento.fold(
        0,
        (total, plato) => total + plato.ventaTotal,
      );

  double get margenTotal => _platosEvento.fold(
        0,
        (total, plato) => total + plato.margen,
      );

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
