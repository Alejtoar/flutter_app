import 'package:flutter/material.dart';
import '../models/intermedio_requerido.dart';
import '../services/intermedio_requerido_service.dart';

class IntermedioRequeridoViewModel with ChangeNotifier {
  final IntermedioRequeridoService _service;
  List<IntermedioRequerido> _intermediosRequeridos = [];
  bool _loading = false;
  String? _error;
  IntermedioRequerido? _intermedioSeleccionado;

  // Getters
  List<IntermedioRequerido> get intermediosRequeridos => _intermediosRequeridos;
  bool get loading => _loading;
  String? get error => _error;
  IntermedioRequerido? get intermedioSeleccionado => _intermedioSeleccionado;

  IntermedioRequeridoViewModel(this._service);

  // Cargar intermedios requeridos por plato
  Future<void> cargarIntermediosPorPlato(String platoId) async {
    _setLoading(true);
    try {
      _intermediosRequeridos = await _service.obtenerPorPlato(platoId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _intermediosRequeridos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar un intermedio requerido específico
  Future<void> cargarIntermedioRequerido(String id) async {
    _setLoading(true);
    try {
      _intermedioSeleccionado = await _service.obtenerIntermedioRequerido(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _intermedioSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo intermedio requerido
  Future<bool> crearIntermedioRequerido(IntermedioRequerido intermedio) async {
    _setLoading(true);
    try {
      final nuevoIntermedio = await _service.crearIntermedioRequerido(intermedio);
      _intermediosRequeridos = [..._intermediosRequeridos, nuevoIntermedio];
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

  // Actualizar intermedio requerido existente
  Future<bool> actualizarIntermedioRequerido(IntermedioRequerido intermedio) async {
    _setLoading(true);
    try {
      await _service.actualizarIntermedioRequerido(intermedio);
      final index = _intermediosRequeridos.indexWhere((i) => i.id == intermedio.id);
      if (index != -1) {
        _intermediosRequeridos[index] = intermedio;
      }
      if (_intermedioSeleccionado?.id == intermedio.id) {
        _intermedioSeleccionado = intermedio;
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

  // Eliminar intermedio requerido
  Future<bool> eliminarIntermedioRequerido(String id) async {
    _setLoading(true);
    try {
      await _service.eliminarIntermedioRequerido(id);
      _intermediosRequeridos.removeWhere((i) => i.id == id);
      if (_intermedioSeleccionado?.id == id) {
        _intermedioSeleccionado = null;
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

  // Actualizar orden
  Future<bool> actualizarOrden(String id, int nuevoOrden) async {
    try {
      await _service.actualizarOrden(id, nuevoOrden);
      final intermedio = _intermediosRequeridos.firstWhere((i) => i.id == id);
      final actualizado = intermedio.copyWith(orden: nuevoOrden);
      await actualizarIntermedioRequerido(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Actualizar cantidad
  Future<bool> actualizarCantidad(String id, double nuevaCantidad) async {
    try {
      await _service.actualizarCantidad(id, nuevaCantidad);
      final intermedio = _intermediosRequeridos.firstWhere((i) => i.id == id);
      final actualizado = intermedio.copyWith(cantidad: nuevaCantidad);
      await actualizarIntermedioRequerido(actualizado);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Reordenar intermedios
  Future<bool> reordenarIntermedios(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final intermedio = _intermediosRequeridos.removeAt(oldIndex);
      _intermediosRequeridos.insert(newIndex, intermedio);
      
      // Actualizar orden de todos los intermedios afectados
      bool success = true;
      for (var i = 0; i < _intermediosRequeridos.length; i++) {
        final result = await actualizarOrden(_intermediosRequeridos[i].id!, i);
        if (!result) success = false;
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Seleccionar intermedio
  void seleccionarIntermedio(IntermedioRequerido? intermedio) {
    _intermedioSeleccionado = intermedio;
    notifyListeners();
  }

  // Limpiar selección
  void limpiarSeleccion() {
    _intermedioSeleccionado = null;
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
}
