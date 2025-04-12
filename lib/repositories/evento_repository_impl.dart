import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/repositories/evento_repository.dart';

class EventoFirestoreRepository implements EventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'eventos';

  EventoFirestoreRepository(this._db);

  @override
  Future<Evento> crear(Evento evento) async {
    try {
      // Generar código si no existe
      if (evento.codigo.isEmpty) {
        evento = evento.copyWith(codigo: await generarNuevoCodigo());
      }
      
      // Verificar código único
      if (await existeCodigo(evento.codigo)) {
        throw Exception('El código ${evento.codigo} ya existe');
      }
      
      final docRef = await _db.collection(_coleccion).add(evento.toFirestore());
      return evento.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Evento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Evento no encontrado');
      return Evento.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Evento evento) async {
    try {
      await _db.collection(_coleccion)
          .doc(evento.id)
          .update(evento.toFirestore());
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
  Future<List<Evento>> buscarPorNombre(String query) async {
    try {
      // Crear una expresión regular con la opción 'i' para insensibilidad a mayúsculas
      final regex = RegExp(query, caseSensitive: false);
      
      final snapshot = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .get();
          
      // Filtrar los resultados usando la expresión regular
      final docs = snapshot.docs.where((doc) {
        final nombre = doc.data()['nombre'] as String;
        return regex.hasMatch(nombre);
      });
      
      return docs.map((doc) => Evento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Evento> obtenerPorCodigo(String codigo) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
          
      if (query.docs.isEmpty) throw Exception('Evento no encontrado');
      return Evento.fromFirestore(query.docs.first);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<String> generarNuevoCodigo() async {
    try {
      final ultimoEvento = await _db.collection(_coleccion)
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();
          
      String ultimoCodigo = 'EV-000';
      if (ultimoEvento.docs.isNotEmpty) {
        ultimoCodigo = ultimoEvento.docs.first.data()['codigo'] ?? 'EV-000';
      }
      
      final numero = int.parse(ultimoCodigo.split('-').last) + 1;
      return 'EV-${numero.toString().padLeft(3, '0')}';
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
  Future<bool> existeEventoConNombre(String nombre) async {
    final query = await _db.collection(_coleccion)
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Future<List<Evento>> obtenerPorEstado(EstadoEvento estado) async {
    final query = await _db.collection(_coleccion)
        .where('estado', isEqualTo: estado.index)
        .get();
    return query.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Evento>> obtenerPorRangoFechas(DateTime desde, DateTime hasta) async {
    final query = await _db.collection(_coleccion)
        .where('fecha', isGreaterThanOrEqualTo: desde)
        .where('fecha', isLessThanOrEqualTo: hasta)
        .get();
    return query.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Evento>> obtenerPorTipo(TipoEvento tipo) async {
    final query = await _db.collection(_coleccion)
        .where('tipo', isEqualTo: tipo.index)
        .get();
    return query.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Evento>> obtenerTodos() async {
    final query = _db.collection(_coleccion)
        .where('activo', isEqualTo: true);
        
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a eventos');
      case 'not-found':
        return Exception('Evento no encontrado');
      default:
        return Exception('Error en Firestore: ${e.message}');
    }
  }
}
