import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/exceptions/intermedio_en_uso_exception.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';

/// Controlador que gestiona la lógica de negocio para los intermedios.
/// 
/// Este controlador maneja las operaciones CRUD para los intermedios,
/// así como la gestión de los insumos utilizados en cada intermedio.
/// También se encarga de la generación de códigos únicos para nuevos intermedios.
class IntermedioController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _repository.generarNuevoCodigo(uid: _uid);
  }
  // Repositorios
  final IntermedioRepository _repository;
  final InsumoUtilizadoRepository _insumoUtilizadoRepository;
  
  // Estado de la aplicación
  List<Intermedio> _intermedios = [];
  bool _loading = false;
  String? _error;

  // Insumos utilizados por el intermedio actual (para edición)
  List<InsumoUtilizado> _insumosUtilizados = [];
  
  // Autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Getters públicos
  
  /// Lista de insumos utilizados por el intermedio actual
  List<InsumoUtilizado> get insumosUtilizados => _insumosUtilizados;
  
  /// ID del usuario actual
  String? get _uid => _auth.currentUser?.uid;
  
  /// Lista completa de intermedios
  List<Intermedio> get intermedios => _intermedios;
  
  /// Indica si se está cargando información
  bool get loading => _loading;
  
  /// Mensaje de error, si existe
  String? get error => _error;
  
  /// Crea una nueva instancia del controlador de intermedios
  /// 
  /// [repository] Repositorio para acceder a los datos de intermedios
  /// [insumoUtilizadoRepository] Repositorio para acceder a los datos de insumos utilizados
  IntermedioController(this._repository, this._insumoUtilizadoRepository);

  /// Carga todos los intermedios del usuario actual
  /// 
  /// Actualiza el estado de carga y notifica a los listeners cuando finaliza.
  /// En caso de error, establece el mensaje de error correspondiente.
  Future<void> cargarIntermedios() async {
    _loading = true;
    notifyListeners();
    try {
      _intermedios = await _repository.obtenerTodos(uid: _uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Elimina un intermedio y sus insumos asociados
  /// 
  /// [id] El ID del intermedio a eliminar
  /// 
  /// Lanza una excepción si el intermedio está siendo utilizado en algún plato.
  Future<void> eliminarIntermedio(String id) async {
    try {
      await _repository.eliminar(id, uid: _uid);
      await _insumoUtilizadoRepository.eliminarPorIntermedio(id, uid: _uid);
      _intermedios.removeWhere((i) => i.id == id);
      _error = null;
      notifyListeners();
    } on IntermedioEnUsoException catch (e) {
      _error = e.toString();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crear un intermedio y sus insumos utilizados (batch)
  Future<Intermedio?> crearIntermedioConInsumos(
    Intermedio intermedio,
    List<InsumoUtilizado> insumos
  ) async {
    _loading = true;
    notifyListeners();
    try {
      final creado = await _repository.crear(intermedio, uid: _uid);
      final relaciones = insumos.map((iu) => iu.copyWith(intermedioId: creado.id!)).toList();
      await _insumoUtilizadoRepository.crearMultiples(relaciones, uid: _uid);
      _intermedios.add(creado);
      _error = null;
      notifyListeners();
      return creado;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Actualizar un intermedio y sus insumos utilizados (batch)
  Future<bool> actualizarIntermedioConInsumos(
    Intermedio intermedio,
    List<InsumoUtilizado> nuevosInsumos
  ) async {
    _loading = true;
    notifyListeners();
    try {
      await _repository.actualizar(intermedio, uid: _uid);
      await _insumoUtilizadoRepository.eliminarPorIntermedio(intermedio.id!, uid: _uid);
      final relaciones = nuevosInsumos.map((iu) => iu.copyWith(intermedioId: intermedio.id!)).toList();
      await _insumoUtilizadoRepository.crearMultiples(relaciones, uid: _uid);
      final idx = _intermedios.indexWhere((i) => i.id == intermedio.id);
      if (idx != -1) _intermedios[idx] = intermedio;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cargar insumos utilizados para un intermedio específico
  Future<void> cargarInsumosUtilizadosPorIntermedio(String intermedioId) async {
    _loading = true;
    notifyListeners();
    try {
      _insumosUtilizados = await _insumoUtilizadoRepository.obtenerPorIntermedio(intermedioId, uid: _uid);
      _error = null;
    } catch (e) {
      _insumosUtilizados = [];
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
