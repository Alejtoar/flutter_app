import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import '../models/intermedio.dart';

class IntermedioFirestoreRepository implements IntermedioRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios';

  IntermedioFirestoreRepository(this._db);

  @override
  Future<Intermedio> crear(Intermedio intermedio) async {
    try {
      // Validar unicidad del código
      if (await existeCodigo(intermedio.codigo)) {
        throw Exception('El código ${intermedio.codigo} ya está registrado');
      }
      
      final docRef = await _db.collection(_coleccion).add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Intermedio> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Intermedio no encontrado');
      return Intermedio.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Intermedio>> obtenerTodos() async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      return querySnapshot.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Intermedio>> obtenerPorIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _db.collection(_coleccion)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Intermedio intermedio) async {
    try {
      await _db.collection(_coleccion)
          .doc(intermedio.id)
          .update(intermedio.toFirestore());
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
  Future<List<Intermedio>> buscarPorNombre(String query) async {
    try {
      final regex = RegExp(query, caseSensitive: false);
      
      final snapshot = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .get();
          
      final docs = snapshot.docs.where((doc) {
        final nombre = doc.data()['nombre'] as String;
        return regex.hasMatch(nombre);
      });
      
      return docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
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
      codigo = 'INT-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
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
  Future<List<Intermedio>> filtrarPorTipo(String tipo) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContains: tipo)
          .where('activo', isEqualTo: true)
          .get();
      return querySnapshot.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
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


  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a los intermedios');
      case 'not-found':
        return Exception('Intermedio no encontrado');
      case 'invalid-argument':
        return Exception('Datos del intermedio no válidos');
      default:
        return Exception('Error al acceder a los intermedios: ${e.message}');
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
}