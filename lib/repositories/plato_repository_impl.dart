import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/repositories/plato_repository.dart';

class PlatoFirestoreRepository implements PlatoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos';

  PlatoFirestoreRepository(this._db);

  @override
  Future<Plato> crear(Plato plato) async {
    try {
      // Validación adicional
      if (await existeCodigo(plato.codigo)) {
        throw Exception('El código ${plato.codigo} ya está en uso');
      }

      final docRef = await _db.collection(_coleccion).add(plato.toFirestore());
      return plato.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Plato> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Plato no encontrado');
      return Plato.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerTodos({String? categoria}) async {
    try {
      Query query = _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .orderBy('nombre');

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
  Future<List<Plato>> obtenerVarios(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _db.collection(_coleccion)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Plato plato) async {
    try {
      await _db.collection(_coleccion)
          .doc(plato.id)
          .update(plato.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivar(String id) async {
    try {
      await _db.collection(_coleccion)
          .doc(id)
          .update({
            'activo': false,
            'fechaActualizacion': FieldValue.serverTimestamp()
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
  Future<List<Plato>> buscarPorNombre(String query) async {
    try {
      final regex = RegExp(query, caseSensitive: false);
      
      final snapshot = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .get();
          
      final docs = snapshot.docs.where((doc) {
        final nombre = doc.data()['nombre'] as String;
        return regex.hasMatch(nombre);
      });
      
      return docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<String> generarNuevoCodigo() async {
  try {
    String codigo;
    bool codigoExiste;
    int intentos = 0;
    const maxIntentos = 5;

    do {
      final count = await _db.collection(_coleccion).count().get();
      codigo = 'PC-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
      codigoExiste = await existeCodigo(codigo);
      intentos++;
      
      if (intentos > maxIntentos) {
        throw Exception('No se pudo generar un código único después de $maxIntentos intentos');
      }
    } while (codigoExiste);

    return codigo;
  } on FirebaseException catch (e) {
    throw _handleFirestoreError(e);
  }
}

  @override
  Future<bool> existeCodigo(String codigo) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategoria(String categoria) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContains: categoria)
          .where('activo', isEqualTo: true)
          .get();
          
      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategorias(List<String> categorias) async {
    try {
      if (categorias.isEmpty) return [];
      
      // Firestore no soporta arrayContainsAll nativamente, usamos arrayContainsAny
      // y filtramos localmente para obtener solo los que tienen TODAS las categorías
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContainsAny: categorias)
          .where('activo', isEqualTo: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => Plato.fromFirestore(doc))
          .where((plato) => categorias.every((c) => plato.categorias.contains(c)))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<DateTime?> obtenerFechaActualizacion(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
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