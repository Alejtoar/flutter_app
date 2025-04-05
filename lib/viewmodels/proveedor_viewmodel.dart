import 'package:flutter/material.dart';
import '../models/proveedor.dart';
import '../services/proveedor_service.dart';

class ProveedorViewModel with ChangeNotifier {
  final ProveedorService _service;
  List<Proveedor> _proveedores = [];
  bool _loading = false;
  String? _error;
  Proveedor? _proveedorSeleccionado;

  List<Proveedor> get proveedores => _proveedores;
  bool get loading => _loading;
  String? get error => _error;
  Proveedor? get proveedorSeleccionado => _proveedorSeleccionado;

  ProveedorViewModel(this._service);

  // Cargar todos los proveedores
  Future<void> cargarProveedores({List<String>? tiposInsumos}) async {
    _setLoading(true);
    try {
      _proveedores = await _service.obtenerTodos(tiposInsumos: tiposInsumos);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _proveedores = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar un proveedor específico
  Future<void> cargarProveedor(String id) async {
    _setLoading(true);
    try {
      _proveedorSeleccionado = await _service.obtenerProveedor(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _proveedorSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo proveedor
  Future<bool> crearProveedor({
    required String nombre,
    required String telefono,
    required String correo,
    required List<String> tiposInsumos,
  }) async {
    _setLoading(true);
    try {
      final codigo = await _service.generarNuevoCodigo();
      final proveedor = await _service.crearProveedorConValidacion(
        codigo: codigo,
        nombre: nombre,
        telefono: telefono,
        correo: correo,
        tiposInsumos: tiposInsumos,
      );
      
      await _service.crearProveedor(proveedor);
      await cargarProveedores();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar proveedor existente
  Future<bool> actualizarProveedor(Proveedor proveedor) async {
    _setLoading(true);
    try {
      await _service.actualizarProveedor(proveedor);
      await cargarProveedores();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Desactivar proveedor
  Future<bool> desactivarProveedor(String id) async {
    _setLoading(true);
    try {
      await _service.desactivarProveedor(id);
      await cargarProveedores();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buscar proveedores por nombre
  Future<List<Proveedor>> buscarProveedores(String query) async {
    _setLoading(true);
    try {
      final resultados = await _service.buscarProveedoresPorNombre(query);
      _error = null;
      return resultados;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Buscar proveedores por tipo de insumo
  Future<List<Proveedor>> buscarPorTipoInsumo(String tipoInsumo) async {
    _setLoading(true);
    try {
      final resultados = await _service.buscarPorTipoInsumo(tipoInsumo);
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

  // Seleccionar proveedor
  void seleccionarProveedor(Proveedor? proveedor) {
    _proveedorSeleccionado = proveedor;
    notifyListeners();
  }
}