import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/evento.dart';

class EventoService {
  final FirebaseFirestore _db;
  final String _coleccion = 'eventos';

  EventoService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Evento _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Evento(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombreCliente: data['nombreCliente'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      ubicacion: data['ubicacion'] ?? '',
      numeroInvitados: data['numeroInvitados'] ?? 0,
      platos: (data['platos'] as List<dynamic>? ?? [])
          .map((p) => PlatoEvento.fromMap(p as Map<String, dynamic>))
          .toList(),
      tipoEvento: TipoEvento.values.firstWhere(
        (e) => e.toString() == data['tipoEvento'],
        orElse: () => TipoEvento.inmediato,
      ),
      estado: EstadoEvento.values.firstWhere(
        (e) => e.toString() == data['estado'],
        orElse: () => EstadoEvento.cotizado,
      ),
      presupuestoTotal: (data['presupuestoTotal'] ?? 0).toDouble(),
      costoTotal: (data['costoTotal'] ?? 0).toDouble(),
      requisitosEspeciales: Map<String, dynamic>.from(data['requisitosEspeciales'] ?? {}),
      fechaCotizacion: (data['fechaCotizacion'] as Timestamp).toDate(),
      fechaConfirmacion: (data['fechaConfirmacion'] as Timestamp?)?.toDate(),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
      requiereInventario: data['requiereInventario'] ?? false,
      comentariosLogistica: data['comentariosLogistica'],
    );
  }

  Future<Evento> crearEvento(Evento evento) async {
    try {
      final docRef = await _db.collection(_coleccion).add(evento.toFirestore());
      return evento.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Evento> obtenerEvento(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Evento no encontrado');
      return Evento.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Evento>> obtenerEventos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoEvento? tipo,
    EstadoEvento? estado,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(_coleccion);

      if (fechaInicio != null) {
        query = query.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      }
      if (tipo != null) {
        query = query.where('tipoEvento', isEqualTo: tipo.toString());
      }
      if (estado != null) {
        query = query.where('estado', isEqualTo: estado.toString());
      }

      query = query.orderBy('fecha', descending: true);
      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarEvento(Evento evento) async {
    try {
      if (evento.id == null) throw Exception('ID de evento no válido');
      await _db.collection(_coleccion).doc(evento.id).update(evento.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarEstadoEvento(String id, EstadoEvento nuevoEstado) async {
    try {
      await _db.collection(_coleccion).doc(id).update({
        'estado': nuevoEstado.toString(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> confirmarEvento(String id, DateTime fechaConfirmacion) async {
    try {
      await _db.collection(_coleccion).doc(id).update({
        'estado': EstadoEvento.confirmado.toString(),
        'fechaConfirmacion': Timestamp.fromDate(fechaConfirmacion),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Evento>> buscarEventos(String query) async {
    try {
      // Búsqueda por código o nombre del cliente
      final querySnapshot = await _db.collection(_coleccion)
          .where('codigo', isGreaterThanOrEqualTo: query)
          .where('codigo', isLessThan: '${query}z')
          .get();

      final querySnapshotNombre = await _db.collection(_coleccion)
          .where('nombreCliente', isGreaterThanOrEqualTo: query)
          .where('nombreCliente', isLessThan: '${query}z')
          .get();

      final resultados = <Evento>{};
      for (var doc in querySnapshot.docs) {
        resultados.add(Evento.fromFirestore(doc));
      }
      for (var doc in querySnapshotNombre.docs) {
        resultados.add(Evento.fromFirestore(doc));
      }

      return resultados.toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Evento>> obtenerEventosUrgentes() async {
    try {
      final ahora = DateTime.now();
      final limite = ahora.add(const Duration(days: 7));
      
      final querySnapshot = await _db.collection(_coleccion)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(ahora))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(limite))
          .where('estado', whereIn: [
            EstadoEvento.confirmado.toString(),
            EstadoEvento.enPreparacion.toString(),
          ])
          .orderBy('fecha')
          .get();

      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Evento no encontrado');
      case 'already-exists':
        return Exception('Ya existe un evento con este código');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}
