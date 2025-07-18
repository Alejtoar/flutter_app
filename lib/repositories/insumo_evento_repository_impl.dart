// lib/repositories/insumo_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:golo_app/models/insumo_evento.dart'; 
import 'package:golo_app/repositories/insumo_evento_repository.dart'; 
import 'package:golo_app/config/app_config.dart';

class InsumoEventoFirestoreRepository implements InsumoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_eventos'; 
  final bool _isMultiUser =
      AppConfig
          .instance
          .isMultiUser; 

  InsumoEventoFirestoreRepository(this._db);

  CollectionReference _getCollection({String? uid}) {
    if (_isMultiUser) {
      // Si es multi-usuario, DEBEMOS tener un uid.
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
  Future<InsumoEvento> crear(InsumoEvento relacion, {String? uid}) async {
    if (relacion.eventoId.isEmpty || relacion.insumoId.isEmpty) {
      throw ArgumentError('eventoId y insumoId son requeridos para crear la relación InsumoEvento.');
    }
    try {
      final data = relacion.toFirestore(); // No incluye el 'id' de Firestore
      final docRef = await _getCollection(uid: uid).add(data);
      if (kDebugMode) {
        debugPrint('Relación InsumoEvento creada con ID: ${docRef.id} para evento ${relacion.eventoId}');
      }
      return relacion.copyWith(id: docRef.id); // Devuelve con el ID asignado
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'crear');
    } catch (e) {
       throw Exception('Error inesperado al crear relación InsumoEvento: $e');
    }
  }

  @override
  Future<InsumoEvento> obtener(String id, {String? uid}) async {
     if (id.isEmpty) throw ArgumentError('Se requiere un ID para obtener la relación InsumoEvento.');
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) {
        throw Exception('Relación InsumoEvento con ID $id no encontrada.');
      }
      return InsumoEvento.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtener', id: id);
    } catch (e) {
      if (e is Exception && e.toString().contains('no encontrada')) rethrow;
       throw Exception('Error inesperado al obtener relación InsumoEvento $id: $e');
    }
  }

  @override
  Future<void> actualizar(InsumoEvento relacion, {String? uid}) async {
    if (relacion.id == null || relacion.id!.isEmpty) {
      throw ArgumentError('La relación InsumoEvento debe tener un ID para ser actualizada.');
    }
    try {
      final data = relacion.toFirestore(); // Obtiene todos los campos actualizables
      await _getCollection(uid: uid).doc(relacion.id!).update(data);
      if (kDebugMode) {
        print('Relación InsumoEvento actualizada con ID: ${relacion.id}');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw Exception('No se pudo actualizar: Relación InsumoEvento con ID ${relacion.id} no encontrada.');
      }
      throw _handleFirestoreError(e, 'actualizar', id: relacion.id);
    } catch (e) {
       throw Exception('Error inesperado al actualizar relación InsumoEvento ${relacion.id}: $e');
    }
  }

  @override
  Future<void> eliminar(String id, {String? uid}) async {
    if (id.isEmpty) throw ArgumentError('Se requiere un ID para eliminar la relación InsumoEvento.');
    try {
      await _getCollection(uid: uid).doc(id).delete();
       if (kDebugMode) {
        print('Relación InsumoEvento eliminada con ID: $id');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
         if (kDebugMode) print('Advertencia: Se intentó eliminar la relación InsumoEvento $id, pero no se encontró.');
         return;
      }
      throw _handleFirestoreError(e, 'eliminar', id: id);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relación InsumoEvento $id: $e');
    }
  }

  @override
  Future<List<InsumoEvento>> obtenerPorEvento(String eventoId, {String? uid}) async {
     if (eventoId.isEmpty){
        if (kDebugMode) print('Se solicitó obtener InsumoEvento por eventoId vacío.');
        return [];
     }
    try {
      final querySnapshot = await _getCollection(uid: uid).where('eventoId', isEqualTo: eventoId).get();
      return querySnapshot.docs.map((doc) => InsumoEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtenerPorEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones InsumoEvento por evento $eventoId: $e');
    }
  }

  @override
  Future<List<InsumoEvento>> obtenerPorInsumo(String insumoId, {String? uid}) async {
    if (insumoId.isEmpty){
        if (kDebugMode) print('Se solicitó obtener InsumoEvento por insumoId vacío.');
        return [];
     }
    try {
      final querySnapshot = await _getCollection(uid: uid).where('insumoId', isEqualTo: insumoId).get();
      return querySnapshot.docs.map((doc) => InsumoEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtenerPorInsumo', insumoId: insumoId);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones InsumoEvento por insumo $insumoId: $e');
    }
  }

  @override
  Future<void> reemplazarInsumosDeEvento(String eventoId, List<InsumoEvento> nuevosInsumos, {String? uid}) async {
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para reemplazar insumos.');
    try {
      final batch = _db.batch();

      // 1. Obtener y marcar para eliminar todas las relaciones existentes para este evento
      final querySnapshot = await _getCollection(uid: uid).where('eventoId', isEqualTo: eventoId).get();
      int eliminados = 0;
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        eliminados++;
        if (kDebugMode) print('[InsumoEvento Batch] Marcando para eliminar relación existente: ${doc.id}');
      }

      // 2. Marcar para añadir las nuevas relaciones
      int anadidos = 0;
      for (final insumoEvento in nuevosInsumos) {
        // Validar que el insumo a añadir tenga ID
        if (insumoEvento.insumoId.isEmpty) {
           if (kDebugMode) print('[InsumoEvento Batch] Omitiendo insumo sin insumoId en la lista de nuevosInsumos.');
           continue; // Saltar este item si no tiene insumoId
        }
        final data = insumoEvento.copyWith(eventoId: eventoId).toFirestore();
        final docRef = _getCollection(uid: uid).doc(); // Genera nuevo ID para la relación
        batch.set(docRef, data);
        anadidos++;
        if (kDebugMode) print('[InsumoEvento Batch] Marcando para añadir nueva relación para insumoId: ${insumoEvento.insumoId} (nuevo doc ID: ${docRef.id})');
      }

      // 3. Ejecutar todas las operaciones en el batch
      await batch.commit();
       if (kDebugMode) {
        print('Batch commit exitoso para reemplazar InsumoEvento del evento $eventoId. Eliminados: $eliminados, Añadidos: $anadidos');
      }

    } on FirebaseException catch (e) {
       throw _handleFirestoreError(e, 'reemplazarInsumosDeEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al reemplazar relaciones InsumoEvento para evento $eventoId: $e');
    }
  }

  @override
  Future<bool> existeRelacion(String insumoId, String eventoId, {String? uid}) async {
    if (insumoId.isEmpty || eventoId.isEmpty) return false;
    try {
      final query = await _getCollection(uid: uid)
          .where('insumoId', isEqualTo: insumoId)
          .where('eventoId', isEqualTo: eventoId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'existeRelacion', eventoId: eventoId, insumoId: insumoId);
    } catch (e) {
       throw Exception('Error inesperado al verificar existencia de relación InsumoEvento: $e');
    }
  }

  @override
  Future<void> eliminarPorEvento(String eventoId, {String? uid}) async {
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para eliminar InsumoEvento por evento.');
    try {
      final batch = _db.batch();
      final querySnapshot = await _getCollection(uid: uid)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      if (querySnapshot.docs.isEmpty) {
         if (kDebugMode) print('No se encontraron InsumoEvento para eliminar del evento $eventoId.');
         return;
      }

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
       if (kDebugMode) {
        print('${querySnapshot.docs.length} relaciones InsumoEvento eliminadas para el evento $eventoId.');
      }
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'eliminarPorEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relaciones InsumoEvento por evento $eventoId: $e');
    }
  }

  // --- Manejador de Errores ---
   Exception _handleFirestoreError(FirebaseException e, String operation, {String? id, String? eventoId, String? insumoId}) {
    final contextInfo = 'Operación: $operation, ID: $id, EventoID: $eventoId, InsumoID: $insumoId';
    if (kDebugMode) {
      print("Firebase Error en InsumoEventoRepo: ${e.code}, Message: ${e.message}. Contexto: $contextInfo");
    }
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para la operación "$operation" en relaciones InsumoEvento.');
      case 'not-found':
        return Exception('Recurso no encontrado para la operación "$operation" en InsumoEvento (ID: $id).');
      case 'unavailable':
         return Exception('Servicio Firestore no disponible durante la operación "$operation" en InsumoEvento.');
      default:
        return Exception('Error de Firestore ($operation) en InsumoEvento: ${e.message ?? e.code}');
    }
  }

  // Método crearMultiples eliminado ya que reemplazarInsumosDeEvento lo cubre.
}