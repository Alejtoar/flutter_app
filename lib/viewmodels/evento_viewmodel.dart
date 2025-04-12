import 'package:golo_app/models/evento.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/logics/calculadora_costos_logic.dart';
import 'package:golo_app/viewmodels/base/base_viewmodel.dart';

class EventoViewModel extends BaseViewModel {
  EventoRepository _eventoRepo;
  set eventoRepo(EventoRepository value) => _eventoRepo = value;
  final CalculadoraCostosService _calculadoraService;
  
  List<Evento> _eventos = [];
  List<Evento> get eventos => _eventos;
  
  EventoViewModel(this._eventoRepo, this._calculadoraService);
  
  Future<void> cargarEventos() async {
    setState(ViewState.busy);
    try {
      _eventos = await _eventoRepo.obtenerTodos();
      setState(ViewState.idle);
    } catch (e) {
      setState(ViewState.error, error: 'Error al cargar eventos');
    }
  }
  
  Future<double> calcularCostoEvento(String eventoId) async {
    setState(ViewState.busy);
    try {
      final costo = await _calculadoraService.calcularCostoEvento(eventoId);
      setState(ViewState.idle);
      return costo;
    } catch (e) {
      setState(ViewState.error, error: 'Error al calcular costo');
      rethrow;
    }
  }
}
