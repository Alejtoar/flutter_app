import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';
import 'package:golo_app/repositories/plato_evento_repository.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';

class AgrupadorService {
  final InsumoRepository _insumoRepo;
  final IntermedioRepository _intermedioRepo;
  final InsumoUtilizadoRepository _insumoUtilizadoRepo;
  final IntermedioRequeridoRepository _intermedioRequeridoRepo;
  final PlatoRepository _platoRepo;
  final ProveedorRepository _proveedorRepo;
  final PlatoEventoRepository _platoEventoRepo;
  final IntermedioEventoRepository _intermedioEventoRepo;
  final InsumoEventoRepository _insumoEventoRepo;

  AgrupadorService({
    required InsumoRepository insumoRepo,
    required IntermedioRepository intermedioRepo,
    required InsumoUtilizadoRepository insumoUtilizadoRepo,
    required IntermedioRequeridoRepository intermedioRequeridoRepo,
    required PlatoRepository platoRepo,
    required ProveedorRepository proveedorRepo,
    required PlatoEventoRepository platoEventoRepo,
    required IntermedioEventoRepository intermedioEventoRepo,
    required InsumoEventoRepository insumoEventoRepo,
  }) : _insumoRepo = insumoRepo,
       _intermedioRepo = intermedioRepo,
       _insumoUtilizadoRepo = insumoUtilizadoRepo,
       _intermedioRequeridoRepo = intermedioRequeridoRepo,
       _platoRepo = platoRepo,
       _proveedorRepo = proveedorRepo,
       _platoEventoRepo = platoEventoRepo,
       _intermedioEventoRepo = intermedioEventoRepo,
       _insumoEventoRepo = insumoEventoRepo;

  /// Obtiene un resumen detallado de insumos para un plato específico
  Future<Map<String, dynamic>> listarInsumosDePlato({
    required String platoId,
    int cantidad = 1,
  }) async {
    final plato = await _platoRepo.obtener(platoId);
    final proporcion = cantidad / plato.porcionesMinimas;

    final intermediosRequeridos = await _intermedioRequeridoRepo.obtenerPorPlato(platoId);
    final insumosMap = <String, Map<String, dynamic>>{};

    for (final ir in intermediosRequeridos) {
      final insumosUtilizados = await _insumoUtilizadoRepo.obtenerPorIntermedio(ir.intermedioId);
      
      for (final iu in insumosUtilizados) {
        final insumo = await _insumoRepo.obtener(iu.insumoId);
        final cantidadTotal = iu.cantidad * ir.cantidad * proporcion;

        if (insumo.id != null && insumosMap.containsKey(insumo.id!)) {
          insumosMap[insumo.id!]!['cantidad'] += cantidadTotal;
        } else if (insumo.id != null) {
          insumosMap[insumo.id!] = {
            'insumo': insumo,
            'cantidad': cantidadTotal,
            'unidad': insumo.unidad,
          };
        }
      }
    }

    return {
      'plato': plato,
      'cantidadSolicitada': cantidad,
      'insumos': insumosMap.values.toList(),
    };
  }

  /// Versión para múltiples platos (suma cantidades de insumos)
  Future<Map<String, dynamic>> listarInsumosDePlatos(Map<String, int> platosYCantidades) async {
    final insumosMap = <String, Map<String, dynamic>>{};
    final platosInfo = <Map<String, dynamic>>[];

    for (final entry in platosYCantidades.entries) {
      final platoId = entry.key;
      final cantidad = entry.value;
      
      final resultado = await listarInsumosDePlato(
        platoId: platoId,
        cantidad: cantidad,
      );

      platosInfo.add({
        'plato': resultado['plato'],
        'cantidad': resultado['cantidadSolicitada'],
      });

      for (final insumoData in resultado['insumos']) {
        final insumo = insumoData['insumo'] as Insumo;
        final cantidad = insumoData['cantidad'] as double;

        if (insumo.id != null && insumosMap.containsKey(insumo.id!)) {
          insumosMap[insumo.id!]!['cantidad'] += cantidad;
        } else if (insumo.id != null) {
          insumosMap[insumo.id!] = {
            'insumo': insumo,
            'cantidad': cantidad,
            'unidad': insumo.unidad,
          };
        }
      }
    }

    return {
      'platos': platosInfo,
      'insumosTotales': insumosMap.values.toList(),
    };
  }

