import 'package:flutter/material.dart';
import '../models/insumo.dart';
import '../services/insumo_service.dart';

class InsumoViewModel with ChangeNotifier {
  final InsumoService _service;
  List<Insumo> _insumos = [];
  bool _loading = false;
  String? _error;
  Insumo? _insumoSeleccionado;

  List<Insumo> get insumos => _insumos;
  bool get loading => _loading;
  String? get error => _error;
  Insumo? get insumoSeleccionado => _insumoSeleccionado;

  InsumoViewModel(this._service);

  // Cargar todos los insumos
  Future<void> cargarInsumos({String? proveedorId}) async {
    _setLoading(true);
    try {
      _insumos = await _service.obtenerTodos(proveedorId: proveedorId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _insumos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar un insumo específico
  Future<void> cargarInsumo(String id) async {
    _setLoading(true);
    try {
      _insumoSeleccionado = await _service.obtenerInsumo(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _insumoSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo insumo
  Future<bool> crearInsumo({
    required String nombre,
    required String unidad,
    required double precioUnitario,
    required String proveedorId,
  }) async {
    _setLoading(true);
    try {
      final codigo = await _service.generarNuevoCodigo();
      final insumo = await _service.crearInsumoConValidacion(
        codigo: codigo,
        nombre: nombre,
        unidad: unidad,
        precioUnitario: precioUnitario,
        proveedorId: proveedorId,
      );
      
      await _service.crearInsumo(insumo);
      await cargarInsumos();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar insumo existente
  Future<bool> actualizarInsumo(Insumo insumo) async {
    _setLoading(true);
    try {
      await _service.actualizarInsumo(insumo);
      await cargarInsumos();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Desactivar insumo
  Future<bool> desactivarInsumo(String id) async {
    _setLoading(true);
    try {
      await _service.desactivarInsumo(id);
      await cargarInsumos();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buscar insumos por nombre
  Future<List<Insumo>> buscarInsumos(String query) async {
    _setLoading(true);
    try {
      final resultados = await _service.buscarInsumosPorNombre(query);
      _error = null;
      return resultados;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Helper para manejar el estado de loading
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // Limpiar errores
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Seleccionar insumo
  void seleccionarInsumo(Insumo? insumo) {
    _insumoSeleccionado = insumo;
    notifyListeners();
  }
}