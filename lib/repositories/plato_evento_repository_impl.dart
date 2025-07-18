// plato_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:golo_app/repositories/plato_evento_repository.dart'; // Asegúrate que la interfaz abstracta exista
import '../models/plato_evento.dart';
import 'package:golo_app/config/app_config.dart';

// Asumiendo que tienes una interfaz PlatoEventoRepository definida
// abstract class PlatoEventoRepository { ... }

class PlatoEventoFirestoreRepository implements PlatoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos_eventos'; // Colección para la relación
  final bool _isMultiUser =
      AppConfig
          .instance
          .isMultiUser; //aca ya inicie la var pero aun no lo cambio todo

  PlatoEventoFirestoreRepository(this._db);

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
  Future<PlatoEvento> crear(PlatoEvento relacion, {String? uid}) async {
    // No deberíamos permitir crear una relación sin IDs válidos
    if (relacion.eventoId.isEmpty || relacion.platoId.isEmpty) {
      throw ArgumentError('eventoId y platoId son requeridos para crear la relación.');
    }
    try {
      // Usar el toFirestore del modelo, que no incluye el 'id' de la relación
      final data = relacion.toFirestore();
      final docRef = await _getCollection(uid: uid).add(data);
      if (kDebugMode) {
        print('Relación PlatoEvento creada con ID: ${docRef.id}');
      }
      // Devolver la relación original con el nuevo ID asignado por Firestore
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al crear relación PlatoEvento: $e');
    }
  }

  @override
  Future<PlatoEvento> obtener(String id, {String? uid}) async {
     if (id.isEmpty) throw ArgumentError('Se requiere un ID para obtener la relación.');
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) {
        throw Exception('Relación PlatoEvento con ID $id no encontrada.');
      }
      // Usamos fromFirestore que ahora está en el modelo
      return PlatoEvento.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      if (e is Exception && e.toString().contains('no encontrada')) rethrow;
       throw Exception('Error inesperado al obtener relación PlatoEvento $id: $e');
    }
  }

  @override
  Future<void> actualizar(PlatoEvento relacion, {String? uid} ) async {
    if (relacion.id == null || relacion.id!.isEmpty) {
      throw ArgumentError('La relación debe tener un ID para ser actualizada.');
    }
    try {
      // Usar toFirestore, que incluye todos los campos personalizables
      final data = relacion.toFirestore();
      await _getCollection(uid: uid).doc(relacion.id!).update(data);
      if (kDebugMode) {
        print('Relación PlatoEvento actualizada con ID: ${relacion.id}');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw Exception('No se pudo actualizar: Relación PlatoEvento con ID ${relacion.id} no encontrada.');
      }
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al actualizar relación PlatoEvento ${relacion.id}: $e');
    }
  }

  @override
  Future<void> eliminar(String id, {String? uid}) async {
    if (id.isEmpty) throw ArgumentError('Se requiere un ID para eliminar la relación.');
    try {
      await _getCollection(uid: uid).doc(id).delete();
       if (kDebugMode) {
        print('Relación PlatoEvento eliminada con ID: $id');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
         print('Advertencia: Se intentó eliminar la relación PlatoEvento $id, pero no se encontró.');
         return; // No es necesariamente un error fatal
      }
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relación PlatoEvento $id: $e');
    }
  }

  @override
  Future<List<PlatoEvento>> obtenerPorEvento(String eventoId, {String? uid}) async {
     if (eventoId.isEmpty) return []; // Devolver lista vacía si no hay eventoId
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('eventoId', isEqualTo: eventoId)
          .get();
      return querySnapshot.docs.map((doc) => PlatoEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones PlatoEvento por evento $eventoId: $e');
    }
  }

  @override
  Future<List<PlatoEvento>> obtenerPorPlato(String platoId, {String? uid}) async {
    if (platoId.isEmpty) return [];
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('platoId', isEqualTo: platoId)
          .get();
      return querySnapshot.docs.map((doc) => PlatoEvento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al obtener relaciones PlatoEvento por plato $platoId: $e');
    }
  }

  // --- Método Clave: Reemplazo Atómico ---
  @override
  Future<void> reemplazarPlatosDeEvento(String eventoId, List<PlatoEvento> nuevosPlatos, {String? uid}) async {
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para reemplazar platos.');
    try {
      final batch = _db.batch();

      // 1. Obtener y marcar para eliminar todas las relaciones existentes para este evento
      final querySnapshot = await _getCollection(uid: uid)
          .where('eventoId', isEqualTo: eventoId)
          .get();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
         if (kDebugMode) print('Marcando para eliminar PlatoEvento existente: ${doc.id}');
      }

      // 2. Marcar para añadir las nuevas relaciones
      for (final platoEvento in nuevosPlatos) {
        // Asegurarse de que el eventoId sea el correcto y obtener los datos
        final data = platoEvento.copyWith(eventoId: eventoId).toFirestore();
        // Crear una referencia a un nuevo documento en la colección
        final docRef = _getCollection(uid: uid).doc();
        batch.set(docRef, data);
         if (kDebugMode) print('Marcando para añadir nuevo PlatoEvento para platoId: ${platoEvento.platoId}');
      }

      // 3. Ejecutar todas las operaciones en el batch
      await batch.commit();
       if (kDebugMode) {
        print('Batch commit exitoso para reemplazar PlatosEvento del evento $eventoId');
      }

    } on FirebaseException catch (e) {
       if (kDebugMode) print('Error Firebase durante batch de reemplazo PlatoEvento: ${e.code}');
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) print('Error general durante batch de reemplazo PlatoEvento: $e');
       throw Exception('Error inesperado al reemplazar relaciones PlatoEvento para evento $eventoId: $e');
    }
  }

  @override
  Future<bool> existeRelacion(String platoId, String eventoId, {String? uid}) async {
    if (platoId.isEmpty || eventoId.isEmpty) return false;
    try {
      final query = await _getCollection(uid: uid)
          .where('platoId', isEqualTo: platoId)
          .where('eventoId', isEqualTo: eventoId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorEvento(String eventoId, {String? uid}) async {
    // Este método es básicamente lo que hace la primera parte de reemplazarPlatosDeEvento
     if (eventoId.isEmpty) throw ArgumentError('Se requiere un eventoId para eliminar por evento.');
    try {
      final batch = _db.batch();
      final querySnapshot = await _getCollection(uid: uid)
          .where('eventoId', isEqualTo: eventoId)
          .get();

      if (querySnapshot.docs.isEmpty) {
         if (kDebugMode) print('No se encontraron PlatoEvento para eliminar del evento $eventoId.');
         return; // No hay nada que eliminar
      }

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
       if (kDebugMode) {
        print('${querySnapshot.docs.length} relaciones PlatoEvento eliminadas para el evento $eventoId.');
      }
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al eliminar relaciones PlatoEvento por evento $eventoId: $e');
    }
  }

  // --- Manejador de Errores ---
   Exception _handleFirestoreError(FirebaseException e) {
    if (kDebugMode) {
      print("Firebase Error Code: ${e.code}, Message: ${e.message}");
    }
    // Simplificado, puedes añadir más códigos si es necesario
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a las relaciones PlatoEvento.');
      case 'not-found':
        return Exception('Recurso no encontrado en Firestore (relación PlatoEvento).');
      case 'unavailable':
         return Exception('Servicio Firestore no disponible.');
      default:
        return Exception('Error de Firestore al operar con PlatoEvento: ${e.message ?? e.code}');
    }
  }

  // Eliminar crearMultiples si ya tienes reemplazarPlatosDeEvento,
  // ya que reemplazar cubre el caso de creación inicial (elimina 0 y añade los nuevos).
  // Si necesitas específicamente añadir sin borrar, mantenlo, pero reemplazar es más común para editar.

  /*
  @override
  Future<void> crearMultiples(String eventoId, List<PlatoEvento> relaciones) async {
    // ... implementación si la necesitas ...
  }
  */
}