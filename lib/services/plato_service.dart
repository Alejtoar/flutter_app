import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plato.dart';
import '../models/intermedio_requerido.dart';

class PlatoService {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos';

  PlatoService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<Plato> crearPlato(Plato plato) async {
    try {
      final docRef = await _db.collection(_coleccion).add(plato.toFirestore());
      return plato.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Plato> obtenerPlato(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Plato no encontrado');
      return Plato.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Plato>> obtenerTodos({bool? activo}) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(_coleccion);
      
      if (activo != null) {
        query = query.where('activo', isEqualTo: activo);
      }

      query = query.orderBy('nombre');
      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Plato>> buscarPlatos(String query) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThan: '${query}z')
          .where('activo', isEqualTo: true)
          .get();

      final querySnapshotCodigo = await _db.collection(_coleccion)
          .where('codigo', isGreaterThanOrEqualTo: query)
          .where('codigo', isLessThan: '${query}z')
          .where('activo', isEqualTo: true)
          .get();

      final resultados = <Plato>{};
      for (var doc in querySnapshot.docs) {
        resultados.add(Plato.fromFirestore(doc));
      }
      for (var doc in querySnapshotCodigo.docs) {
        resultados.add(Plato.fromFirestore(doc));
      }

      return resultados.toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarPlato(Plato plato) async {
    try {
      if (plato.id == null) throw Exception('ID de plato no válido');
      await _db.collection(_coleccion).doc(plato.id).update(plato.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> desactivarPlato(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).update({
        'activo': false,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Plato>> obtenerPlatosPorCategoria(String categoria) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContains: categoria)
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();

      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarCostos(String id, double nuevoCosto, double nuevoPrecio) async {
    try {
      await _db.collection(_coleccion).doc(id).update({
        'costoBase': nuevoCosto,
        'precioVenta': nuevoPrecio,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<String> generarCodigo() async {
    try {
      final count = await _db.collection(_coleccion).count().get();
      return 'P-${(count.count! + 1).toString().padLeft(3, '0')}';
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> eliminarPlato(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Plato no encontrado');
      case 'already-exists':
        return Exception('Ya existe un plato con este código');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}
