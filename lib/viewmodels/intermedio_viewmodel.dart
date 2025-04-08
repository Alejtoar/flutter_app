import 'package:flutter/material.dart';
import '../models/intermedio.dart';
import '../services/intermedio_service.dart';

class IntermedioViewModel extends ChangeNotifier {
  final IntermedioService _service;
  List<Intermedio> _intermedios = [];
  String? _error;
  bool _loading = false;

  IntermedioViewModel({IntermedioService? service})
      : _service = service ?? IntermedioService();

  List<Intermedio> get intermedios => _intermedios;
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

  Future<bool> crearIntermedio({
    required String codigo,
    required String nombre,
    required List<String> categorias,
    required double reduccionPorcentaje,
    required String receta,
    required int tiempoPreparacionMinutos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    required bool activo,
  }) async {
    try {
      _setLoading(true);
      final intermedio = await _service.crearIntermedioConValidacion(
        codigo: codigo,
        nombre: nombre,
        categorias: categorias,
        reduccionPorcentaje: reduccionPorcentaje,
        receta: receta,
        tiempoPreparacionMinutos: tiempoPreparacionMinutos,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        activo: activo,
      );
      _intermedios.add(intermedio);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarIntermedio(Intermedio intermedio) async {
    try {
      _setLoading(true);
      await _service.actualizarIntermedio(intermedio);
      final index = _intermedios.indexWhere((i) => i.id == intermedio.id);
      if (index != -1) {
        _intermedios[index] = intermedio;
      }
      _error = null;
      notifyListeners();
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
      await _service.eliminarIntermedio(id);
      _intermedios.removeWhere((i) => i.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}