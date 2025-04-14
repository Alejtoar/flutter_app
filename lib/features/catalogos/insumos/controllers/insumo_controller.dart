import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/repositories/insumo_repository.dart';

class InsumoController extends ChangeNotifier {
  final InsumoRepository _repository;
  List<Insumo> _insumos = [];
  List<Insumo> _filteredInsumos = [];
  bool _loading = false;
  String? _error;

  InsumoController(this._repository);

  List<Insumo> get insumos => _filteredInsumos;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadInsumos() async {
    try {
      _setLoading(true);
      _insumos = await _repository.obtenerTodos();
      _filteredInsumos = List.from(_insumos);
    } catch (e) {
      _setError('Error al cargar insumos: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteInsumo(String id) async {
    try {
      _setLoading(true);
      await _repository.eliminarInsumo(id);
      await loadInsumos();
      return true;
    } catch (e) {
      _setError('Error al eliminar insumo: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  void filterInsumos(String query) {
    _filteredInsumos = _insumos
        .where((i) => i.nombre.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  Future<void> saveInsumo(Insumo insumo) async {
    try {
      _setLoading(true);
      if (insumo.id == null || insumo.id!.isEmpty) {
        await _repository.crear(insumo);
      } else {
        await _repository.actualizar(insumo);
      }
      await loadInsumos();
    } catch (e) {
      _setError('Error al guardar insumo: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos auxiliares para manejar estado
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Nuevo método para limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }
}