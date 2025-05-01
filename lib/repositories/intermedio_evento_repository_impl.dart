// lib/repositories/intermedio_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:golo_app/models/intermedio_evento.dart'; // Ajusta la ruta si es necesario
import 'package:golo_app/repositories/intermedio_evento_repository.dart'; // Ajusta la ruta si es necesario

class IntermedioEventoFirestoreRepository implements IntermedioEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios_eventos'; // Nombre de la colección en Firestore

  IntermedioEventoFirestoreRepository(this._db);

  @override
  Future<IntermedioEvento> crear(IntermedioEvento relacion) async {
    if (relacion.eventoId.isEmpty || relacion.intermedioId.isEmpty) {
      throw ArgumentError('eventoId y intermedioId son requeridos para crear la relación IntermedioEvento.');
    }
    try {
      final data = relacion.toFirestore(); // No incluye el 'id' de Firestore
      final docRef = await _db.collection(_coleccion).add(data);
      if (kDebugMode) {
        print('Relación IntermedioEvento creada con ID: ${docRef.id} para evento ${relacion.eventoId}');
      }
      return relacion.copyWith(id: docRef.id); // Devuelve con el ID asignado
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'crear');
    } catch (e) {
       throw Exception('Error inesperado al crear relación IntermedioEvento: $e');
    }
  }

  @override
  Future<IntermedioEvento> obtener(String id) async {
     if (id.isEmpty) throw ArgumentError('Se requiere un ID para obtener la relación IntermedioEvento.');
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) {
        throw Exception('Relación IntermedioEvento con ID $id no encontrada.');
      }
      return IntermedioEvento.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtener', id: id);
    } catch (e) {
      if (e is Exception && e.toString().contains('no encontrada')) rethrow;
       throw Exception('Error inesperado al obtener relación IntermedioEvento $id: $e');
    }
  }

  @override
  Future<void> actualizar(IntermedioEvento relacion) async {
    if (relacion.id == null || relacion.id!.isEmpty) {
      throw ArgumentError('La relación IntermedioEvento debe tener un ID para ser actualizada.');
    }
    try {
      final data = relacion.toFirestore(); // Obtiene todos los campos actualizables
      await _db.collection(_coleccion).doc(relacion.id!).update(data);
      if (kDebugMode) {
        print('Relación IntermedioEvento actualizada con ID: ${relacion.id}');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw Exception('No se pudo actualizar: Relación IntermedioEvento con ID ${relacion.id} no encontrada.');
      }
      throw _handleFirestoreError(e, 'actualizar', id: relacion.id);
    } catch (e) {
       throw Exception('Error inesperado al actualizar relación IntermedioEvento ${relacion.id}: $e');
    }
  }

  @override
  Future<void> eliminar(String id) async {
    if (id.isEmpty) throw ArgumentError('Se requiere un ID para eliminar la relación IntermedioEvento.');
    try {
      await _db.collection(_coleccion).doc(id).delete();
       if (kDebugMode) {
        print('Relación IntermedioEvento eliminada con ID: $id');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
         if (kDebugMode) print('Advertencia: Se intentó eliminar la relación IntermedioEvento $id, pero no se encontró.');
         return;
      }
      throw _handleFirestoreError(e, 'eliminar', id: id);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relación IntermedioEvento $id: $e');
    }
  }

  @override
  Future<List<IntermedioEvento>> obtenerPorEvento(String eventoId) async {
     if (eventoId.isEmpty){
        if (kDebugMode) print('Se solicitó obtener IntermedioEvento por eventoId vacío.');
        return [];
     }
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .get();
      return querySnapshot.docs.map((doc) => IntermedioEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtenerPorEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones IntermedioEvento por evento $eventoId: $e');
    }
  }

  @override
  Future<List<IntermedioEvento>> obtenerPorIntermedio(String intermedioId) async {
    if (intermedioId.isEmpty){
        if (kDebugMode) print('Se solicitó obtener IntermedioEvento por intermedioId vacío.');
        return [];
     }
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('intermedioId', isEqualTo: intermedioId)
          .get();
      return querySnapshot.docs.map((doc) => IntermedioEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'obtenerPorIntermedio', intermedioId: intermedioId);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones IntermedioEvento por intermedio $intermedioId: $e');
    }
  }

  @override
  Future<void> reemplazarIntermediosDeEvento(String eventoId, List<IntermedioEvento> nuevosIntermedios) async {
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para reemplazar intermedios.');
    try {
      final batch = _db.batch();

      // 1. Obtener y marcar para eliminar todas las relaciones existentes para este evento
      final querySnapshot = await _db.collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .get();
      int eliminados = 0;
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        eliminados++;
        if (kDebugMode) print('[IntermedioEvento Batch] Marcando para eliminar relación existente: ${doc.id}');
      }

      // 2. Marcar para añadir las nuevas relaciones
      int anadidos = 0;
      for (final intermedioEvento in nuevosIntermedios) {
         // Validar que el intermedio a añadir tenga ID
        if (intermedioEvento.intermedioId.isEmpty) {
           if (kDebugMode) print('[IntermedioEvento Batch] Omitiendo intermedio sin intermedioId en la lista de nuevosIntermedios.');
           continue; // Saltar este item si no tiene intermedioId
        }
        final data = intermedioEvento.copyWith(eventoId: eventoId).toFirestore();
        final docRef = _db.collection(_coleccion).doc(); // Genera nuevo ID para la relación
        batch.set(docRef, data);
        anadidos++;
        if (kDebugMode) print('[IntermedioEvento Batch] Marcando para añadir nueva relación para intermedioId: ${intermedioEvento.intermedioId} (nuevo doc ID: ${docRef.id})');
      }

      // 3. Ejecutar todas las operaciones en el batch
      await batch.commit();
       if (kDebugMode) {
        print('Batch commit exitoso para reemplazar IntermedioEvento del evento $eventoId. Eliminados: $eliminados, Añadidos: $anadidos');
      }

    } on FirebaseException catch (e) {
       throw _handleFirestoreError(e, 'reemplazarIntermediosDeEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al reemplazar relaciones IntermedioEvento para evento $eventoId: $e');
    }
  }

  @override
  Future<bool> existeRelacion(String intermedioId, String eventoId) async {
    if (intermedioId.isEmpty || eventoId.isEmpty) return false;
    try {
      final query = await _db.collection(_coleccion)
          .where('intermedioId', isEqualTo: intermedioId)
          .where('eventoId', isEqualTo: eventoId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'existeRelacion', eventoId: eventoId, intermedioId: intermedioId);
    } catch (e) {
       throw Exception('Error inesperado al verificar existencia de relación IntermedioEvento: $e');
    }
  }

  @override
  Future<void> eliminarPorEvento(String eventoId) async {
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para eliminar IntermedioEvento por evento.');
    try {
      final batch = _db.batch();
      final querySnapshot = await _db.collection(_coleccion)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      if (querySnapshot.docs.isEmpty) {
         if (kDebugMode) print('No se encontraron IntermedioEvento para eliminar del evento $eventoId.');
         return;
      }

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
       if (kDebugMode) {
        print('${querySnapshot.docs.length} relaciones IntermedioEvento eliminadas para el evento $eventoId.');
      }
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e, 'eliminarPorEvento', eventoId: eventoId);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relaciones IntermedioEvento por evento $eventoId: $e');
    }
  }

  // --- Manejador de Errores ---
   Exception _handleFirestoreError(FirebaseException e, String operation, {String? id, String? eventoId, String? intermedioId}) {
    final contextInfo = 'Operación: $operation, ID: $id, EventoID: $eventoId, IntermedioID: $intermedioId';
    if (kDebugMode) {
      print("Firebase Error en IntermedioEventoRepo: ${e.code}, Message: ${e.message}. Contexto: $contextInfo");
    }
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para la operación "$operation" en relaciones IntermedioEvento.');
      case 'not-found':
        return Exception('Recurso no encontrado para la operación "$operation" en IntermedioEvento (ID: $id).');
      case 'unavailable':
         return Exception('Servicio Firestore no disponible durante la operación "$operation" en IntermedioEvento.');
      default:
        return Exception('Error de Firestore ($operation) en IntermedioEvento: ${e.message ?? e.code}');
    }
  }

  // Método crearMultiples eliminado ya que reemplazarIntermediosDeEvento lo cubre.
}