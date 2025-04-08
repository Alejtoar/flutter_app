import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intermedio_requerido.dart';

class IntermedioRequeridoService {
  static const String collectionName = 'intermedios_requeridos';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear nuevo intermedio requerido
  Future<String> crear(IntermedioRequerido intermedio) async {
    final doc = await _firestore.collection(collectionName).add(intermedio.toFirestore());
    return doc.id;
  }

  // Actualizar intermedio requerido
  Future<void> actualizar(String id, IntermedioRequerido intermedio) async {
    await _firestore.collection(collectionName).doc(id).update(intermedio.toFirestore());
  }

  // Obtener intermedio requerido por ID
  Future<IntermedioRequerido?> obtener(String id) async {
    final doc = await _firestore.collection(collectionName).doc(id).get();
    if (!doc.exists) return null;
    return IntermedioRequerido.fromFirestore(doc);
  }

  // Obtener todos los intermedios requeridos
  Stream<List<IntermedioRequerido>> obtenerTodos() {
    return _firestore
        .collection(collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IntermedioRequerido.fromFirestore(doc))
            .toList());
  }

  // Eliminar intermedio requerido
  Future<void> eliminar(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  // Obtener intermedios requeridos por plato
  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('platoId', isEqualTo: platoId)
        .get();
    return snapshot.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
  }
}
