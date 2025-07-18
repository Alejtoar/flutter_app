//inaumo_controller.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/exceptions/insumo_en_uso_exception.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';

class InsumoController extends ChangeNotifier {
  String? _error;
  String? get error => _error;
  final InsumoRepository _repository;
  final ProveedorRepository _proveedorRepository;
  List<Insumo> _insumos = [];
  bool _loading = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _categoriasFiltro = [];
  String? _proveedorFiltro;
  List<Insumo> _insumosFiltrados = [];

  // Proveedores
  List<Proveedor> _proveedores = [];
  Proveedor? _proveedorSeleccionado;
  List<Proveedor> get proveedores => _proveedores;
  Proveedor? get proveedorSeleccionado => _proveedorSeleccionado;

  List<Insumo> get insumos => _insumos;
  List<Insumo> get insumosFiltrados => _insumosFiltrados;
  bool get loading => _loading;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _uid => _auth.currentUser?.uid;

  InsumoController(this._repository, this._proveedorRepository);

  // Método público para cargar insumos
  Future<void> cargarInsumos() async {
    _loading = true;
    notifyListeners();

    try {
      _insumos = await _repository.obtenerTodos(uid: _uid);
      _insumosFiltrados = _insumos; // Inicializar la lista filtrada
      debugPrint('Insumos cargados: ${_insumos.length}');
    } catch (e) {
      debugPrint('Error al cargar insumos: $e');
      _insumos = [];
      _insumosFiltrados = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Cargar proveedores
  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepository.obtenerTodos(uid: _uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar proveedores: $e');
      _proveedores = [];
      notifyListeners();
    }
  }

  void seleccionarProveedor(Proveedor? proveedor) {
    _proveedorSeleccionado = proveedor;
    notifyListeners();
  }

  // Filtrar insumos por proveedor
  Future<void> filtrarPorProveedor(String? proveedorId) async {
    if (proveedorId == null || proveedorId.isEmpty) {
      await cargarInsumos();
      return;
    }
    try {
      _loading = true;
      notifyListeners();
      _insumosFiltrados = await _repository.filtrarInsumosPorProveedor(
        proveedorId,
        uid: _uid,
      );
    } catch (e) {
      debugPrint('Error al filtrar por proveedor: $e');
      _insumosFiltrados = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Método público para búsqueda con debounce
  void buscarInsumos(
    String query, {
    List<String> categorias = const [],
    String? proveedorId,
  }) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _categoriasFiltro = categorias;
      _proveedorFiltro = proveedorId;
      _aplicarFiltros();
      notifyListeners();
    });
  }

  void _aplicarFiltros() {
    _insumosFiltrados =
        _insumos.where((insumo) {
          final matchNombre =
              _searchQuery.isEmpty ||
              insumo.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchCategorias =
              _categoriasFiltro.isEmpty ||
              insumo.categorias.any((c) => _categoriasFiltro.contains(c));
          final matchProveedor =
              _proveedorFiltro == null ||
              _proveedorFiltro!.isEmpty ||
              insumo.proveedorId == _proveedorFiltro;
          return matchNombre && matchCategorias && matchProveedor;
        }).toList();
  }

  // Método público para eliminar con confirmación (contexto pasado desde UI)
  Future<bool> eliminarInsumo({required String id}) async {
    try {
      await _repository.eliminarInsumo(id, uid: _uid);
      await cargarInsumos();
      _error = null;
      return true;
    } on InsumoEnUsoException catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Métodos públicos para CRUD
  Future<void> crearInsumo(Insumo insumo) async {
    await _repository.crear(insumo, uid: _uid);
    await cargarInsumos();
  }

  Future<void> actualizarInsumo(Insumo insumo) async {
    await _repository.actualizar(insumo, uid: _uid);
    await cargarInsumos();
  }

  Future<String> generarNuevoCodigo() async {
    return await _repository.generarNuevoCodigo(uid: _uid);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
