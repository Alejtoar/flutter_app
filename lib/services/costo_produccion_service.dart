import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/costo_produccion.dart';

class CostoProduccionService {
  final FirebaseFirestore _db;
  final String _coleccion = 'costos_produccion';

  CostoProduccionService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<CostoProduccion> crearCostoProduccion(CostoProduccion costo) async {
    try {
      final docRef = await _db.collection(_coleccion).add(costo.toFirestore());
      return costo.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<CostoProduccion> obtenerCostoProduccion(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Costo de producción no encontrado');
      return CostoProduccion.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<CostoProduccion>> obtenerCostosPorEvento(String eventoId) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => CostoProduccion.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<CostoProduccion>> obtenerCostosPorRango(DateTime inicio, DateTime fin) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('fechaCreacion', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fechaCreacion', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .orderBy('fechaCreacion', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => CostoProduccion.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarCostoProduccion(CostoProduccion costo) async {
    try {
      if (costo.id == null) throw Exception('ID de costo no válido');
      await _db.collection(_coleccion).doc(costo.id).update(costo.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Map<String, double>> obtenerEstadisticasCostos(DateTime inicio, DateTime fin) async {
    try {
      final costos = await obtenerCostosPorRango(inicio, fin);
      
      if (costos.isEmpty) {
        return {
          'costoDirectoTotal': 0,
          'costoIndirectoTotal': 0,
          'costosIndirectosTotal': 0,
          'costoTotal': 0,
          'ventaTotal': 0,
          'margenTotal': 0,
          'margenPromedio': 0,
        };
      }

      double costoDirectoTotal = 0;
      double costoIndirectoTotal = 0;
      double costosIndirectosTotal = 0;
      double costoTotal = 0;
      double ventaTotal = 0;
      double margenTotal = 0;

      for (var costo in costos) {
        costoDirectoTotal += costo.costoDirecto;
        costoIndirectoTotal += costo.costoIndirecto;
        costosIndirectosTotal += costo.costosIndirectos;
        costoTotal += costo.costoTotal;
        ventaTotal += costo.precioVenta;
        margenTotal += costo.margenGanancia;
      }

      return {
        'costoDirectoTotal': costoDirectoTotal,
        'costoIndirectoTotal': costoIndirectoTotal,
        'costosIndirectosTotal': costosIndirectosTotal,
        'costoTotal': costoTotal,
        'ventaTotal': ventaTotal,
        'margenTotal': margenTotal,
        'margenPromedio': margenTotal / costos.length,
      };
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Costo de producción no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}
