import 'package:flutter/material.dart';
import '../models/intermedio_requerido.dart';
import '../services/intermedio_requerido_service.dart';

class IntermedioRequeridoViewModel extends ChangeNotifier {
  final IntermedioRequeridoService _service;
  List<IntermedioRequerido> _intermedios = [];
  String? _error;
  bool _loading = false;

  IntermedioRequeridoViewModel({IntermedioRequeridoService? service})
      : _service = service ?? IntermedioRequeridoService();

  List<IntermedioRequerido> get intermedios => _intermedios;
  String? get error => _error;
  bool get isLoading => _loading;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> obtenerIntermedios() async {
    try {
      _setLoading(true);
      final stream = _service.obtenerTodos();
      stream.listen((intermedios) {
        _intermedios = intermedios;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<IntermedioRequerido> crearIntermedio(IntermedioRequerido intermedio) async {
    try {
      _setLoading(true);
      final id = await _service.crear(intermedio);
      return intermedio.copyWith(id: id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarIntermedio(IntermedioRequerido intermedio) async {
    try {
      _setLoading(true);
      await _service.actualizar(intermedio.id!, intermedio);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarIntermedio(String id) async {
    try {
      _setLoading(true);
      await _service.eliminar(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarCantidad(IntermedioRequerido intermedio, double nuevaCantidad) async {
    try {
      if (nuevaCantidad <= 0) {
        throw ArgumentError('La cantidad debe ser mayor que cero');
      }
      
      _setLoading(true);
      final actualizado = intermedio.copyWith(cantidad: nuevaCantidad);
      await _service.actualizar(intermedio.id!, actualizado);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<IntermedioRequerido> actualizarOrden(IntermedioRequerido intermedio, int nuevoOrden) async {
    final actualizado = intermedio.copyWith();
    await _service.actualizar(intermedio.id!, actualizado);
    return actualizado;
  }

  Future<bool> reordenarIntermedios(int oldIndex, int newIndex) async {
    try {
      _setLoading(true);
      notifyListeners();

      // Actualizar orden de todos los intermedios afectados
      for (int i = 0; i < _intermedios.length; i++) {
        final intermedio = _intermedios[i];
        final nuevoOrden = i;
        await actualizarOrden(intermedio, nuevoOrden);
      }

      // Actualizar la lista local
      final intermedio = _intermedios.removeAt(oldIndex);
      _intermedios.insert(newIndex, intermedio);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}
