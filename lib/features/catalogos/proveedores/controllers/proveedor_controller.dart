import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';

class ProveedorController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _repository.generarNuevoCodigo(uid: _uid);
  }
  final ProveedorRepository _repository;
  List<Proveedor> _proveedores = [];
  List<Proveedor> _proveedoresFiltrados = [];
  List<Proveedor> get proveedores => _proveedoresFiltrados.isEmpty ? _proveedores : _proveedoresFiltrados;
  bool _loading = false;
  bool get loading => _loading;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _uid => _auth.currentUser?.uid;

  ProveedorController(this._repository);

  Future<void> cargarProveedores() async {
    _loading = true;
    notifyListeners();
    _proveedores = await _repository.obtenerTodos(uid: _uid);
    _proveedoresFiltrados = [];
    _loading = false;
    notifyListeners();
  }

  Future<void> buscarProveedoresPorNombre(String query) async {
    if (query.isEmpty) {
      _proveedoresFiltrados = [];
    } else {
      _proveedoresFiltrados = await _repository.buscarPorNombre(query, uid: _uid);
    }
    notifyListeners();
  }

  Future<void> crearProveedor(Proveedor proveedor) async {
    await _repository.crear(proveedor, uid: _uid);
    await cargarProveedores();
  }

  Future<void> actualizarProveedor(Proveedor proveedor) async {
    await _repository.actualizar(proveedor, uid: _uid);
    await cargarProveedores();
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await _repository.eliminar(id, uid: _uid);
      await cargarProveedores();
      return true;
    } catch (_) {
      return false;
    }
  }
}
