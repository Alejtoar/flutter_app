// plato_controller.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/repositories/plato_repository_impl.dart';
import 'package:golo_app/exceptions/plato_en_uso_exception.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository_impl.dart';
import 'package:golo_app/repositories/insumo_requerido_repository_impl.dart';

class PlatoController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _platoRepository.generarNuevoCodigo();
  }
  final PlatoFirestoreRepository _platoRepository;
  final IntermedioRequeridoFirestoreRepository _intermedioRequeridoRepository;
  final InsumoRequeridoFirestoreRepository _insumoRequeridoRepository;

  PlatoController(
    this._platoRepository,
    this._intermedioRequeridoRepository,
    this._insumoRequeridoRepository,
  );

  List<Plato> _platos = [];
  List<Plato> get platos => _platos;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // Relaciones actuales cargadas para edición
  List<IntermedioRequerido> _intermediosRequeridos = [];
  List<IntermedioRequerido> get intermediosRequeridos => _intermediosRequeridos;
  List<InsumoRequerido> _insumosRequeridos = [];
  List<InsumoRequerido> get insumosRequeridos => _insumosRequeridos;

  Future<void> cargarPlatos() async {
    _loading = true;
    notifyListeners();
    try {
      _platos = await _platoRepository.obtenerTodos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> eliminarPlato(String id) async {
    try {
      await _platoRepository.eliminar(id);
      await _intermedioRequeridoRepository.eliminarPorPlato(id);
      await _insumoRequeridoRepository.eliminarPorPlato(id);
      _platos.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
    } on PlatoEnUsoException catch (e) {
      _error = e.toString();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> _eliminarPlatoIndividual(String id) async {
    try {
      await _platoRepository.eliminar(id);
      // Eliminar relaciones es opcional aquí si sabes que el repositorio ya lo hace en cascada
      // o si la eliminación en lote lo manejará por separado. Por ahora lo dejamos.
      await _intermedioRequeridoRepository.eliminarPorPlato(id);
      await _insumoRequeridoRepository.eliminarPorPlato(id);
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
  Future<void> eliminarUnPlato(String id) async {
    _error = null; // Limpiar error anterior
    final success = await _eliminarPlatoIndividual(id);
    if (success) {
      _platos.removeWhere((p) => p.id == id);
    }
    // Siempre notificar para actualizar la UI, ya sea quitando el item o mostrando el error.
    notifyListeners();
  }


  /// Método PÚBLICO para eliminar MÚLTIPLES platos.
  /// Notifica UNA SOLA VEZ al final.
  Future<Set<String>> eliminarPlatosEnLote(Set<String> ids) async { // <-- CAMBIA EL TIPO DE RETORNO
    if (ids.isEmpty) return {}; // Devuelve set vacío
    _error = null;

    final List<Future<bool>> deleteFutures = [];
    final List<String> idList = ids.toList(); // Convertir a lista para acceder por índice

    for (final id in idList) {
       deleteFutures.add(_eliminarPlatoIndividual(id));
    }

    final List<bool> results = await Future.wait(deleteFutures);
    final Set<String> idsExitosos = {};

    for (int i = 0; i < results.length; i++) {
        if (results[i]) { // Si el resultado fue 'true' (éxito)
            idsExitosos.add(idList[i]); // Añade el ID correspondiente a la lista de éxitos
        }
    }

    final int falloCount = results.length - idsExitosos.length;
    debugPrint("[PlatoController] Eliminación en lote finalizada. Éxitos: ${idsExitosos.length}, Fallos: $falloCount");

    if (falloCount > 0) {
      _error = "No se pudieron eliminar $falloCount de ${results.length} platos. (Verificar si están en uso)";
    }

    // Actualizar la lista local _platos quitando SOLO los que tuvieron éxito
    if (idsExitosos.isNotEmpty) {
        _platos.removeWhere((plato) => idsExitosos.contains(plato.id));
    }

    // Notificar a la UI UNA SOLA VEZ con el estado final.
    notifyListeners();

    return idsExitosos; // <-- DEVOLVER LOS IDs EXITOSOS
  }

  /// Crear un plato y sus relaciones (intermedios e insumos requeridos)
  Future<Plato?> crearPlatoConRelaciones(
    Plato plato,
    List<IntermedioRequerido> intermedios,
    List<InsumoRequerido> insumos,
  ) async {
    debugPrint('===> [crearPlatoConRelaciones] Iniciando creación de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}');
    debugPrint('===> [crearPlatoConRelaciones] Intermedios: ${intermedios.length}, Insumos: ${insumos.length}');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('===> [crearPlatoConRelaciones] Creando plato en repositorio...');
      final creado = await _platoRepository.crear(plato);
      debugPrint('===> [crearPlatoConRelaciones] Plato creado con id: ${creado.id}');
      final intermediosConId = intermedios.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      final insumosConId = insumos.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      debugPrint('===> [crearPlatoConRelaciones] Reemplazando intermedios requeridos...');
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        creado.id!,
        { for (var i in intermediosConId) i.intermedioId: i.cantidad },
      );
      debugPrint('===> [crearPlatoConRelaciones] Reemplazando insumos requeridos...');
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(
        creado.id!,
        { for (var i in insumosConId) i.insumoId: i.cantidad },
      );
      _platos.add(creado);
      _error = null;
      debugPrint('===> [crearPlatoConRelaciones] Plato y relaciones guardados correctamente.');
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
    debugPrint('===> [actualizarPlatoConRelaciones] Iniciando actualización de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}');
    debugPrint('===> [actualizarPlatoConRelaciones] Intermedios: ${nuevosIntermedios.length}, Insumos: ${nuevosInsumos.length}');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('===> [actualizarPlatoConRelaciones] Actualizando plato en repositorio...');
      await _platoRepository.actualizar(plato);
      debugPrint('===> [actualizarPlatoConRelaciones] Reemplazando intermedios requeridos...');
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        plato.id!,
        { for (var i in nuevosIntermedios) i.intermedioId: i.cantidad },
      );
      debugPrint('===> [actualizarPlatoConRelaciones] Reemplazando insumos requeridos...');
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(
        plato.id!,
        { for (var i in nuevosInsumos) i.insumoId: i.cantidad },
      );
      final idx = _platos.indexWhere((p) => p.id == plato.id);
      if (idx != -1) _platos[idx] = plato;
      _error = null;
      debugPrint('===> [actualizarPlatoConRelaciones] Plato y relaciones actualizados correctamente.');
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
      _intermediosRequeridos = await _intermedioRequeridoRepository.obtenerPorPlato(platoId);
      _insumosRequeridos = await _insumoRequeridoRepository.obtenerPorPlato(platoId);
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
