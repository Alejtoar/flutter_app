
// intermedio_requerido_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';

class IntermedioRequeridoFirestoreRepository implements IntermedioRequeridoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios_requeridos';

  IntermedioRequeridoFirestoreRepository(this._db);

  @override
  Future<IntermedioRequerido> crear(IntermedioRequerido relacion) async {
    try {
      // Verificar si la relación ya existe
      if (await existeRelacion(relacion.platoId, relacion.intermedioId)) {
        throw Exception('Esta relación plato-intermedio ya existe');
      }

      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<IntermedioRequerido> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return IntermedioRequerido.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(IntermedioRequerido relacion) async {
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
  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .get();
          
      return query.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<IntermedioRequerido>> obtenerPorIntermedio(String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('intermedioId', isEqualTo: intermedioId)
          .get();
          
      return query.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> reemplazarIntermediosDePlato(
    String platoId, 
    Map<String, double> nuevosIntermedios
  ) async {
    try {
      final batch = _db.batch();
      
      // 1. Eliminar relaciones existentes
      final relacionesExistentes = await obtenerPorPlato(platoId);
      for (final relacion in relacionesExistentes) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }
      
      // 2. Crear nuevas relaciones
      for (final entry in nuevosIntermedios.entries) {
        final nuevaRelacion = IntermedioRequerido(
          platoId: platoId,
          intermedioId: entry.key,
          cantidad: entry.value,
        );
        final docRef = _db.collection(_coleccion).doc();
        batch.set(docRef, nuevaRelacion.toFirestore());
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeRelacion(String platoId, String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .where('intermedioId', isEqualTo: intermedioId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorPlato(String platoId) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorPlato(platoId);

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