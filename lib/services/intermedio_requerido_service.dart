import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intermedio_requerido.dart';
import '../services/intermedio_service.dart';

class IntermedioRequeridoService {
  final FirebaseFirestore _db;
  final IntermedioService _intermedioService;
  final String _coleccion = 'intermedios_requeridos';

  IntermedioRequeridoService({
    FirebaseFirestore? db,
    IntermedioService? intermedioService,
  }) : _db = db ?? FirebaseFirestore.instance,
       _intermedioService = intermedioService ?? IntermedioService();

  Future<IntermedioRequerido> crearIntermedioRequerido(IntermedioRequerido intermedio) async {
    try {
      // Validar que el intermedio base existe
      await _intermedioService.obtenerIntermedio(intermedio.intermedioId);
      
      final docRef = await _db.collection(_coleccion).add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<IntermedioRequerido> obtenerIntermedioRequerido(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Intermedio requerido no encontrado');
      return IntermedioRequerido.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .orderBy('orden')
          .get();

      return querySnapshot.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarIntermedioRequerido(IntermedioRequerido intermedio) async {
    try {
      if (intermedio.id == null) throw Exception('ID de intermedio requerido no válido');
      await _db.collection(_coleccion).doc(intermedio.id).update(intermedio.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> eliminarIntermedioRequerido(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarOrden(String id, int nuevoOrden) async {
    try {
      await _db.collection(_coleccion).doc(id).update({
        'orden': nuevoOrden,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarCantidad(String id, double nuevaCantidad) async {
    try {
      if (nuevaCantidad <= 0) {
        throw ArgumentError('La cantidad debe ser mayor que cero');
      }
      
      await _db.collection(_coleccion).doc(id).update({
        'cantidad': nuevaCantidad,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Intermedio requerido no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}
