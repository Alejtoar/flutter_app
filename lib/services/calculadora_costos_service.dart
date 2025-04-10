import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/repositories/plato_repository.dart';

class CalculadoraCostosService {
  final InsumoRepository _insumoRepo;
  final IntermedioRepository _intermedioRepo;
  final InsumoUtilizadoRepository _insumoUtilizadoRepo;
  final IntermedioRequeridoRepository _intermedioRequeridoRepo;
  final PlatoRepository _platoRepo;

  CalculadoraCostosService({
    required InsumoRepository insumoRepo,
    required IntermedioRepository intermedioRepo,
    required InsumoUtilizadoRepository insumoUtilizadoRepo,
    required IntermedioRequeridoRepository intermedioRequeridoRepo,
    required PlatoRepository platoRepo,
  }) : _insumoRepo = insumoRepo,
       _intermedioRepo = intermedioRepo,
       _insumoUtilizadoRepo = insumoUtilizadoRepo,
       _intermedioRequeridoRepo = intermedioRequeridoRepo,
       _platoRepo = platoRepo;

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
}