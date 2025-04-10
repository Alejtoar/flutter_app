import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';
import '../models/intermedio_evento.dart';

class IntermedioEventoFirestoreRepository implements IntermedioEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios_eventos';

  IntermedioEventoFirestoreRepository(this._db);

  @override
  Future<IntermedioEvento> crear(IntermedioEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add({
        'eventoId': relacion.eventoId,
        'intermedioId': relacion.intermedioId,
        'cantidad': relacion.cantidad,
      });
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<IntermedioEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return IntermedioEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(IntermedioEvento relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update({
            'cantidad': relacion.cantidad,
          });
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
  Future<List<IntermedioEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => IntermedioEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<IntermedioEvento>> obtenerPorIntermedio(String intermedioId) async {
    final query = await _db.collection(_coleccion)
        .where('intermedioId', isEqualTo: intermedioId)
        .get();
    return query.docs
        .map((doc) => IntermedioEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> reemplazarIntermediosDeEvento(
    String eventoId, 
    List<String> nuevosIntermediosIds
  ) async {
    final batch = _db.batch();
    
    // Eliminar relaciones existentes
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    
    // Crear nuevas relaciones
    for (final intermedioId in nuevosIntermediosIds) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, {
        'eventoId': eventoId,
        'intermedioId': intermedioId,
        'cantidad': 1, // Valor por defecto
      });
    }
    
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String intermedioId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('intermedioId', isEqualTo: intermedioId)
        .where('eventoId', isEqualTo: eventoId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Future<void> eliminarPorEvento(String eventoId) async {
    final batch = _db.batch();
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    await batch.commit();
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a Firestore');
      case 'not-found':
        return Exception('Documento no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}