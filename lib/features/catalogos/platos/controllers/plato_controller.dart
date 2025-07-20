import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/exceptions/plato_en_uso_exception.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';
import 'package:golo_app/repositories/insumo_requerido_repository.dart';

/// Controlador que gestiona la lógica de negocio para los platos.
///
/// Este controlador maneja las operaciones CRUD para los platos,
/// así como la gestión de los insumos e intermedios requeridos para cada plato.
/// También se encarga de la generación de códigos únicos para nuevos platos.
class PlatoController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _platoRepository.generarNuevoCodigo(uid: _uid);
  }

  // Repositorios
  final PlatoRepository _platoRepository;
  final IntermedioRequeridoRepository _intermedioRequeridoRepository;
  final InsumoRequeridoRepository _insumoRequeridoRepository;
  
  // Autenticación
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Estado de la aplicación
  List<Plato> _platos = [];
  bool _loading = false;
  String? _error;
  
  // Relaciones cargadas para edición
  List<IntermedioRequerido> _intermediosRequeridos = [];
  List<InsumoRequerido> _insumosRequeridos = [];
  
  // Getters públicos
  
  /// ID del usuario actual
  String? get _uid => _auth.currentUser?.uid;
  
  /// Lista completa de platos
  List<Plato> get platos => _platos;
  
  /// Indica si se está cargando información
  bool get loading => _loading;
  
  /// Mensaje de error, si existe
  String? get error => _error;
  
  /// Lista de intermedios requeridos para el plato actual
  List<IntermedioRequerido> get intermediosRequeridos => _intermediosRequeridos;
  
  /// Lista de insumos requeridos para el plato actual
  List<InsumoRequerido> get insumosRequeridos => _insumosRequeridos;
  
  /// Crea una nueva instancia del controlador de platos
  /// 
  /// [platoRepository] Repositorio para acceder a los datos de platos
  /// [intermedioRequeridoRepository] Repositorio para acceder a los datos de intermedios requeridos
  /// [insumoRequeridoRepository] Repositorio para acceder a los datos de insumos requeridos
  PlatoController(
    this._platoRepository,
    this._intermedioRequeridoRepository,
    this._insumoRequeridoRepository,
  );

  /// Carga todos los platos del usuario actual
  /// 
  /// Actualiza el estado de carga y notifica a los listeners cuando finaliza.
  /// En caso de error, establece el mensaje de error correspondiente.
  Future<void> cargarPlatos() async {
    _loading = true;
    notifyListeners();
    try {
      _platos = await _platoRepository.obtenerTodos(uid: _uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Carga las relaciones (insumos e intermedios) de un plato específico
  /// 
  /// [platoId] ID del plato del cual cargar las relaciones
  /// 
  /// Lanza una excepción si ocurre un error al cargar las relaciones.
  /// Notifica a los listeners cuando finaliza la operación.
  Future<void> cargarRelacionesPlato(String platoId) async {
    try {
      _intermediosRequeridos = await _intermedioRequeridoRepository.obtenerPorPlato(platoId, uid: _uid);
      _insumosRequeridos = await _insumoRequeridoRepository.obtenerPorPlato(platoId, uid: _uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }
  //     return false;
  //   } catch (e) {
  //     _error = e.toString();
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<bool> _eliminarPlatoIndividual(String id) async {
    try {
      await _platoRepository.eliminar(id, uid: _uid);
      // Eliminar relaciones es opcional aquí si sabes que el repositorio ya lo hace en cascada
      // o si la eliminación en lote lo manejará por separado. Por ahora lo dejamos.
      await _intermedioRequeridoRepository.eliminarPorPlato(id, uid: _uid);
      await _insumoRequeridoRepository.eliminarPorPlato(id, uid: _uid);
      return true;
    } on PlatoEnUsoException catch (e) {
      _error = e.toString(); // Guardar el error
      debugPrint('[PlatoController] Error al eliminar plato $id: $_error');
      return false; // Indicar fallo
    } catch (e) {
      _error = 'Error inesperado al eliminar plato $id: $e';
      debugPrint(_error);
      return false; // Indicar fallo
    }
  }

  /// Método PÚBLICO para eliminar un solo plato desde la UI (ej. botón de basura individual).
  /// Este SÍ notifica a la UI.
  Future<bool> eliminarPlato(String id) async {
    final success = await _eliminarPlatoIndividual(id);

    if (success) {
      // Si la eliminación en la BD fue exitosa, quitarlo de la lista local
      _platos.removeWhere((p) => p.id == id);
    }

    notifyListeners();
    return success;
  }

  Future<Set<String>> eliminarPlatosEnLote(Set<String> ids) async {
    if (ids.isEmpty) return {};
    _error = null;

    final List<Future<bool>> deleteFutures = [];
    final List<String> idList =
        ids.toList(); // Convertir a lista para acceder por índice

    for (final id in idList) {
      deleteFutures.add(_eliminarPlatoIndividual(id));
    }

    final List<bool> results = await Future.wait(deleteFutures);
    final Set<String> idsExitosos = {};

    for (int i = 0; i < results.length; i++) {
      if (results[i]) {
        // Si el resultado fue 'true' (éxito)
        idsExitosos.add(
          idList[i],
        ); // Añade el ID correspondiente a la lista de éxitos
      }
    }

    final int falloCount = results.length - idsExitosos.length;
    debugPrint(
      "[PlatoController] Eliminación en lote finalizada. Éxitos: ${idsExitosos.length}, Fallos: $falloCount",
    );

    if (falloCount > 0) {
      _error =
          "No se pudieron eliminar $falloCount de ${results.length} platos. (Verificar si están en uso)";
    }

    if (idsExitosos.isNotEmpty) {
      _platos.removeWhere((plato) => idsExitosos.contains(plato.id));
    }

    notifyListeners();

    return idsExitosos;
  }

  /// Crear un plato y sus relaciones (intermedios e insumos requeridos)
  Future<Plato?> crearPlatoConRelaciones(
    Plato plato,
    List<IntermedioRequerido> intermedios,
    List<InsumoRequerido> insumos,
  ) async {
    debugPrint(
      '===> [crearPlatoConRelaciones] Iniciando creación de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}',
    );
    debugPrint(
      '===> [crearPlatoConRelaciones] Intermedios: ${intermedios.length}, Insumos: ${insumos.length}',
    );
    _loading = true;
    notifyListeners();
    try {
      debugPrint(
        '===> [crearPlatoConRelaciones] Creando plato en repositorio...',
      );
      final creado = await _platoRepository.crear(plato, uid: _uid);
      debugPrint(
        '===> [crearPlatoConRelaciones] Plato creado con id: ${creado.id}',
      );
      final intermediosConId =
          intermedios.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      final insumosConId =
          insumos.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      debugPrint(
        '===> [crearPlatoConRelaciones] Reemplazando intermedios requeridos...',
      );
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        creado.id!,
        {for (var i in intermediosConId) i.intermedioId: i.cantidad},
        uid: _uid,
      );
      debugPrint(
        '===> [crearPlatoConRelaciones] Reemplazando insumos requeridos...',
      );
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(creado.id!, {
        for (var i in insumosConId) i.insumoId: i.cantidad,
      }, uid: _uid);
      _platos.add(creado);
      _error = null;
      debugPrint(
        '===> [crearPlatoConRelaciones] Plato y relaciones guardados correctamente.',
      );
      notifyListeners();
      return creado;
    } catch (e, st) {
      debugPrint('===> [crearPlatoConRelaciones][ERROR] $e');
      debugPrint('===> [crearPlatoConRelaciones][STACK] $st');
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      debugPrint('===> [crearPlatoConRelaciones] Finalizado.');
      notifyListeners();
    }
  }

  /// Actualizar un plato y sus relaciones (intermedios e insumos requeridos)
  Future<bool> actualizarPlatoConRelaciones(
    Plato plato,
    List<IntermedioRequerido> nuevosIntermedios,
    List<InsumoRequerido> nuevosInsumos,
  ) async {
    debugPrint(
      '===> [actualizarPlatoConRelaciones] Iniciando actualización de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}',
    );
    debugPrint(
      '===> [actualizarPlatoConRelaciones] Intermedios: ${nuevosIntermedios.length}, Insumos: ${nuevosInsumos.length}',
    );
    _loading = true;
    notifyListeners();
    try {
      debugPrint(
        '===> [actualizarPlatoConRelaciones] Actualizando plato en repositorio...',
      );
      await _platoRepository.actualizar(plato, uid: _uid);
      debugPrint(
        '===> [actualizarPlatoConRelaciones] Reemplazando intermedios requeridos...',
      );
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        plato.id!,
        {for (var i in nuevosIntermedios) i.intermedioId: i.cantidad},
        uid: _uid,
      );
      debugPrint(
        '===> [actualizarPlatoConRelaciones] Reemplazando insumos requeridos...',
      );
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(plato.id!, {
        for (var i in nuevosInsumos) i.insumoId: i.cantidad,
      }, uid: _uid);
      final idx = _platos.indexWhere((p) => p.id == plato.id);
      if (idx != -1) _platos[idx] = plato;
      _error = null;
      debugPrint(
        '===> [actualizarPlatoConRelaciones] Plato y relaciones actualizados correctamente.',
      );
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('===> [actualizarPlatoConRelaciones][ERROR] $e');
      debugPrint('===> [actualizarPlatoConRelaciones][STACK] $st');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      debugPrint('===> [actualizarPlatoConRelaciones] Finalizado.');
      notifyListeners();
    }
  }

  /// Cargar relaciones de un plato específico
  Future<void> cargarRelacionesPorPlato(String platoId) async {
    _loading = true;
    notifyListeners();
    try {
      _intermediosRequeridos = await _intermedioRequeridoRepository
          .obtenerPorPlato(platoId, uid: _uid);
      _insumosRequeridos = await _insumoRequeridoRepository.obtenerPorPlato(
        platoId,
        uid: _uid,
      );
      _error = null;
    } catch (e) {
      _intermediosRequeridos = [];
      _insumosRequeridos = [];
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
