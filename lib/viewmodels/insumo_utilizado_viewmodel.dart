import 'package:flutter/material.dart';
import '../models/insumo_utilizado.dart';
import '../services/insumo_utilizado_service.dart';
import '../services/insumo_service.dart';

class InsumoUtilizadoViewModel with ChangeNotifier {
  final InsumoUtilizadoService _service;
  final InsumoService _insumoService;
  List<InsumoUtilizado> _insumosUtilizados = [];
  bool _loading = false;
  String? _error;

  List<InsumoUtilizado> get insumosUtilizados => _insumosUtilizados;
  bool get loading => _loading;
  String? get error => _error;

  InsumoUtilizadoViewModel(this._service, this._insumoService);

  Future<void> cargarDesdeMapas(List<Map<String, dynamic>> insumosData) async {
    _setLoading(true);
    try {
      _insumosUtilizados = await _service.convertirMapasAInsumosUtilizados(insumosData);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar insumos: ${e.toString()}';
      _insumosUtilizados = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<double> calcularCostoTotal() async {
    _setLoading(true);
    try {
      final costo = _service.calcularCostoTotal(_insumosUtilizados);
      _error = null;
      return costo;
    } catch (e) {
      _error = 'Error en cálculo: ${e.toString()}';
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarPrecios() async {
    _setLoading(true);
    try {
      final nuevosInsumos = await Future.wait(
        _insumosUtilizados.map((iu) async {
          final insumo = await _insumoService.obtenerInsumo(iu.insumoId);
          return iu.copyWith(
            precioUnitario: insumo.precioUnitario,
          );
        }),
      );
      
      _insumosUtilizados = nuevosInsumos;
      _error = null;
    } catch (e) {
      _error = 'Error al actualizar precios: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void agregarInsumo(InsumoUtilizado insumo) {
    _insumosUtilizados.add(insumo);
    notifyListeners();
  }

  void removerInsumo(String insumoId) {
    _insumosUtilizados.removeWhere((iu) => iu.insumoId == insumoId);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}