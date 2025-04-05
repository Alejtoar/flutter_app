import 'package:flutter/material.dart';
import '../models/plato.dart';
import '../models/intermedio_requerido.dart';
import '../services/plato_service.dart';

class PlatoViewModel with ChangeNotifier {
  bool _mostrarInactivos = false;
  bool get mostrarInactivos => _mostrarInactivos;

  void setMostrarInactivos(bool value) {
    _mostrarInactivos = value;
    cargarPlatos();
    notifyListeners();
  }

  final PlatoService _service;
  List<Plato> _platos = [];
  bool _loading = false;
  String? _error;
  Plato? _platoSeleccionado;
  final Map<String, List<Plato>> _platosPorCategoria = {};

  // Getters
  List<Plato> get platos => _platos;
  bool get loading => _loading;
  String? get error => _error;
  Plato? get platoSeleccionado => _platoSeleccionado;
  Map<String, List<Plato>> get platosPorCategoria => _platosPorCategoria;

  // Getters adicionales para la UI
  List<String> get categorias => Plato.categoriasDisponibles.keys.toList();

  List<IntermedioRequerido> getIntermediosRequeridos(String platoId) {
    final plato = _platos.firstWhere((p) => p.id == platoId);
    return plato.intermedios;
  }

  Map<String, double> getCostoProduccion(String platoId) {
    final plato = _platos.firstWhere((p) => p.id == platoId);
    // TODO: Implementar cálculo real de costos
    return {
      'costoDirecto': 100.0,
      'costoIndirecto': 20.0,
      'costoAdicional': 10.0,
      'costoTotal': plato.costoTotal,
      'precioVenta': plato.precioVenta,
    };
  }

  PlatoViewModel(this._service) {
    cargarPlatos();
  }

  // Cargar todos los platos
  Future<void> cargarPlatos({bool? activo}) async {
    _setLoading(true);
    try {
      _platos = await _service.obtenerTodos(activo: activo);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar platos por categoría
  Future<void> cargarPlatosPorCategoria(List<String> categorias) async {
    _setLoading(true);
    try {
      _platosPorCategoria.clear();
      for (var categoria in categorias) {
        final platos = await _service.obtenerPlatosPorCategoria(categoria);
        _platosPorCategoria[categoria] = platos;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platosPorCategoria.clear();
    } finally {
      _setLoading(false);
    }
  }

  // Cargar un plato específico
  Future<void> cargarPlato(String id) async {
    _setLoading(true);
    try {
      _platoSeleccionado = await _service.obtenerPlato(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platoSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo plato
  Future<bool> crearPlato(Plato plato) async {
    _setLoading(true);
    try {
      final nuevoPlato = await _service.crearPlato(plato);
      _platos = [nuevoPlato, ..._platos];
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

  // Actualizar plato existente
  Future<bool> actualizarPlato(Plato plato) async {
    _setLoading(true);
    try {
      await _service.actualizarPlato(plato);
      final index = _platos.indexWhere((p) => p.id == plato.id);
      if (index != -1) {
        _platos[index] = plato;
      }
      if (_platoSeleccionado?.id == plato.id) {
        _platoSeleccionado = plato;
      }
      _actualizarPlatoEnCategorias(plato);
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

  // Desactivar plato
  Future<bool> desactivarPlato(String id) async {
    _setLoading(true);
    try {
      await _service.desactivarPlato(id);
      _platos.removeWhere((p) => p.id == id);
      if (_platoSeleccionado?.id == id) {
        _platoSeleccionado = null;
      }
      _removerPlatoDeCategorias(id);
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

  // Actualizar costos
  Future<bool> actualizarCostos(String id, double nuevoCosto, double nuevoPrecio) async {
    _setLoading(true);
    try {
      await _service.actualizarCostos(id, nuevoCosto, nuevoPrecio);
      await cargarPlato(id);
      final index = _platos.indexWhere((p) => p.id == id);
      if (index != -1 && _platoSeleccionado != null) {
        _platos[index] = _platoSeleccionado!;
        _actualizarPlatoEnCategorias(_platoSeleccionado!);
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

  // Búsqueda de platos
  Future<void> buscarPlatos(String query) async {
    if (query.isEmpty) {
      await cargarPlatos(activo: true);
      return;
    }

    _setLoading(true);
    try {
      _platos = await _service.buscarPlatos(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _platos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Generar código único
  Future<String> generarCodigo() async {
    try {
      return await _service.generarCodigo();
    } catch (e) {
      _error = e.toString();
      return '';
    }
  }

  // Helpers
  void _actualizarPlatoEnCategorias(Plato plato) {
    for (var categoria in plato.categorias) {
      if (_platosPorCategoria.containsKey(categoria)) {
        final index = _platosPorCategoria[categoria]!.indexWhere((p) => p.id == plato.id);
        if (index != -1) {
          _platosPorCategoria[categoria]![index] = plato;
        }
      }
    }
  }

  void _removerPlatoDeCategorias(String id) {
    for (var categoria in _platosPorCategoria.keys) {
      _platosPorCategoria[categoria]?.removeWhere((p) => p.id == id);
    }
  }

  void seleccionarPlato(Plato? plato) {
    _platoSeleccionado = plato;
    notifyListeners();
  }

  void limpiarSeleccion() {
    _platoSeleccionado = null;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
