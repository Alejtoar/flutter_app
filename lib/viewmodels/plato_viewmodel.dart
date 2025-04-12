// In plato_viewmodel.dart
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/viewmodels/base/base_viewmodel.dart';

class PlatoViewModel extends BaseViewModel {
  final PlatoRepository _platoRepo;
  Plato? _platoDetalles;
  List<Plato> _platos = [];

  PlatoViewModel(this._platoRepo);

  Plato? get platoDetalles => _platoDetalles;
  List<Plato> get platos => _platos;

  Future<void> cargarDetallesPlato(String platoId) async {
    setState(ViewState.busy);
    try {
      _platoDetalles = await _platoRepo.obtener(platoId);
      setState(ViewState.idle);
    } catch (e) {
      setState(ViewState.error, error: 'Error al cargar detalles');
    }
  }

  Future<void> eliminarPlato(String platoId) async {
    setState(ViewState.busy);
    try {
      await _platoRepo.eliminar(platoId);
      setState(ViewState.idle);
    } catch (e) {
      setState(ViewState.error, error: 'Error al eliminar');
      rethrow;
    }
  }

  Future<void> guardarPlato(Plato plato) async {
    setState(ViewState.busy);
    try {
      if (plato.id == null) {
        await _platoRepo.crear(plato);
      } else {
        await _platoRepo.actualizar(plato);
      }
      setState(ViewState.idle);
    } catch (e) {
      setState(ViewState.error, error: 'Error al guardar');
      rethrow;
    }
  }

  Future<void> cargarPlatos() async {
    setState(ViewState.busy);
    try {
      _platos = await _platoRepo.obtenerTodos();
      setState(ViewState.idle);
    } catch (e) {
      setState(ViewState.error, error: 'Error al cargar platos');
      rethrow;
    }
  }
}