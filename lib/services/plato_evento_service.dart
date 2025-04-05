import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/plato_evento.dart';

class PlatoEventoService {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos_evento';

  PlatoEventoService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<PlatoEvento> crearPlatoEvento(PlatoEvento platoEvento, String eventoId) async {
    try {
      final docRef = await _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .add(platoEvento.toMap());
      
      // Retornar el plato evento con su ID asignado
      return PlatoEvento.fromMap({
        ...platoEvento.toMap(),
        'id': docRef.id,
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<PlatoEvento>> obtenerPlatosEvento(String eventoId) async {
    try {
      final querySnapshot = await _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .get();

      return querySnapshot.docs
          .map((doc) => PlatoEvento.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarPlatoEvento(
    String eventoId,
    String platoEventoId,
    PlatoEvento platoEvento,
  ) async {
    try {
      await _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .doc(platoEventoId)
          .update(platoEvento.toMap());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> eliminarPlatoEvento(String eventoId, String platoEventoId) async {
    try {
      await _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .doc(platoEventoId)
          .delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<PlatoEvento>> buscarPlatosEvento(String eventoId, String query) async {
    try {
      Query<Map<String, dynamic>> nombreQuery = _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThan: query + 'z');

      Query<Map<String, dynamic>> codigoQuery = _db.collection('eventos')
          .doc(eventoId)
          .collection(_coleccion)
          .where('codigo', isGreaterThanOrEqualTo: query)
          .where('codigo', isLessThan: query + 'z');

      final querySnapshotNombre = await nombreQuery.get();
      final querySnapshotCodigo = await codigoQuery.get();

      final resultados = <PlatoEvento>{};
      for (var doc in querySnapshotNombre.docs) {
        resultados.add(PlatoEvento.fromMap(doc.data()));
      }
      for (var doc in querySnapshotCodigo.docs) {
        resultados.add(PlatoEvento.fromMap(doc.data()));
      }

      return resultados.toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Plato del evento no encontrado');
      case 'already-exists':
        return Exception('Este plato ya existe en el evento');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}