  /// Versión agrupada por proveedor
  Future<Map<String, dynamic>> listarInsumosDePlatosPorProveedor(
    Map<String, int> platosYCantidades,
  ) async {
    final resultado = await listarInsumosDePlatos(platosYCantidades);
    final insumosPorProveedor = <String, Map<String, dynamic>>{};

    for (final insumoData in resultado['insumosTotales']) {
      final insumo = insumoData['insumo'] as Insumo;
      final proveedor = await _proveedorRepo.obtener(insumo.proveedorId);
      
      if (proveedor.id == null) continue; // Skip insumos with no provider

      if (!insumosPorProveedor.containsKey(proveedor.id!)) {
        insumosPorProveedor[proveedor.id!] = {
          'proveedor': proveedor,
          'insumos': <Map<String, dynamic>>[],
        };
      }

      insumosPorProveedor[proveedor.id!]!['insumos'].add(insumoData);
    }

    return {
      'platos': resultado['platos'],
      'insumosPorProveedor': insumosPorProveedor.values.toList(),
    };
  }

  /// Métodos equivalentes para intermedios
  Future<Map<String, dynamic>> listarInsumosDeIntermedio({
    required String intermedioId,
    double cantidad = 1,
  }) async {
    final intermedio = await _intermedioRepo.obtener(intermedioId);
    final proporcion = cantidad / intermedio.cantidadEstandar;
    final insumosUtilizados = await _insumoUtilizadoRepo.obtenerPorIntermedio(intermedioId);
    final insumosMap = <String, Map<String, dynamic>>{};

    for (final iu in insumosUtilizados) {
      final insumo = await _insumoRepo.obtener(iu.insumoId);
      final cantidadTotal = iu.cantidad * proporcion;

      if (insumo.id != null && insumosMap.containsKey(insumo.id!)) {
        insumosMap[insumo.id!]!['cantidad'] += cantidadTotal;
      } else if (insumo.id != null) {
        insumosMap[insumo.id!] = {
          'insumo': insumo,
          'cantidad': cantidadTotal,
          'unidad': insumo.unidad,
        };
      }
    }

    return {
      'intermedio': intermedio,
      'cantidadSolicitada': cantidad,
      'insumos': insumosMap.values.toList(),
    };
  }

  Future<Map<String, dynamic>> listarInsumosDeIntermedios(
    Map<String, double> intermediosYCantidades,
  ) async {
    final insumosMap = <String, Map<String, dynamic>>{};
    final intermediosInfo = <Map<String, dynamic>>[];

    for (final entry in intermediosYCantidades.entries) {
      final intermedioId = entry.key;
      final cantidad = entry.value;
      
      final resultado = await listarInsumosDeIntermedio(
        intermedioId: intermedioId,
        cantidad: cantidad,
      );

      intermediosInfo.add({
        'intermedio': resultado['intermedio'],
        'cantidad': resultado['cantidadSolicitada'],
      });

      for (final insumoData in resultado['insumos']) {
        final insumo = insumoData['insumo'] as Insumo;
        final cantidad = insumoData['cantidad'] as double;

        if (insumo.id != null && insumosMap.containsKey(insumo.id!)) {
          insumosMap[insumo.id!]!['cantidad'] += cantidad;
        } else if (insumo.id != null) {
          insumosMap[insumo.id!] = {
            'insumo': insumo,
            'cantidad': cantidad,
            'unidad': insumo.unidad,
          };
        }
      }
    }

    return {
      'intermedios': intermediosInfo,
      'insumosTotales': insumosMap.values.toList(),
    };
  }

  /// Agrupa todos los componentes de un evento (platos, intermedios, insumos)
  Future<Map<String, dynamic>> agruparComponentesEvento(String eventoId) async {
    final componentes = {
      'platos': [],
      'intermedios': [],
      'insumos': [],
    };

    // 1. Obtener y agrupar platos del evento
    final platosEvento = await _platoEventoRepo.obtenerPorEvento(eventoId);
    for (final platoEvento in platosEvento) {
      final plato = await _platoRepo.obtener(platoEvento.platoId);
      componentes['platos']?.add({
        'plato': plato,
        'cantidad': platoEvento.cantidad,
      });
    }

    // 2. Obtener y agrupar intermedios del evento
    final intermediosEvento = await _intermedioEventoRepo.obtenerPorEvento(eventoId);
    for (final intermedioEvento in intermediosEvento) {
      final intermedio = await _intermedioRepo.obtener(intermedioEvento.intermedioId);
      componentes['intermedios']?.add({
        'intermedio': intermedio,
        'cantidad': intermedioEvento.cantidad,
      });
    }

    // 3. Obtener y agrupar insumos directos del evento
    final insumosEvento = await _insumoEventoRepo.obtenerPorEvento(eventoId);
    for (final insumoEvento in insumosEvento) {
      final insumo = await _insumoRepo.obtener(insumoEvento.insumoId);
      componentes['insumos']?.add({
        'insumo': insumo,
        'cantidad': insumoEvento.cantidad,
        'unidad': insumo.unidad,
      });
    }

    return componentes;
  }
}