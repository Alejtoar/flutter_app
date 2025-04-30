import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';
import '../models/insumo_evento.dart';

class InsumoEventoFirestoreRepository implements InsumoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_eventos';

  InsumoEventoFirestoreRepository(this._db);

  @override
  Future<InsumoEvento> crear(InsumoEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add({
        'eventoId': relacion.eventoId,
        'insumoId': relacion.insumoId,
        'cantidad': relacion.cantidad,
      });
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<InsumoEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return InsumoEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(InsumoEvento relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update({'cantidad': relacion.cantidad});
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
  Future<List<InsumoEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => InsumoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<InsumoEvento>> obtenerPorInsumo(String insumoId) async {
    final query = await _db.collection(_coleccion)
        .where('insumoId', isEqualTo: insumoId)
        .get();
    return query.docs
        .map((doc) => InsumoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> crearMultiples(String eventoId, List<InsumoEvento> relaciones) async {
    final batch = _db.batch();
    for (final relacion in relaciones) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, {
        'eventoId': eventoId,
        'insumoId': relacion.insumoId,
        'cantidad': relacion.cantidad,
      });
    }
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String insumoId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('insumoId', isEqualTo: insumoId)
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