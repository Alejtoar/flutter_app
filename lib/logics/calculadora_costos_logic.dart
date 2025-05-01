// lib/logics/calculadora_costos_logic.dart

import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/repositories/plato_evento_repository.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';

class CalculadoraCostosService {
  final InsumoRepository _insumoRepo;
  final IntermedioRepository _intermedioRepo;
  final InsumoUtilizadoRepository _insumoUtilizadoRepo;
  final IntermedioRequeridoRepository _intermedioRequeridoRepo;
  final PlatoRepository _platoRepo;
  final PlatoEventoRepository _platoEventoRepo;
  final IntermedioEventoRepository _intermedioEventoRepo;
  final InsumoEventoRepository _insumoEventoRepo;

  CalculadoraCostosService({
    required InsumoRepository insumoRepo,
    required IntermedioRepository intermedioRepo,
    required InsumoUtilizadoRepository insumoUtilizadoRepo,
    required IntermedioRequeridoRepository intermedioRequeridoRepo,
    required PlatoRepository platoRepo,
    required PlatoEventoRepository platoEventoRepo,
    required IntermedioEventoRepository intermedioEventoRepo,
    required InsumoEventoRepository insumoEventoRepo,
  }) : _insumoRepo = insumoRepo,
       _intermedioRepo = intermedioRepo,
       _insumoUtilizadoRepo = insumoUtilizadoRepo,
       _intermedioRequeridoRepo = intermedioRequeridoRepo,
       _platoRepo = platoRepo,
       _platoEventoRepo = platoEventoRepo,
       _intermedioEventoRepo = intermedioEventoRepo,
       _insumoEventoRepo = insumoEventoRepo;

  /// Calcula el costo de un insumo para cierta cantidad
  Future<double> calcularCostoInsumo(String insumoId, double cantidad) async {
    final insumo = await _insumoRepo.obtener(insumoId);
    return insumo.precioUnitario * cantidad;
  }

  /// Calcula el costo de preparar un intermedio para cierta cantidad
  Future<double> calcularCostoIntermedio({
    required String intermedioId,
    double? cantidadPreparar,
  }) async {
    // Obtener el intermedio
    final intermedio = await _intermedioRepo.obtener(intermedioId);
    
    // Determinar la proporción
    final proporcion = cantidadPreparar != null 
        ? cantidadPreparar / intermedio.cantidadEstandar
        : 1.0;

    // Obtener los insumos utilizados
    final insumosUtilizados = await _insumoUtilizadoRepo.obtenerPorIntermedio(intermedioId);
    
    // Obtener detalles de los insumos
    final insumoIds = insumosUtilizados.map((iu) => iu.insumoId).toList();
    final insumos = await _insumoRepo.obtenerVarios(insumoIds);

    // Calcular costo total
    double costoTotal = 0.0;
    for (final iu in insumosUtilizados) {
      final insumo = insumos.firstWhere((i) => i.id == iu.insumoId);
      final cantidadAjustada = iu.cantidad * proporcion;
      costoTotal += insumo.precioUnitario * cantidadAjustada;
    }

    return costoTotal;
  }

  /// Calcula el costo de preparar N unidades de un plato
  Future<double> calcularCostoPlato({
    required String platoId,
    required int cantidad,
  }) async {
    // Obtener el plato
    final plato = await _platoRepo.obtener(platoId);
    
    // Calcular proporción
    final proporcion = cantidad / plato.porcionesMinimas;

    // Obtener intermedios requeridos
    final intermediosRequeridos = await _intermedioRequeridoRepo.obtenerPorPlato(platoId);
    
    // Calcular costo de cada intermedio
    double costoTotal = 0.0;
    for (final ir in intermediosRequeridos) {
      final costoIntermedio = await calcularCostoIntermedio(
        intermedioId: ir.intermedioId,
        cantidadPreparar: ir.cantidad * proporcion,
      );
      costoTotal += costoIntermedio;
    }

    return costoTotal;
  }

  /// Calcula los costos para múltiples platos
  Future<Map<String, double>> calcularCostosPorPlatos(Map<String, int> platosYCantidades) async {
    final resultados = <String, double>{};
    
    for (final entry in platosYCantidades.entries) {
      final platoId = entry.key;
      final cantidad = entry.value;
      
      resultados[platoId] = await calcularCostoPlato(
        platoId: platoId,
        cantidad: cantidad,
      );
    }

    return resultados;
  }

  /// Calcula el margen de ganancia sugerido (30% sobre el costo)
  double calcularPrecioVenta(double costo) {
    return costo * 1.3; // 30% de margen
  }

  /// Calcula el costo total de un evento considerando todos sus componentes
  Future<double> calcularCostoEvento(String eventoId) async {
    double costoTotal = 0.0;
    
    // 1. Calcular costo de platos del evento
    final platosEvento = await _platoEventoRepo.obtenerPorEvento(eventoId);
    for (final platoEvento in platosEvento) {
      final costoPlato = await calcularCostoPlato(
        platoId: platoEvento.platoId,
        cantidad: platoEvento.cantidad,
      );
      costoTotal += costoPlato;
    }
    
    // 2. Calcular costo de intermedios del evento
    final intermediosEvento = await _intermedioEventoRepo.obtenerPorEvento(eventoId);
    for (final intermedioEvento in intermediosEvento) {
      final costoIntermedio = await calcularCostoIntermedio(
        intermedioId: intermedioEvento.intermedioId,
        cantidadPreparar: intermedioEvento.cantidad.toDouble(),
      );
      costoTotal += costoIntermedio;
    }
    
    // 3. Calcular costo de insumos directos del evento
    final insumosEvento = await _insumoEventoRepo.obtenerPorEvento(eventoId);
    for (final insumoEvento in insumosEvento) {
      final costoInsumo = await calcularCostoInsumo(
        insumoEvento.insumoId,
        insumoEvento.cantidad,
      );
      costoTotal += costoInsumo;
    }
    
    return costoTotal;
  }
}