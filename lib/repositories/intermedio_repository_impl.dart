import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import '../models/intermedio.dart';
import 'package:golo_app/exceptions/intermedio_en_uso_exception.dart';
import 'package:golo_app/config/app_config.dart';

class IntermedioFirestoreRepository implements IntermedioRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios';
  static const String _coleccionIntermediosEventos = 'intermedios_eventos';
  static const String _coleccionIntermediosPlatos = 'intermedios_requeridos';
  
  final bool _isMultiUser =
      AppConfig.instance.isMultiUser;

  IntermedioFirestoreRepository(this._db);

  CollectionReference _getCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) throw Exception("UID es requerido en modo multi-usuario.");
      return _db.collection('usuarios').doc(uid).collection(_coleccion);
    } else {
      return _db.collection(_coleccion);
    }
  }
  CollectionReference _getIntermediosEventosCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) throw Exception("UID es requerido en modo multi-usuario.");
      return _db.collection('usuarios').doc(uid).collection(_coleccionIntermediosEventos);
    } else {
      return _db.collection(_coleccionIntermediosEventos);
    }
  }

  CollectionReference _getIntermediosPlatosCollection({String? uid}) {
    if (_isMultiUser) {
      if (uid == null || uid.isEmpty) throw Exception("UID es requerido en modo multi-usuario.");
      return _db.collection('usuarios').doc(uid).collection(_coleccionIntermediosPlatos);
    } else {
      return _db.collection(_coleccionIntermediosPlatos);
    }
  }

  @override
  Future<Intermedio> crear(Intermedio intermedio, {String? uid}) async {
    try {
      // Validar unicidad del código
      if (await existeCodigo(intermedio.codigo, uid: uid)) {
        throw Exception('El código ${intermedio.codigo} ya está registrado');
      }
      
      final docRef = await _getCollection(uid: uid).add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Intermedio> obtener(String id, {String? uid}) async {
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) throw Exception('Intermedio no encontrado');
      return Intermedio.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Intermedio>> obtenerTodos({String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .get();
      return querySnapshot.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Intermedio>> obtenerPorIds(List<String> ids, {String? uid}) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _getCollection(uid: uid)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Intermedio intermedio, {String? uid}) async {
    try {
      await _getCollection(uid: uid)
          .doc(intermedio.id)
          .update(intermedio.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivar(String id, {String? uid}) async {
    try {
      await _getCollection(uid: uid)
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
  Future<List<Intermedio>> buscarPorNombre(String query, {String? uid}) async {
    try {
      final regex = RegExp(query, caseSensitive: false);
      
      final snapshot = await _getCollection(uid: uid)
          .where('activo', isEqualTo: true)
          .get();
          
      final docs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null || data['nombre'] == null) {
          return false;
        }

        final nombre = data['nombre'] as String;
        return regex.hasMatch(nombre);
      });
      
      return docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
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
      final count = await _getCollection(uid: uid).count().get();
      codigo = 'INT-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
      codigoExiste = await existeCodigo(codigo, uid: uid);
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
  Future<List<Intermedio>> filtrarPorTipo(String tipo, {String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('categorias', arrayContains: tipo)
          .where('activo', isEqualTo: true)
          .get();
      return querySnapshot.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }


  @override
  Future<void> eliminar(String id, {String? uid}) async {
    // 1. Verificar relaciones en intermedio_requerido, intermedio_evento
    final usos = <String>[];
    // Intermedio requerido (en platos)
    final intermedioRequeridoSnap = await _getIntermediosPlatosCollection(uid: uid).where('intermedioId', isEqualTo: id).limit(1).get();
    if (intermedioRequeridoSnap.docs.isNotEmpty) usos.add('Platos');
    // Intermedio evento (en eventos)
    final intermedioEventoSnap = await _getIntermediosEventosCollection(uid: uid).where('intermedioId', isEqualTo: id).limit(1).get();
    if (intermedioEventoSnap.docs.isNotEmpty) usos.add('Eventos');
    if (usos.isNotEmpty) {
      // Lanzar excepción personalizada
      throw IntermedioEnUsoException(usos);
    }
    // Si no está en uso, borrar normalmente
    try {
      await _getCollection(uid: uid).doc(id).delete();
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
  Future<bool> existeCodigo(String codigo, {String? uid}) async {
    try {
      final query = await _getCollection(uid: uid)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }
}