import 'package:flutter/foundation.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/services/plato_evento_service.dart';
import 'package:golo_app/services/plato_service.dart';

class PlatoEventoViewModel extends ChangeNotifier {
  final PlatoEventoService _platoEventoService;
  final PlatoService _platoService;
  
  List<PlatoEvento> _platosEvento = [];
  List<Plato> _platos = [];
  bool _isLoading = false;
  String? _error;

  PlatoEventoViewModel({PlatoEventoService? platoEventoService, PlatoService? platoService})
      : _platoEventoService = platoEventoService ?? PlatoEventoService(),
        _platoService = platoService ?? PlatoService();

  List<PlatoEvento> get platosEvento => _platosEvento;
  List<Plato> get platos => _platos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarPlatosEvento(String eventoId) async {
    _setLoading(true);
    try {
      _platosEvento = await _platoEventoService.obtenerPlatosEvento(eventoId);
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
      await _platoEventoService.crearPlatoEvento(platoEvento, eventoId);
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
      await _platoEventoService.actualizarPlatoEvento(eventoId, platoEventoId, platoEvento);
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
      await _platoEventoService.eliminarPlatoEvento(eventoId, platoEventoId);
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
      final resultados = await _platoEventoService.buscarPlatosEvento(eventoId, query);
      _error = null;
      return resultados;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cargarPlatos() async {
    _setLoading(true);
    try {
      _platos = await _platoService.obtenerPlatos();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cálculos de totales
  double calcularCostoTotal(String eventoId) {
    final platosEvento = _platosEvento.where((p) => p.eventoId == eventoId).toList();
    double total = 0;
    for (var platoEvento in platosEvento) {
      final plato = _platos.firstWhere(
        (p) => p.id == platoEvento.platoId,
        orElse: () => throw Exception('Plato no encontrado'),
      );
      total += plato.costoPorcion * platoEvento.cantidad;
    }
    return total;
  }

  double calcularVentaTotal(String eventoId) {
    final platosEvento = _platosEvento.where((p) => p.eventoId == eventoId).toList();
    double total = 0;
    for (var platoEvento in platosEvento) {
      final plato = _platos.firstWhere(
        (p) => p.id == platoEvento.platoId,
        orElse: () => throw Exception('Plato no encontrado'),
      );
      total += plato.precioVenta * platoEvento.cantidad;
    }
    return total;
  }

  double calcularMargen(String eventoId) {
    final costoTotal = calcularCostoTotal(eventoId);
    final ventaTotal = calcularVentaTotal(eventoId);
    return costoTotal > 0 ? 100 * (ventaTotal - costoTotal) / costoTotal : 0;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
