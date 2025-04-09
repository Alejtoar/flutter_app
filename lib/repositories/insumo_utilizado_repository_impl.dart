import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';

class InsumoUtilizadoFirestoreRepository implements InsumoUtilizadoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_utilizados';

  InsumoUtilizadoFirestoreRepository(this._db);

  @override
  Future<InsumoUtilizado> crear(InsumoUtilizado relacion) async {
    try {
      // Verificar si la relación ya existe
      if (await existeRelacion(relacion.insumoId, relacion.intermedioId)) {
        throw Exception('Esta relación insumo-intermedio ya existe');
      }

      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<InsumoUtilizado> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return InsumoUtilizado.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(InsumoUtilizado relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update(relacion.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoUtilizado>> obtenerPorIntermedio(String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('intermedioId', isEqualTo: intermedioId)
          .get();
          
      return query.docs.map((doc) => InsumoUtilizado.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoUtilizado>> obtenerPorInsumo(String insumoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('insumoId', isEqualTo: insumoId)
          .get();
          
      return query.docs.map((doc) => InsumoUtilizado.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> crearMultiples(List<InsumoUtilizado> relaciones) async {
    try {
      final batch = _db.batch();
      
      for (final relacion in relaciones) {
        final docRef = _db.collection(_coleccion).doc();
        batch.set(docRef, relacion.toFirestore());
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizarCantidades(
    String intermedioId, 
    Map<String, double> cantidadesPorInsumo
  ) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorIntermedio(intermedioId);

      for (final relacion in relaciones) {
        if (cantidadesPorInsumo.containsKey(relacion.insumoId)) {
          final docRef = _db.collection(_coleccion).doc(relacion.id);
          batch.update(docRef, {
            'cantidad': cantidadesPorInsumo[relacion.insumoId],
            'fechaActualizacion': FieldValue.serverTimestamp()
          });
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeRelacion(String insumoId, String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('insumoId', isEqualTo: insumoId)
          .where('intermedioId', isEqualTo: intermedioId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorIntermedio(String intermedioId) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorIntermedio(intermedioId);

      for (final relacion in relaciones) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a estas relaciones');
      case 'not-found':
        return Exception('Relación no encontrada');
      case 'invalid-argument':
        return Exception('Datos de relación no válidos');
      default:
        return Exception('Error al acceder a las relaciones: ${e.message}');
    }
  }
}