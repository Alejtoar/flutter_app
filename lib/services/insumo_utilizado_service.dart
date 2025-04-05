import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/insumo_utilizado.dart';
import '../models/insumo.dart';
import './insumo_service.dart';

class InsumoUtilizadoService {
  final FirebaseFirestore _db;
  final InsumoService _insumoService;
  final String _coleccionIntermedios = 'intermedios';
  final String _coleccionPlatos = 'platos';

  InsumoUtilizadoService({
    FirebaseFirestore? db,
    InsumoService? insumoService,
  }) : _db = db ?? FirebaseFirestore.instance,
       _insumoService = insumoService ?? InsumoService();

  // 1. Actualización en cascada cuando cambia un insumo
  Future<void> actualizarEnInsumosCambiados(String insumoId) async {
    final batch = _db.batch();
    final insumoActual = await _insumoService.obtenerInsumo(insumoId);
    
    // Buscar en intermedios
    final intermedios = await _db.collection(_coleccionIntermedios)
        .where('insumos.insumoId', isEqualTo: insumoId)
        .get();

    for (final doc in intermedios.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final insumos = List<Map<String, dynamic>>.from(data['insumos'] ?? []);
      
      final nuevosInsumos = insumos.map((insumo) {
        if (insumo['insumoId'] == insumoId) {
          return {
            ...insumo,
            'nombre': insumoActual.nombre,
            'unidad': insumoActual.unidad,
            'precioUnitario': insumoActual.precioUnitario,
            'fechaActualizacion': FieldValue.serverTimestamp(),
          };
        }
        return insumo;
      }).toList();

      batch.update(doc.reference, {
        'insumos': nuevosInsumos,
        'fechaActualizacion': FieldValue.serverTimestamp()
      });
    }

    // Buscar en platos (a través de intermedios)
    final platos = await _db.collection(_coleccionPlatos)
        .where('intermedios.intermedioId.insumos.insumoId', isEqualTo: insumoId)
        .get();

    for (final doc in platos.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final intermediosPlato = List<Map<String, dynamic>>.from(data['intermedios'] ?? []);
      
      final nuevosIntermedios = await Future.wait(intermediosPlato.map((intermedio) async {
        if (intermedio['insumos'] != null) {
          final insumosIntermedio = List<Map<String, dynamic>>.from(intermedio['insumos']);
          final insumosActualizados = insumosIntermedio.map((insumo) {
            if (insumo['insumoId'] == insumoId) {
              return {
                ...insumo,
                'nombre': insumoActual.nombre,
                'unidad': insumoActual.unidad,
                'precioUnitario': insumoActual.precioUnitario,
                'fechaActualizacion': FieldValue.serverTimestamp(),
              };
            }
            return insumo;
          }).toList();
          
          return {
            ...intermedio,
            'insumos': insumosActualizados,
            'fechaActualizacion': FieldValue.serverTimestamp()
          };
        }
        return intermedio;
      }));

      batch.update(doc.reference, {
        'intermedios': nuevosIntermedios,
        'fechaActualizacion': FieldValue.serverTimestamp()
      });
    }

    await batch.commit();
  }

  // 2. Validación de consistencia
  Future<void> validarRelaciones(String insumoId) async {
    final count = await _db.collectionGroup('insumos')
        .where('insumoId', isEqualTo: insumoId)
        .count()
        .get();

    if (count.count! > 0) {
      throw Exception('No se puede modificar/eliminar: el insumo está en uso en ${count.count} preparaciones');
    }
  }

  // 3. Conversión masiva para reportes
  Future<List<InsumoUtilizado>> convertirMapasAInsumosUtilizados(
    List<Map<String, dynamic>> insumosData,
  ) async {
    final insumosIds = insumosData.map((i) => i['insumoId'] as String).where((id) => id.isNotEmpty).toList();
    
    if (insumosIds.isEmpty) return [];
    
    final insumosCompletos = await _insumoService.obtenerInsumos(insumosIds);

    return insumosData.map((data) {
      final insumo = insumosCompletos.firstWhere(
        (i) => i.id == data['insumoId'],
        orElse: () => throw Exception('Insumo ${data['insumoId']} no encontrado'),
      );
      
      return InsumoUtilizado.crear(
        insumoId: insumo.id!,
        codigo: insumo.codigo,
        nombre: insumo.nombre,
        unidad: insumo.unidad,
        cantidad: (data['cantidad'] ?? 0).toDouble(),
        precioUnitario: insumo.precioUnitario,
      );
    }).toList();
  }

  // 4. Cálculo de costos parciales (VERSIÓN CORREGIDA)
  double calcularCostoTotal(List<InsumoUtilizado> insumos) {
    return insumos.fold(0, (total, insumo) => total + (insumo.cantidad * insumo.precioUnitario));
  }

  // 5. Versión asíncrona para cálculos con precios actualizados
  Future<double> calcularCostoTotalActualizado(List<InsumoUtilizado> insumos) async {
    double total = 0;
    
    for (final insumo in insumos) {
      final insumoActual = await _insumoService.obtenerInsumo(insumo.insumoId);
      total += insumo.cantidad * insumoActual.precioUnitario;
    }
    
    return total;
  }

  // 6. Migración de datos
  Future<void> migrarFormatoAntiguo() async {
    final batch = _db.batch();
    final intermedios = await _db.collection(_coleccionIntermedios).get();

    for (final doc in intermedios.docs) {
      final data = doc.data();
      if (data['insumos'] is List && data['insumos'].isNotEmpty) {
        final nuevosInsumos = await convertirMapasAInsumosUtilizados(
          List<Map<String, dynamic>>.from(data['insumos']),
        );

        batch.update(doc.reference, {
          'insumos': nuevosInsumos.map((i) => i.toFirestore()).toList(),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}