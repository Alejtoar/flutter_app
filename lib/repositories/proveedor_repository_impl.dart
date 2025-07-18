// proveedor_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:golo_app/repositories/proveedor_repository.dart';
import 'package:golo_app/config/app_config.dart';

class ProveedorFirestoreRepository implements ProveedorRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'proveedores';
  final bool _isMultiUser =
      AppConfig
          .instance
          .isMultiUser; //aca ya inicie la var pero aun no lo cambio todo

  ProveedorFirestoreRepository(this._db);

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
  Future<Proveedor> crear(Proveedor proveedor, {String? uid}) async {
    try {
      // Validar unicidad del código
      if (await existeCodigo(proveedor.codigo, uid: uid)) {
        throw Exception('El código ${proveedor.codigo} ya está registrado');
      }

      final docRef = await _getCollection(uid: uid).add(proveedor.toFirestore());
      return proveedor.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Proveedor> obtener(String id, {String? uid}) async {
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) throw Exception('Proveedor no encontrado');
      return Proveedor.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Proveedor>> obtenerTodos({String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          // .where('activo', isEqualTo: true)
          .get();
      return querySnapshot.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Proveedor>> obtenerPorTipoInsumo(String tipoInsumo, {String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('tiposInsumos', arrayContains: tipoInsumo)
          .where('activo', isEqualTo: true)
          .get();
      return querySnapshot.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Proveedor proveedor, {String? uid}) async {
    try {
      await _getCollection(uid: uid)
          .doc(proveedor.id)
          .update(proveedor.toFirestore());
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
  Future<void> eliminar(String id, {String? uid}) async {
    try {
      await _getCollection(uid: uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Proveedor>> buscarPorNombre(String query, {String? uid}) async {
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
      
      return docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
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
        codigo = 'P-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
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

  @override
  Future<List<Proveedor>> obtenerPorTiposInsumo(List<String> tipos, {String? uid}) async {
    try {
      if (tipos.isEmpty) return [];
      
      final querySnapshot = await _getCollection(uid: uid)
          .where('tiposInsumos', arrayContainsAny: tipos)
          .where('activo', isEqualTo: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => Proveedor.fromFirestore(doc))
          .where((proveedor) => tipos.any((t) => proveedor.tiposInsumos.contains(t)))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<DateTime?> obtenerFechaActualizacion(String id, {String? uid}) async {
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
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
        return Exception('No tienes permiso para acceder a los proveedores');
      case 'not-found':
        return Exception('Proveedor no encontrado');
      case 'invalid-argument':
        return Exception('Datos del proveedor no válidos');
      default:
        return Exception('Error al acceder a los proveedores: ${e.message}');
    }
  }
}