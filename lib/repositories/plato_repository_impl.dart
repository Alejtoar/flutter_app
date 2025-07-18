//plato_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/config/app_config.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/exceptions/plato_en_uso_exception.dart';

class PlatoFirestoreRepository implements PlatoRepository {
  final FirebaseFirestore _db;
  static const String _coleccionPlatos = 'platos';
  static const String _coleccionPlatosEventos = 'platos_eventos';
  final bool _isMultiUser =
      AppConfig
          .instance
          .isMultiUser; //aca ya inicie la var pero aun no lo cambio todo

  PlatoFirestoreRepository(this._db);

  CollectionReference _getPlatosCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) throw Exception("UID es requerido en modo multi-usuario.");
      return _db.collection('usuarios').doc(uid).collection(_coleccionPlatos);
    } else {
      return _db.collection(_coleccionPlatos);
    }
  }

  // Helper para la colección de eventos (necesario para la verificación en eliminar)
  Query _getPlatosEventosCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) throw Exception("UID es requerido en modo multi-usuario.");
      return _db.collection('usuarios').doc(uid).collection(_coleccionPlatosEventos);
    } else {
      return _db.collection(_coleccionPlatosEventos);
    }
  }

  @override
  Future<Plato> crear(Plato plato, {String? uid}) async {
    try {
      final docRef = await _getPlatosCollection(uid: uid).add(plato.toFirestore());
      return plato.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Plato> obtener(String id, {String? uid}) async {
    try {
      final doc = await _getPlatosCollection(uid: uid).doc(id).get();
      if (!doc.exists) throw Exception('Plato no encontrado');
      return Plato.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerTodos({String? categoria, String? uid}) async {
    try {
      Query query = _getPlatosCollection(uid: uid);

      if (categoria != null) {
        query = query.where('categorias', arrayContains: categoria);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerVarios(List<String> ids, {String? uid}) async {
    try {
      if (ids.isEmpty) return [];

      final query =
          await _getPlatosCollection(uid: uid)
              .where(FieldPath.documentId, whereIn: ids)
              .where('activo', isEqualTo: true)
              .get();

      return query.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Plato plato, {String? uid}) async {
    try {
      await _getPlatosCollection(uid: uid).doc(plato.id).update(plato.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivar(String id, {String? uid}) async {
    try {
      await _getPlatosCollection(uid: uid).doc(id).update({
        'activo': false,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id, {String? uid}) async {
    // La única responsabilidad de este método es verificar si el plato
    // está siendo usado por un objeto de nivel superior, como un Evento.
    final usos = <String>[];
    
    // 1. Verificar si el plato está en uso en algún Evento
    final eventosSnap = await _getPlatosEventosCollection(uid: uid)
        .where('platoId', isEqualTo: id) // Asumiendo que platosId es un array
        .limit(1)
        .get();

    if (eventosSnap.docs.isNotEmpty) {
      usos.add('Eventos');
    }

    // Puedes añadir más verificaciones aquí en el futuro si otro objeto
    // de nivel superior empieza a usar Platos (ej. un "Menú Fijo").

    // 2. Si se encontró algún uso, lanzar la excepción y no borrar
    if (usos.isNotEmpty) {
      debugPrint("Intento de eliminar el plato $id falló. En uso en: ${usos.join(', ')}");
      // Esta excepción será capturada por el PlatoController
      throw PlatoEnUsoException(usos);
    }
    
    // 3. Si no está en uso, proceder con la eliminación del documento del plato.
    // La limpieza de las relaciones (insumos_requeridos, etc.) la hará el Controller.
    try {
      debugPrint("Plato $id no está en uso por objetos superiores. Eliminando documento del plato...");
      await _getPlatosCollection(uid: uid).doc(id).delete();
    } on FirebaseException catch (e) {
      // Re-lanzar como una excepción manejable
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> buscarPorNombre(String query, {String? uid}) async {
    try {
      final regex = RegExp(query, caseSensitive: false);

      final snapshot =
          await _getPlatosCollection(uid: uid).where('activo', isEqualTo: true).get();

      final docs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null || data['nombre'] == null) {
          return false;
        }

        final nombre = data['nombre'] as String;

        
        return regex.hasMatch(nombre);
      });

      return docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<String> generarNuevoCodigo({String? uid}) async {
    try {
      String codigo;
      bool codigoExiste;
      int intentos = 0;
      const maxIntentos = 5;

      do {
        final count = await _getPlatosCollection(uid: uid).count().get();
        codigo =
            'PC-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
        codigoExiste = await existeCodigo(codigo, uid: uid);
        intentos++;

        if (intentos > maxIntentos) {
          throw Exception(
            'No se pudo generar un código único después de $maxIntentos intentos',
          );
        }
      } while (codigoExiste);

      return codigo;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeCodigo(String codigo, {String? uid}) async {
    try {
      final query =
          await _getPlatosCollection(uid: uid)
              .where('codigo', isEqualTo: codigo)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategoria(String categoria, {String? uid}) async {
    try {
      final querySnapshot =
          await _getPlatosCollection(uid: uid)
              .where('categorias', arrayContains: categoria)
              .where('activo', isEqualTo: true)
              .get();

      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategorias(List<String> categorias, {String? uid}) async {
    try {
      if (categorias.isEmpty) return [];

      // Firestore no soporta arrayContainsAll nativamente, usamos arrayContainsAny
      // y filtramos localmente para obtener solo los que tienen TODAS las categorías
      final querySnapshot =
          await _getPlatosCollection(uid: uid)
              .where('categorias', arrayContainsAny: categorias)
              .where('activo', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Plato.fromFirestore(doc))
          .where(
            (plato) => categorias.every((c) => plato.categorias.contains(c)),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<DateTime?> obtenerFechaActualizacion(String id, {String? uid}) async {
    try {
      final doc = await _getPlatosCollection(uid: uid).doc(id).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return data['fechaActualizacion']?.toDate();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a los platos');
      case 'not-found':
        return Exception('Plato no encontrado');
      case 'invalid-argument':
        return Exception('Datos del plato no válidos');
      default:
        return Exception('Error al acceder a los platos: ${e.message}');
    }
  }
}
