// insumo_requerido_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/repositories/insumo_requerido_repository.dart';
import 'package:golo_app/config/app_config.dart';

class InsumoRequeridoFirestoreRepository implements InsumoRequeridoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_requeridos';
  final bool _isMultiUser =
      AppConfig.instance.isMultiUser;

  InsumoRequeridoFirestoreRepository(this._db);

  CollectionReference _getCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) {
        throw Exception(
          "UID de usuario es requerido para operaciones en modo multi-usuario.",
        );
      }
      // Construye la ruta anidada
      return _db.collection('usuarios').doc(uid).collection(_coleccion);
    } else {
      // Si no, usamos la colección a nivel raíz.
      return _db.collection(_coleccion);
    }
  }

  @override
  Future<InsumoRequerido> crear(InsumoRequerido relacion, {String? uid}) async {
    try {
      if (await existeRelacion(relacion.platoId, relacion.insumoId, uid: uid)) {
        throw Exception('Esta relación plato-insumo ya existe');
      }
      final docRef = await _getCollection(uid: uid).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<InsumoRequerido> obtener(String id, {String? uid}) async {
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return InsumoRequerido.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(InsumoRequerido relacion, {String? uid}) async {
    try {
      await _getCollection(uid: uid).doc(relacion.id).update(relacion.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id, {String? uid}) async {
    try {
      await _getCollection(uid: uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoRequerido>> obtenerPorPlato(String platoId, {String? uid}) async {
    try {
      final query = await _getCollection(uid: uid)
          .where('platoId', isEqualTo: platoId)
          .get();
      return query.docs.map((doc) => InsumoRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoRequerido>> obtenerPorInsumo(String insumoId, {String? uid}) async {
    try {
      final query = await _getCollection(uid: uid)
          .where('insumoId', isEqualTo: insumoId)
          .get();
      return query.docs.map((doc) => InsumoRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> reemplazarInsumosDePlato(
    String platoId,
    Map<String, double> nuevosInsumos,
    {String? uid}
  ) async {
    try {
      final batch = _db.batch();
      // 1. Eliminar relaciones existentes
      final relacionesExistentes = await obtenerPorPlato(platoId, uid: uid);
      for (final relacion in relacionesExistentes) {
        batch.delete(_getCollection(uid: uid).doc(relacion.id));
      }
      // 2. Crear nuevas relaciones
      for (final entry in nuevosInsumos.entries) {
        final nuevaRelacion = InsumoRequerido(
          platoId: platoId,
          insumoId: entry.key,
          cantidad: entry.value,
        );
        final docRef = _getCollection(uid: uid).doc();
        batch.set(docRef, nuevaRelacion.toFirestore());
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeRelacion(String platoId, String insumoId, {String? uid}) async {
    try {
      final query = await _getCollection(uid: uid)
          .where('platoId', isEqualTo: platoId)
          .where('insumoId', isEqualTo: insumoId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorPlato(String platoId, {String? uid}) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorPlato(platoId, uid: uid);
      for (final relacion in relaciones) {
        batch.delete(_getCollection(uid: uid).doc(relacion.id));
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
