import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../services/evento_service.dart';

class EventoViewModel with ChangeNotifier {
  final EventoService _service;
  List<Evento> _eventos = [];
  List<Evento> _eventosUrgentes = [];
  bool _loading = false;
  String? _error;
  Evento? _eventoSeleccionado;

  // Getters
  List<Evento> get eventos => _eventos;
  List<Evento> get eventosUrgentes => _eventosUrgentes;
  bool get loading => _loading;
  String? get error => _error;
  Evento? get eventoSeleccionado => _eventoSeleccionado;

  EventoViewModel(this._service);

  // Cargar eventos con filtros
  Future<void> cargarEventos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoEvento? tipo,
    EstadoEvento? estado,
  }) async {
    _setLoading(true);
    try {
      _eventos = await _service.obtenerEventos(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        tipo: tipo,
        estado: estado,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _eventos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar eventos urgentes
  Future<void> cargarEventosUrgentes() async {
    try {
      _eventosUrgentes = await _service.obtenerEventosUrgentes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _eventosUrgentes = [];
    }
  }

  // Cargar un evento específico
  Future<void> cargarEvento(String id) async {
    _setLoading(true);
    try {
      _eventoSeleccionado = await _service.obtenerEvento(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _eventoSeleccionado = null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear nuevo evento
  Future<bool> crearEvento(Evento evento) async {
    _setLoading(true);
    try {
      await _service.crearEvento(evento);
      await cargarEventos();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar evento existente
  Future<bool> actualizarEvento(Evento evento) async {
    _setLoading(true);
    try {
      await _service.actualizarEvento(evento);
      if (_eventoSeleccionado?.id == evento.id) {
        _eventoSeleccionado = evento;
      }
      await cargarEventos();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirmar evento
  Future<bool> confirmarEvento(String id) async {
    _setLoading(true);
    try {
      await _service.confirmarEvento(id, DateTime.now());
      await cargarEventos();
      if (_eventoSeleccionado?.id == id) {
        await cargarEvento(id);
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar estado del evento
  Future<bool> actualizarEstadoEvento(String id, EstadoEvento nuevoEstado) async {
    _setLoading(true);
    try {
      await _service.actualizarEstadoEvento(id, nuevoEstado);
      await cargarEventos();
      if (_eventoSeleccionado?.id == id) {
        await cargarEvento(id);
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Búsqueda de eventos
  Future<void> buscarEventos(String query) async {
    if (query.isEmpty) {
      await cargarEventos();
      return;
    }

    _setLoading(true);
    try {
      _eventos = await _service.buscarEventos(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _eventos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar evento
  void seleccionarEvento(Evento? evento) {
    _eventoSeleccionado = evento;
    notifyListeners();
  }

  // Limpiar selección
  void limpiarSeleccion() {
    _eventoSeleccionado = null;
    notifyListeners();
  }

  // Limpiar error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Helper para manejar el estado de loading
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
