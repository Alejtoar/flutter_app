import 'package:flutter/material.dart';
import '../models/costo_produccion.dart';
import '../services/costo_produccion_service.dart';

class CostoProduccionViewModel with ChangeNotifier {
  final CostoProduccionService _service;
  List<CostoProduccion> _costos = [];
  Map<String, double> _estadisticas = {};
  bool _loading = false;
  String? _error;
  CostoProduccion? _costoSeleccionado;

  // Getters
  List<CostoProduccion> get costos => _costos;
  Map<String, double> get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get error => _error;
  CostoProduccion? get costoSeleccionado => _costoSeleccionado;

  CostoProduccionViewModel(this._service);

  // Cargar costos por evento
  Future<void> cargarCostosPorEvento(String eventoId) async {
    _setLoading(true);
    try {
      _costos = await _service.obtenerCostosPorEvento(eventoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _costos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar costos por rango de fechas
  Future<void> cargarCostosPorRango(DateTime inicio, DateTime fin) async {
    _setLoading(true);
    try {
      _costos = await _service.obtenerCostosPorRango(inicio, fin);
      await _cargarEstadisticas(inicio, fin);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _costos = [];
      _estadisticas = {};
    } finally {
      _setLoading(false);
    }
  }

  // Cargar estadísticas
  Future<void> _cargarEstadisticas(DateTime inicio, DateTime fin) async {
    try {
      _estadisticas = await _service.obtenerEstadisticasCostos(inicio, fin);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _estadisticas = {};
    }
  }

  // Cargar un costo específico
  Future<void> cargarCosto(String id) async {
    _setLoading(true);
    try {
      _costoSeleccionado = await _service.obtenerCostoProduccion(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _costoSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo costo
  Future<bool> crearCosto(CostoProduccion costo) async {
    _setLoading(true);
    try {
      final nuevoCosto = await _service.crearCostoProduccion(costo);
      _costos = [nuevoCosto, ..._costos];
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar costo existente
  Future<bool> actualizarCosto(CostoProduccion costo) async {
    _setLoading(true);
    try {
      await _service.actualizarCostoProduccion(costo);
      final index = _costos.indexWhere((c) => c.id == costo.id);
      if (index != -1) {
        _costos[index] = costo;
      }
      if (_costoSeleccionado?.id == costo.id) {
        _costoSeleccionado = costo;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar costo
  void seleccionarCosto(CostoProduccion? costo) {
    _costoSeleccionado = costo;
    notifyListeners();
  }

  // Limpiar selección
  void limpiarSeleccion() {
    _costoSeleccionado = null;
    notifyListeners();
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Helper para manejar el estado de loading
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // Obtener resumen de rentabilidad
  Map<String, double> obtenerResumenRentabilidad() {
    if (_costos.isEmpty) {
      return {
        'costoDirectoPromedio': 0,
        'costoIndirectoPromedio': 0,
        'costosIndirectosPromedio': 0,
        'costoTotalPromedio': 0,
        'ventaPromedio': 0,
        'margenPromedio': 0,
        'rentabilidadPromedio': 0,
      };
    }

    double totalCostoDirecto = 0;
    double totalCostoIndirecto = 0;
    double totalCostosIndirectos = 0;
    double totalCostoTotal = 0;
    double totalVenta = 0;
    double totalMargen = 0;

    for (var costo in _costos) {
      totalCostoDirecto += costo.costoDirecto;
      totalCostoIndirecto += costo.costoIndirecto;
      totalCostosIndirectos += costo.costosIndirectos;
      totalCostoTotal += costo.costoTotal;
      totalVenta += costo.precioVenta;
      totalMargen += costo.margenGanancia;
    }

    return {
      'costoDirectoPromedio': totalCostoDirecto / _costos.length,
      'costoIndirectoPromedio': totalCostoIndirecto / _costos.length,
      'costosIndirectosPromedio': totalCostosIndirectos / _costos.length,
      'costoTotalPromedio': totalCostoTotal / _costos.length,
      'ventaPromedio': totalVenta / _costos.length,
      'margenPromedio': totalMargen / _costos.length,
      'rentabilidadPromedio': totalVenta > 0 ? (totalMargen / totalVenta) * 100 : 0,
    };
  }
}
