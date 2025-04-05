import 'package:flutter/material.dart';
import '../models/intermedio.dart';
import '../services/intermedio_service.dart';

class IntermedioViewModel with ChangeNotifier {
  final IntermedioService _service;
  List<Intermedio> _intermedios = [];
  bool _loading = false;
  String? _error;
  Intermedio? _intermedioSeleccionado;

  List<Intermedio> get intermedios => _intermedios;
  bool get loading => _loading;
  String? get error => _error;
  Intermedio? get intermedioSeleccionado => _intermedioSeleccionado;

  IntermedioViewModel(this._service);

  // Cargar todos los intermedios
  Future<void> cargarIntermedios() async {
    _setLoading(true);
    try {
      _intermedios = await _service.obtenerTodos();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _intermedios = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar un intermedio específico
  Future<void> cargarIntermedio(String id) async {
    _setLoading(true);
    try {
      _intermedioSeleccionado = await _service.obtenerIntermedio(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _intermedioSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo intermedio
  Future<bool> crearIntermedio({
    required String nombre,
    required List<Map<String, dynamic>> insumos,
    required List<String> categorias,
    double? reduccionPorcentaje,
    String? receta,
    String? instrucciones,
  }) async {
    _setLoading(true);
    try {
      final intermedio = await _service.crearIntermedioConValidacion(
        nombre: nombre,
        insumosData: insumos,
        categorias: categorias,
        reduccionPorcentaje: reduccionPorcentaje,
        receta: receta,
        instrucciones: instrucciones,
      );
      
      await _service.crearIntermedio(intermedio);
      await cargarIntermedios();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar intermedio existente
  Future<bool> actualizarIntermedio(Intermedio intermedio) async {
    _setLoading(true);
    try {
      await _service.actualizarIntermedio(intermedio);
      await cargarIntermedios();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Desactivar intermedio
  Future<bool> desactivarIntermedio(String id) async {
    _setLoading(true);
    try {
      await _service.desactivarIntermedio(id);
      await cargarIntermedios();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
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

  // Seleccionar intermedio
  void seleccionarIntermedio(Intermedio? intermedio) {
    _intermedioSeleccionado = intermedio;
    notifyListeners();
  }
}