import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/plato_evento_repository.dart';
import '../models/plato_evento.dart';

class PlatoEventoFirestoreRepository implements PlatoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos_eventos';

  PlatoEventoFirestoreRepository(this._db);

  @override
  Future<PlatoEvento> crear(PlatoEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<PlatoEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return PlatoEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(PlatoEvento relacion) async {
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
  Future<List<PlatoEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => PlatoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<PlatoEvento>> obtenerPorPlato(String platoId) async {
    final query = await _db.collection(_coleccion)
        .where('platoId', isEqualTo: platoId)
        .get();
    return query.docs
        .map((doc) => PlatoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> reemplazarPlatosDeEvento(
    String eventoId, 
    List<PlatoEvento> nuevosPlatosEvento
  ) async {
    final batch = _db.batch();
    
    // Eliminar relaciones existentes
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    
    // Crear nuevas relaciones
    for (final platoEvento in nuevosPlatosEvento) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, platoEvento.toFirestore());
    }
    
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String platoId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('platoId', isEqualTo: platoId)
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