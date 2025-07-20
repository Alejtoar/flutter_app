import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';

/// Controlador que gestiona la lógica de negocio para los proveedores.
///
/// Este controlador maneja las operaciones CRUD para los proveedores,
/// así como la búsqueda y filtrado de los mismos.
/// También se encarga de la generación de códigos únicos para nuevos proveedores.
class ProveedorController extends ChangeNotifier {
  // Repositorio para acceder a los datos de proveedores
  final ProveedorRepository _repository;
  
  // Servicio de autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estado de la aplicación
  List<Proveedor> _proveedores = [];
  List<Proveedor> _proveedoresFiltrados = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';

  /// ID del usuario actual
  String? get _uid => _auth.currentUser?.uid;

  /// Lista completa de proveedores
  /// 
  /// Si hay una búsqueda activa, devuelve los proveedores filtrados.
  /// De lo contrario, devuelve todos los proveedores.
  List<Proveedor> get proveedores => 
      _proveedoresFiltrados.isEmpty ? _proveedores : _proveedoresFiltrados;

  /// Indica si se está cargando información
  bool get loading => _loading;

  /// Mensaje de error, si existe
  String? get error => _error;

  /// Término de búsqueda actual
  String get searchQuery => _searchQuery;

  /// Establece el término de búsqueda y notifica a los listeners
  /// 
  /// [value] Término de búsqueda a establecer
  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  /// Crea una nueva instancia del controlador de proveedores
  /// 
  /// [repository] Repositorio para acceder a los datos de proveedores
  ProveedorController(this._repository);

  /// Genera un nuevo código único para un proveedor
  /// 
  /// Retorna un [Future] que se completa con el nuevo código generado
  Future<String> generarNuevoCodigo() async {
    return await _repository.generarNuevoCodigo(uid: _uid);
  }

  /// Carga la lista de proveedores desde el repositorio
  /// 
  /// Actualiza el estado de carga y notifica a los listeners cuando finaliza.
  /// En caso de error, establece el mensaje de error correspondiente.
  Future<void> cargarProveedores() async {
    _loading = true;
    notifyListeners();
    try {
      _proveedores = await _repository.obtenerTodos(uid: _uid);
      _proveedoresFiltrados = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Busca proveedores por nombre
  /// 
  /// [query] Término de búsqueda
  /// 
  /// Actualiza la lista de proveedores filtrados según el término de búsqueda.
  /// Si la consulta está vacía, se limpian los filtros.
  Future<void> buscarProveedoresPorNombre(String query) async {
    try {
      if (query.isEmpty) {
        _proveedoresFiltrados = [];
      } else {
        _proveedoresFiltrados = await _repository.buscarPorNombre(query, uid: _uid);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Crea un nuevo proveedor
  /// 
  /// [proveedor] Proveedor a crear
  /// 
  /// Retorna un [Future] que se completa cuando la operación finaliza.
  /// Actualiza la lista de proveedores después de la creación.
  Future<void> crearProveedor(Proveedor proveedor) async {
    try {
      await _repository.crear(proveedor, uid: _uid);
      await cargarProveedores();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Actualiza un proveedor existente
  /// 
  /// [proveedor] Proveedor con los datos actualizados
  /// 
  /// Retorna un [Future] que se completa cuando la operación finaliza.
  /// Actualiza la lista de proveedores después de la actualización.
  Future<void> actualizarProveedor(Proveedor proveedor) async {
    try {
      await _repository.actualizar(proveedor, uid: _uid);
      await cargarProveedores();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Elimina un proveedor
  /// 
  /// [id] ID del proveedor a eliminar
  /// 
  /// Retorna un [Future] que se completa con `true` si la eliminación fue exitosa,
  /// o `false` en caso contrario.
  /// Actualiza la lista de proveedores después de la eliminación.
  Future<bool> eliminarProveedor(String id) async {
    try {
      await _repository.eliminar(id, uid: _uid);
      await cargarProveedores();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
