import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/exceptions/insumo_en_uso_exception.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';

/// Controlador que gestiona la lógica de negocio para los insumos.
/// 
/// Este controlador se encarga de gestionar las operaciones CRUD para los insumos,
/// así como la lógica de filtrado y búsqueda. También maneja la relación con
/// los proveedores de los insumos.
class InsumoController extends ChangeNotifier {
  // Estado de error
  String? _error;
  
  /// Mensaje de error, si lo hay
  String? get error => _error;
  
  // Repositorios
  final InsumoRepository _repository;
  final ProveedorRepository _proveedorRepository;
  
  // Listas de datos
  List<Insumo> _insumos = [];
  List<Insumo> _insumosFiltrados = [];
  List<Proveedor> _proveedores = [];
  
  // Estado de carga
  bool _loading = false;
  
  // Filtros y búsqueda
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _categoriasFiltro = [];
  String? _proveedorFiltro;
  
  // Proveedores
  Proveedor? _proveedorSeleccionado;
  
  // Getters públicos
  
  /// Lista de todos los proveedores disponibles
  List<Proveedor> get proveedores => _proveedores;
  
  /// Proveedor actualmente seleccionado
  Proveedor? get proveedorSeleccionado => _proveedorSeleccionado;
  
  /// Lista completa de insumos
  List<Insumo> get insumos => _insumos;
  
  /// Lista de insumos filtrados según los criterios de búsqueda
  List<Insumo> get insumosFiltrados => _insumosFiltrados;
  
  /// Indica si se está cargando información
  bool get loading => _loading;
  
  // Autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// ID del usuario actual
  String? get _uid => _auth.currentUser?.uid;

  /// Crea una nueva instancia del controlador de insumos
  /// 
  /// [repository] Repositorio para acceder a los datos de insumos
  /// [proveedorRepository] Repositorio para acceder a los datos de proveedores
  InsumoController(this._repository, this._proveedorRepository);

  /// Carga todos los insumos del usuario actual desde el repositorio
  /// 
  /// Actualiza el estado de carga y notifica a los listeners cuando finaliza.
  /// En caso de error, limpia las listas de insumos y muestra un mensaje de depuración.
  Future<void> cargarInsumos() async {
    _loading = true;
    notifyListeners();

    try {
      _insumos = await _repository.obtenerTodos(uid: _uid);
      _insumosFiltrados = _insumos;
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

  /// Carga todos los proveedores disponibles para el usuario actual
  /// 
  /// Actualiza la lista de proveedores y notifica a los listeners.
  /// En caso de error, limpia la lista de proveedores.
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

  /// Establece el proveedor seleccionado actualmente
  /// 
  /// [proveedor] El proveedor a seleccionar, o null para deseleccionar
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
