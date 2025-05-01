MODELOS


// evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final bool facturable;
  final String? id;
  final String codigo;
  final String nombreCliente;
  final String telefono;
  final String correo;
  final DateTime fecha;
  final String ubicacion;
  final int numeroInvitados;
  final TipoEvento tipoEvento;
  final EstadoEvento estado;
  final DateTime? fechaCotizacion;
  final DateTime? fechaConfirmacion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String? comentariosLogistica;

  const Evento({
    this.id,
    required this.codigo,
    required this.nombreCliente,
    required this.telefono,
    required this.correo,
    required this.fecha,
    required this.ubicacion,
    required this.numeroInvitados,
    required this.tipoEvento,
    required this.estado,
    required this.fechaCotizacion,
    this.fechaConfirmacion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.comentariosLogistica,
    this.facturable = true,
  });

  factory Evento.crear({
    String? id,
    required String codigo,
    required String nombreCliente,
    required String telefono,
    required String correo,
    required DateTime fecha,
    required String ubicacion,
    required int numeroInvitados,
    required TipoEvento tipoEvento,
    required EstadoEvento estado,
    required DateTime fechaCotizacion,
    DateTime? fechaConfirmacion,
    required DateTime fechaCreacion,
    required DateTime fechaActualizacion,
    String? comentariosLogistica,
    bool? facturable,
  }) {
    // Validaciones
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (nombreCliente.isEmpty) errors.add('El nombre del cliente es requerido');
    if (telefono.isEmpty) errors.add('El teléfono es requerido');
    if (correo.isEmpty) errors.add('El correo es requerido');
    if (ubicacion.isEmpty) errors.add('La ubicación es requerida');
    if (numeroInvitados <= 0) errors.add('El número de invitados debe ser positivo');

    // Validación de teléfono y correo
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(telefono)) {
      errors.add('Teléfono no válido. Use formato internacional');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(correo)) {
      errors.add('Correo electrónico no válido');
    }

    // final ahora = DateTime.now();
    // if (fecha.isBefore(ahora)) {
    //   errors.add('La fecha del evento debe ser futura');
    // }

    // Validaciones específicas por tipo de evento
    // final diasHastaEvento = fecha.difference(ahora).inDays;

    // if (tipoEvento == TipoEvento.matrimonio && diasHastaEvento < 30) {
    //   errors.add('Los eventos de matrimonio requieren al menos 30 días de anticipación');
    // }

    // if (tipoEvento == TipoEvento.produccionAudiovisual && diasHastaEvento > 14) {
    //   errors.add('Los eventos de producción audiovisual deben estar dentro de los próximos 14 días');
    // }

    // if (tipoEvento == TipoEvento.chefEnCasa && diasHastaEvento < 7) {
    //   errors.add('Los eventos de chef en casa requieren al menos 7 días de anticipación');
    // }

    // if (tipoEvento == TipoEvento.institucional && diasHastaEvento < 14) {
    //   errors.add('Los eventos institucionales requieren al menos 14 días de anticipación');
    // }

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    return Evento(
      id: id,
      codigo: codigo,
      nombreCliente: nombreCliente,
      telefono: telefono,
      correo: correo,
      fecha: fecha,
      ubicacion: ubicacion,
      numeroInvitados: numeroInvitados,
      tipoEvento: tipoEvento,
      estado: estado,
      fechaCotizacion: fechaCotizacion,
      fechaConfirmacion: fechaConfirmacion,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      comentariosLogistica: comentariosLogistica,
      facturable: facturable ?? true,
    );
  }

  factory Evento.fromMap(Map<String, dynamic> map, String id) {
    return Evento.crear(
      id: id,
      codigo: map['codigo'] ?? '',
      nombreCliente: map['nombreCliente'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      ubicacion: map['ubicacion'] ?? '',
      numeroInvitados: map['numeroInvitados'] ?? 0,
      tipoEvento: TipoEvento.values.firstWhere(
        (e) => e.toString() == map['tipoEvento'],
        orElse: () => TipoEvento.institucional,
      ),
      estado: EstadoEvento.values.firstWhere(
        (e) => e.toString() == map['estado'],
        orElse: () => EstadoEvento.cotizado,
      ),
      fechaCotizacion: (map['fechaCotizacion'] as Timestamp).toDate(),
      fechaConfirmacion: map['fechaConfirmacion'] != null
          ? (map['fechaConfirmacion'] as Timestamp).toDate()
          : null,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
      comentariosLogistica: map['comentariosLogistica'],
      facturable: map['facturable'] ?? true,
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    print('Evento.fromFirestore: Procesando documento con id: ${doc.id}');
    final data = doc.data() as Map<String, dynamic>;
    return Evento(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombreCliente: data['nombreCliente'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      ubicacion: data['ubicacion'] ?? '',
      numeroInvitados: (data['numeroInvitados'] as num?)?.toInt() ?? 0,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCotizacion: data['fechaCotizacion'] != null 
          ? (data['fechaCotizacion'] as Timestamp).toDate()
          : null,
      fechaConfirmacion: data['fechaConfirmacion'] != null 
          ? (data['fechaConfirmacion'] as Timestamp).toDate()
          : null,
      tipoEvento: TipoEvento.values.firstWhere(
        (e) => e.toString() == 'TipoEvento.${data['tipoEvento']}',
        orElse: () => TipoEvento.institucional,
      ),
      estado: EstadoEvento.values.firstWhere(
        (e) => e.toString() == 'EstadoEvento.${data['estado']}',
        orElse: () => EstadoEvento.cotizado,
      ),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
      comentariosLogistica: data['comentariosLogistica'],
      facturable: data['facturable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombreCliente': nombreCliente,
      'telefono': telefono,
      'correo': correo,
      'fecha': Timestamp.fromDate(fecha),
      'ubicacion': ubicacion,
      'numeroInvitados': numeroInvitados,
      'tipoEvento': tipoEvento.toString(),
      'estado': estado.toString(),
      if (fechaCotizacion != null) 'fechaCotizacion': Timestamp.fromDate(fechaCotizacion!),
      if (fechaConfirmacion != null) 'fechaConfirmacion': Timestamp.fromDate(fechaConfirmacion!),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      if (comentariosLogistica != null) 'comentariosLogistica': comentariosLogistica,
      'facturable': facturable,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombreCliente': nombreCliente,
      'telefono': telefono,
      'correo': correo,
      'fecha': Timestamp.fromDate(fecha),
      'ubicacion': ubicacion,
      'numeroInvitados': numeroInvitados,
      'tipoEvento': tipoEvento.toString(),
      'estado': estado.toString(),
      if (fechaCotizacion != null) 'fechaCotizacion': Timestamp.fromDate(fechaCotizacion!),
      if (fechaConfirmacion != null) 'fechaConfirmacion': Timestamp.fromDate(fechaConfirmacion!),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      if (comentariosLogistica != null) 'comentariosLogistica': comentariosLogistica,
      'facturable': facturable,
    };
  }

  Evento copyWith({
    String? id,
    bool? facturable,
    String? codigo,
    String? nombreCliente,
    String? telefono,
    String? correo,
    DateTime? fecha,
    String? ubicacion,
    int? numeroInvitados,
    TipoEvento? tipoEvento,
    EstadoEvento? estado,
    DateTime? fechaCotizacion,
    DateTime? fechaConfirmacion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? comentariosLogistica,
  }) {
    return Evento(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      fecha: fecha ?? this.fecha,
      ubicacion: ubicacion ?? this.ubicacion,
      numeroInvitados: numeroInvitados ?? this.numeroInvitados,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      estado: estado ?? this.estado,
      fechaCotizacion: fechaCotizacion ?? this.fechaCotizacion,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      comentariosLogistica: comentariosLogistica ?? this.comentariosLogistica,
      facturable: facturable ?? this.facturable,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Evento &&
        other.id == id &&
        other.codigo == codigo;
  }

  @override
  int get hashCode => Object.hash(id, codigo);

  @override
  String toString() {
    return 'Evento(id: $id, codigo: $codigo, cliente: $nombreCliente, fecha: $fecha)';
  }
}

enum TipoEvento {
  matrimonio,
  produccionAudiovisual,
  chefEnCasa,
  institucional
}

enum EstadoEvento {
  cotizado,
  confirmado,
  esCotizacion,
  enPruebaMenu,
  completado,
  cancelado
}

// insumo_evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InsumoEvento {
  final String? id;
  final String eventoId;
  final String insumoId;
  final double cantidad;
  final String unidad;

  const InsumoEvento({
    this.id,
    required this.eventoId,
    required this.insumoId,
    required this.cantidad,
    required this.unidad,
  });

  factory InsumoEvento.fromMap(Map<String, dynamic> map) {
    return InsumoEvento(
      id: map['id'] as String?,
      eventoId: map['eventoId'] as String,
      insumoId: map['insumoId'] as String,
      cantidad: map['cantidad'] as double,
      unidad: map['unidad'] as String,
    );
  }

  factory InsumoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoEvento(
      id: doc.id,
      eventoId: data['eventoId'] as String,
      insumoId: data['insumoId'] as String,
      cantidad: data['cantidad'] as double,
      unidad: data['unidad'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'eventoId': eventoId,
      'insumoId': insumoId,
      'cantidad': cantidad,
      'unidad': unidad,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'insumoId': insumoId,
      'cantidad': cantidad,
      'unidad': unidad,
    };
  }

  InsumoEvento copyWith({
    String? id,
    String? eventoId,
    String? insumoId,
    double? cantidad,
    String? unidad,
  }) {
    return InsumoEvento(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      insumoId: insumoId ?? this.insumoId,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
    );
  }
  
}

// intermedio_evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IntermedioEvento {
  final String? id;
  final String eventoId;
  final String intermedioId;
  final int cantidad;

  const IntermedioEvento({
    this.id,
    required this.eventoId,
    required this.intermedioId,
    required this.cantidad,
  });

  factory IntermedioEvento.fromMap(Map<String, dynamic> map) {
    return IntermedioEvento(
      id: map['id'] as String?,
      eventoId: map['eventoId'] as String,
      intermedioId: map['intermedioId'] as String,
      cantidad: map['cantidad'] as int,
    );
  }

  factory IntermedioEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntermedioEvento(
      id: doc.id,
      eventoId: data['eventoId'] as String,
      intermedioId: data['intermedioId'] as String,
      cantidad: data['cantidad'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'eventoId': eventoId,
      'intermedioId': intermedioId,
      'cantidad': cantidad,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'intermedioId': intermedioId,
      'cantidad': cantidad,
    };
  }

  IntermedioEvento copyWith({
  String? id,
  String? eventoId,
  String? intermedioId,
  int? cantidad,
}) {
  return IntermedioEvento(
    id: id ?? this.id,
    eventoId: eventoId ?? this.eventoId,
    intermedioId: intermedioId ?? this.intermedioId,
    cantidad: cantidad ?? this.cantidad,
  );
}
}

// plato_evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlatoEvento {
  // Personalización temporal para el evento
  final String? nombrePersonalizado;
  final List<dynamic>? insumosExtra;
  final List<String>? insumosRemovidos;
  final List<dynamic>? intermediosExtra;
  final List<String>? intermediosRemovidos;
  final String? id;
  final String eventoId;
  final String platoId;
  final int cantidad;

  const PlatoEvento({
    this.id,
    required this.eventoId,
    required this.platoId,
    required this.cantidad,
    this.nombrePersonalizado,
    this.insumosExtra,
    this.insumosRemovidos,
    this.intermediosExtra,
    this.intermediosRemovidos,
  });

  factory PlatoEvento.fromMap(Map<String, dynamic> map) {
    return PlatoEvento(
      id: map['id'] as String?,
      eventoId: map['eventoId'] as String,
      platoId: map['platoId'] as String,
      cantidad: map['cantidad'] as int,
      nombrePersonalizado: map['nombrePersonalizado'] as String?,
      insumosExtra: map['insumosExtra'] as List<dynamic>?,
      insumosRemovidos: (map['insumosRemovidos'] as List<dynamic>?)?.cast<String>(),
      intermediosExtra: map['intermediosExtra'] as List<dynamic>?,
      intermediosRemovidos: (map['intermediosRemovidos'] as List<dynamic>?)?.cast<String>(),
    );
  }

  factory PlatoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatoEvento(
      id: doc.id,
      eventoId: data['eventoId'] as String,
      platoId: data['platoId'] as String,
      cantidad: data['cantidad'] as int,
      nombrePersonalizado: data['nombrePersonalizado'] as String?,
      insumosExtra: data['insumosExtra'] as List<dynamic>?,
      insumosRemovidos: (data['insumosRemovidos'] as List<dynamic>?)?.cast<String>(),
      intermediosExtra: data['intermediosExtra'] as List<dynamic>?,
      intermediosRemovidos: (data['intermediosRemovidos'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
      if (nombrePersonalizado != null) 'nombrePersonalizado': nombrePersonalizado,
      if (insumosExtra != null) 'insumosExtra': insumosExtra,
      if (insumosRemovidos != null) 'insumosRemovidos': insumosRemovidos,
      if (intermediosExtra != null) 'intermediosExtra': intermediosExtra,
      if (intermediosRemovidos != null) 'intermediosRemovidos': intermediosRemovidos,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
      if (nombrePersonalizado != null) 'nombrePersonalizado': nombrePersonalizado,
      if (insumosExtra != null) 'insumosExtra': insumosExtra,
      if (insumosRemovidos != null) 'insumosRemovidos': insumosRemovidos,
      if (intermediosExtra != null) 'intermediosExtra': intermediosExtra,
      if (intermediosRemovidos != null) 'intermediosRemovidos': intermediosRemovidos,
    };
  }

  PlatoEvento copyWith({
    String? id,
    String? eventoId,
    String? platoId,
    int? cantidad,
    String? nombrePersonalizado,
    List<dynamic>? insumosExtra,
    List<String>? insumosRemovidos,
    List<dynamic>? intermediosExtra,
    List<String>? intermediosRemovidos,
  }) {
    return PlatoEvento(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      platoId: platoId ?? this.platoId,
      cantidad: cantidad ?? this.cantidad,
      nombrePersonalizado: nombrePersonalizado ?? this.nombrePersonalizado,
      insumosExtra: insumosExtra ?? this.insumosExtra,
      insumosRemovidos: insumosRemovidos ?? this.insumosRemovidos,
      intermediosExtra: intermediosExtra ?? this.intermediosExtra,
      intermediosRemovidos: intermediosRemovidos ?? this.intermediosRemovidos,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlatoEvento &&
        other.id == id &&
        other.eventoId == eventoId &&
        other.platoId == platoId &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, eventoId, platoId, cantidad);

  @override
  String toString() {
    return 'PlatoEvento(id: $id, eventoId: $eventoId, platoId: $platoId, cantidad: $cantidad, nombrePersonalizado: $nombrePersonalizado, insumosExtra: $insumosExtra, insumosRemovidos: $insumosRemovidos, intermediosExtra: $intermediosExtra, intermediosRemovidos: $intermediosRemovidos)';
  }
}


REPOSITORIOS

//evento_repository_impl.dart
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
      final docRef = _db.collection(_coleccion).doc(evento.id);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Evento no encontrado');
      
      final eventoActual = Evento.fromFirestore(doc);
      final cambios = <String, dynamic>{};
      
      // Solo actualizar los campos que han cambiado
      if (eventoActual.nombreCliente != evento.nombreCliente) {
        cambios['nombreCliente'] = evento.nombreCliente;
      }
      if (eventoActual.telefono != evento.telefono) {
        cambios['telefono'] = evento.telefono;
      }
      if (eventoActual.correo != evento.correo) {
        cambios['correo'] = evento.correo;
      }
      if (eventoActual.fecha != evento.fecha) {
        cambios['fecha'] = Timestamp.fromDate(evento.fecha);
      }
      if (eventoActual.ubicacion != evento.ubicacion) {
        cambios['ubicacion'] = evento.ubicacion;
      }
      if (eventoActual.numeroInvitados != evento.numeroInvitados) {
        cambios['numeroInvitados'] = evento.numeroInvitados;
      }
      if (eventoActual.tipoEvento != evento.tipoEvento) {
        cambios['tipoEvento'] = evento.tipoEvento.toString();
      }
      if (eventoActual.estado != evento.estado) {
        cambios['estado'] = evento.estado.toString();
      }
      if (eventoActual.comentariosLogistica != evento.comentariosLogistica) {
        cambios['comentariosLogistica'] = evento.comentariosLogistica;
      }
      if (eventoActual.facturable != evento.facturable) {
        cambios['facturable'] = evento.facturable;
      }
      
      if (cambios.isNotEmpty) {
        await docRef.update(cambios);
      }
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
    final query = _db.collection(_coleccion);
        
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

//insumo_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';
import '../models/insumo_evento.dart';

class InsumoEventoFirestoreRepository implements InsumoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_eventos';

  InsumoEventoFirestoreRepository(this._db);

  @override
  Future<InsumoEvento> crear(InsumoEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add({
        'eventoId': relacion.eventoId,
        'insumoId': relacion.insumoId,
        'cantidad': relacion.cantidad,
      });
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<InsumoEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return InsumoEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(InsumoEvento relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update({'cantidad': relacion.cantidad});
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
  Future<List<InsumoEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => InsumoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<InsumoEvento>> obtenerPorInsumo(String insumoId) async {
    final query = await _db.collection(_coleccion)
        .where('insumoId', isEqualTo: insumoId)
        .get();
    return query.docs
        .map((doc) => InsumoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> crearMultiples(String eventoId, List<InsumoEvento> relaciones) async {
    final batch = _db.batch();
    for (final relacion in relaciones) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, {
        'eventoId': eventoId,
        'insumoId': relacion.insumoId,
        'cantidad': relacion.cantidad,
      });
    }
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String insumoId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('insumoId', isEqualTo: insumoId)
        .where('eventoId', isEqualTo: eventoId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Future<void> eliminarPorEvento(String eventoId) async {
    final batch = _db.batch();
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    await batch.commit();
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a Firestore');
      case 'not-found':
        return Exception('Documento no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}

//intermedio_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';
import '../models/intermedio_evento.dart';

class IntermedioEventoFirestoreRepository implements IntermedioEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios_eventos';

  IntermedioEventoFirestoreRepository(this._db);

  @override
  Future<IntermedioEvento> crear(IntermedioEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add({
        'eventoId': relacion.eventoId,
        'intermedioId': relacion.intermedioId,
        'cantidad': relacion.cantidad,
      });
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<IntermedioEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return IntermedioEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(IntermedioEvento relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update({
            'cantidad': relacion.cantidad,
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
  Future<List<IntermedioEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => IntermedioEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<IntermedioEvento>> obtenerPorIntermedio(String intermedioId) async {
    final query = await _db.collection(_coleccion)
        .where('intermedioId', isEqualTo: intermedioId)
        .get();
    return query.docs
        .map((doc) => IntermedioEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> crearMultiples(String eventoId, List<IntermedioEvento> relaciones) async {
    final batch = _db.batch();
    
    // Crear nuevas relaciones
    for (final relacion in relaciones) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, relacion.toFirestore());
    }
    
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String intermedioId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('intermedioId', isEqualTo: intermedioId)
        .where('eventoId', isEqualTo: eventoId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Future<void> eliminarPorEvento(String eventoId) async {
    final batch = _db.batch();
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    await batch.commit();
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a Firestore');
      case 'not-found':
        return Exception('Documento no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}

//plato_evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/repositories/plato_evento_repository.dart';
import '../models/plato_evento.dart';

class PlatoEventoFirestoreRepository implements PlatoEventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos_eventos';

  PlatoEventoFirestoreRepository(this._db);

  @override
  Future<PlatoEvento> crear(PlatoEvento relacion) async {
    try {
      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<PlatoEvento> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return PlatoEvento.fromMap(doc.data()!..['id'] = doc.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(PlatoEvento relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update(relacion.toFirestore());
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
  Future<List<PlatoEvento>> obtenerPorEvento(String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('eventoId', isEqualTo: eventoId)
        .get();
    return query.docs
        .map((doc) => PlatoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<List<PlatoEvento>> obtenerPorPlato(String platoId) async {
    final query = await _db.collection(_coleccion)
        .where('platoId', isEqualTo: platoId)
        .get();
    return query.docs
        .map((doc) => PlatoEvento.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  @override
  Future<void> crearMultiples(String eventoId, List<PlatoEvento> relaciones) async {
    final batch = _db.batch();
    
    // Crear nuevas relaciones
    for (final relacion in relaciones) {
      final docRef = _db.collection(_coleccion).doc();
      batch.set(docRef, relacion.toFirestore());
    }
    
    await batch.commit();
  }

  @override
  Future<bool> existeRelacion(String platoId, String eventoId) async {
    final query = await _db.collection(_coleccion)
        .where('platoId', isEqualTo: platoId)
        .where('eventoId', isEqualTo: eventoId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Future<void> eliminarPorEvento(String eventoId) async {
    final batch = _db.batch();
    final relaciones = await obtenerPorEvento(eventoId);
    for (final relacion in relaciones) {
      batch.delete(_db.collection(_coleccion).doc(relacion.id));
    }
    await batch.commit();
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a Firestore');
      case 'not-found':
        return Exception('Documento no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}

UI Y CONTROLADOR QUE MANEJAN EL EVENTO, PERO SOLO SON PROTOTIPOS

//buscador_eventos_controller.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';
import '../../../../models/evento.dart';
import '../../../../models/insumo_evento.dart';
import '../../../../models/intermedio_evento.dart';
import '../../../../repositories/evento_repository_impl.dart';
import '../../../../repositories/plato_evento_repository_impl.dart';
import '../../../../repositories/insumo_evento_repository_impl.dart';
import '../../../../repositories/intermedio_evento_repository_impl.dart';
import '../../../../repositories/plato_repository.dart';
import '../../../../repositories/intermedio_repository.dart';
import '../../../../repositories/insumo_repository.dart';

class BuscadorEventosController extends ChangeNotifier {
  // Objetos relacionados cargados para la UI
  List<Plato> _platosRelacionados = [];
  List<Plato> get platosRelacionados => _platosRelacionados;
  List<Intermedio> _intermediosRelacionados = [];
  List<Intermedio> get intermediosRelacionados => _intermediosRelacionados;
  List<Insumo> _insumosRelacionados = [];
  List<Insumo> get insumosRelacionados => _insumosRelacionados;
  // --- Estado principal ---
  List<Evento> _eventos = [];
  List<Evento> get eventos => _eventos;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // Relaciones actuales cargadas para edición
  List<PlatoEvento> _platosEvento = [];
  List<PlatoEvento> get platosEvento => _platosEvento;
  List<InsumoEvento> _insumosEvento = [];
  List<InsumoEvento> get insumosEvento => _insumosEvento;
  List<IntermedioEvento> _intermediosEvento = [];
  List<IntermedioEvento> get intermediosEvento => _intermediosEvento;

  final EventoFirestoreRepository repository;
  final PlatoEventoFirestoreRepository platoEventoRepository;
  final InsumoEventoFirestoreRepository insumoEventoRepository;
  final IntermedioEventoFirestoreRepository intermedioEventoRepository;

  String searchText = '';
  bool? facturableFiltro;
  EstadoEvento? estadoFiltro;
  TipoEvento? tipoFiltro;
  DateTimeRange? fechaRangoFiltro;

  BuscadorEventosController({
    required this.repository,
    required this.platoEventoRepository,
    required this.insumoEventoRepository,
    required this.intermedioEventoRepository,
  });

  Future<void> cargarEventos() async {
    _loading = true;
    notifyListeners();
    try {
      _eventos =
          await repository.obtenerTodos(); // Implementa este método en el repo
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> eliminarEvento(String id) async {
    try {
      await repository.eliminar(id);
      await platoEventoRepository.eliminarPorEvento(id);
      await insumoEventoRepository.eliminarPorEvento(id);
      await intermedioEventoRepository.eliminarPorEvento(id);
      _eventos.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crear un evento y sus relaciones
  Future<Evento?> crearEventoConRelaciones(
    Evento evento,
    List<PlatoEvento> platosEvento,
    List<InsumoEvento> insumosEvento,
    List<IntermedioEvento> intermediosEvento,
  ) async {
    _loading = true;
    notifyListeners();
    try {
      final creado = await repository.crear(evento);
      final platosConId =
          platosEvento.map((p) => p.copyWith(eventoId: creado.id!)).toList();
      final insumosConId =
          insumosEvento.map((i) => i.copyWith(eventoId: creado.id!)).toList();
      final intermediosConId =
          intermediosEvento
              .map((i) => i.copyWith(eventoId: creado.id!))
              .toList();
      // Primero eliminamos las relaciones existentes
      await platoEventoRepository.eliminarPorEvento(creado.id!);
      // Luego creamos las nuevas relaciones
      await platoEventoRepository.crearMultiples(creado.id!, platosConId);
      await insumoEventoRepository.eliminarPorEvento(creado.id!);
      if (insumosConId.isNotEmpty) {
        await insumoEventoRepository.crearMultiples(creado.id!, insumosConId);
      }
      // Primero eliminamos las relaciones existentes
      await intermedioEventoRepository.eliminarPorEvento(creado.id!);
      // Luego creamos las nuevas relaciones
      await intermedioEventoRepository.crearMultiples(
        creado.id!,
        intermediosConId,
      );
      _eventos.add(creado);
      _error = null;
      notifyListeners();
      return creado;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Actualizar un evento y sus relaciones
  Future<bool> actualizarEventoConRelaciones(
    Evento evento,
    List<PlatoEvento> nuevosPlatosEvento,
    List<InsumoEvento> nuevosInsumosEvento,
    List<IntermedioEvento> nuevosIntermediosEvento,
  ) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.actualizar(evento);
      
      // Actualizar platos
      for (final nuevoPlato in nuevosPlatosEvento) {
        final existe = await platoEventoRepository.existeRelacion(
          nuevoPlato.platoId,
          evento.id!,
        );
        if (existe) {
          await platoEventoRepository.actualizar(nuevoPlato);
        } else {
          await platoEventoRepository.crear(nuevoPlato);
        }
      }
      
      // Actualizar insumos
      for (final nuevoInsumo in nuevosInsumosEvento) {
        final existe = await insumoEventoRepository.existeRelacion(
          nuevoInsumo.insumoId,
          evento.id!,
        );
        if (existe) {
          await insumoEventoRepository.actualizar(nuevoInsumo);
        } else {
          await insumoEventoRepository.crear(nuevoInsumo);
        }
      }
      
      // Actualizar intermedios
      for (final nuevoIntermedio in nuevosIntermediosEvento) {
        final existe = await intermedioEventoRepository.existeRelacion(
          nuevoIntermedio.intermedioId,
          evento.id!,
        );
        if (existe) {
          await intermedioEventoRepository.actualizar(nuevoIntermedio);
        } else {
          await intermedioEventoRepository.crear(nuevoIntermedio);
        }
      }
      
      final idx = _eventos.indexWhere((e) => e.id == evento.id);
      if (idx != -1) _eventos[idx] = evento;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cargar relaciones de un evento específico
  Future<void> cargarRelacionesPorEvento(String eventoId) async {
    _loading = true;
    notifyListeners();
    try {
      _platosEvento = await platoEventoRepository.obtenerPorEvento(eventoId);
      _insumosEvento = await insumoEventoRepository.obtenerPorEvento(eventoId);
      _intermediosEvento = await intermedioEventoRepository.obtenerPorEvento(
        eventoId,
      );
      _error = null;
    } catch (e) {
      _platosEvento = [];
      _insumosEvento = [];
      _intermediosEvento = [];
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  void setFacturableFiltro(bool? value) {
    facturableFiltro = value;
    notifyListeners();
  }

  void setEstadoFiltro(EstadoEvento? value) {
    estadoFiltro = value;
    notifyListeners();
  }

  void setTipoFiltro(TipoEvento? value) {
    tipoFiltro = value;
    notifyListeners();
  }

  void setFechaRangoFiltro(DateTimeRange? value) {
    fechaRangoFiltro = value;
    notifyListeners();
  }

  /// Obtiene los objetos base relacionados a un evento (platos, intermedios, insumos)
  Future<void> fetchDatosRelacionadosEvento({
    required PlatoRepository platoRepository,
    required IntermedioRepository intermedioRepository,
    required InsumoRepository insumoRepository,
  }) async {
    // Requiere que cargarRelacionesPorEvento ya se haya ejecutado
    try {
      // Platos
      final platosIds = _platosEvento.map((pe) => pe.platoId).toList();
      _platosRelacionados = await platoRepository.obtenerVarios(platosIds);

      // Intermedios
      final intermediosIds = _intermediosEvento.map((ie) => ie.intermedioId).toList();
      _intermediosRelacionados = await intermedioRepository.obtenerPorIds(intermediosIds);

      // Insumos
      final insumosIds = _insumosEvento.map((ie) => ie.insumoId).toList();
      _insumosRelacionados = await insumoRepository.obtenerVarios(insumosIds);

      notifyListeners();
    } catch (e) {
      // Si hay error, limpiar y notificar
      _platosRelacionados = [];
      _intermediosRelacionados = [];
      _insumosRelacionados = [];
      _error = e.toString();
      notifyListeners();
    }
  }
}

//buscador_eventos_screen.dart
import 'package:flutter/material.dart';
import '../../../../models/evento.dart';
import '../widgets/busqueda_bar_eventos.dart';
import '../widgets/lista_eventos.dart';
import 'editar_evento_screen.dart';
import 'package:provider/provider.dart';
import '../controllers/buscador_eventos_controller.dart';

class BuscadorEventosScreen extends StatefulWidget {
  const BuscadorEventosScreen({Key? key}) : super(key: key);

  @override
  State<BuscadorEventosScreen> createState() => _BuscadorEventosScreenState();
}

class _BuscadorEventosScreenState extends State<BuscadorEventosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
  super.initState();
  _searchController.addListener(_onSearchChanged);
  _cargarEventosDespuesDeMontar();
}

void _cargarEventosDespuesDeMontar() {
  // Espera al próximo frame para asegurar que el widget está montado
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Provider.of<BuscadorEventosController>(context, listen: false).cargarEventos();
    }
  });
}

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<BuscadorEventosController>(context, listen: false)
        .setSearchText(_searchController.text);
  }

  void _abrirNuevoEvento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEventoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _abrirNuevoEvento,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda
            BusquedaBarEventos(
              controller: _searchController,
              onChanged: (value) {},
            ),
            const SizedBox(height: 8),
            
            // Filtros
            Consumer<BuscadorEventosController>(
              builder: (context, controller, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        // Filtros rápidos de facturación
                        FilterChip(
                          label: const Text('Facturable'),
                          selected: controller.facturableFiltro == true,
                          onSelected: (v) => controller.setFacturableFiltro(v ? true : null),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('No facturable'),
                          selected: controller.facturableFiltro == false,
                          onSelected: (v) => controller.setFacturableFiltro(v ? false : null),
                        ),
                        const Spacer(),
                        
                        // Botón para limpiar filtros
                        if (controller.facturableFiltro != null ||
                            controller.estadoFiltro != null ||
                            controller.tipoFiltro != null ||
                            controller.fechaRangoFiltro != null)
                          TextButton(
                            onPressed: () {
                              controller.setFacturableFiltro(null);
                              controller.setEstadoFiltro(null);
                              controller.setTipoFiltro(null);
                              controller.setFechaRangoFiltro(null);
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Filtro por estado
                        DropdownButton<EstadoEvento?>(
                          value: controller.estadoFiltro,
                          hint: const Text('Estado'),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...EstadoEvento.values.map((estado) => DropdownMenuItem(
                              value: estado,
                              child: Text(estado.toString().split('.').last),
                            ),
                        )],
                          onChanged: (value) => controller.setEstadoFiltro(value),
                        ),
                        const SizedBox(width: 8),
                        
                        // Filtro por tipo
                        DropdownButton<TipoEvento?>(
                          value: controller.tipoFiltro,
                          hint: const Text('Tipo'),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...TipoEvento.values.map((tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo.toString().split('.').last),
                            )),
                          ],
                          onChanged: (value) => controller.setTipoFiltro(value),
                        ),
                        const SizedBox(width: 8),
                        
                        // Filtro por fecha
                        ElevatedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            controller.fechaRangoFiltro != null
                                ? '${controller.fechaRangoFiltro!.start.day}/${controller.fechaRangoFiltro!.start.month} - ${controller.fechaRangoFiltro!.end.day}/${controller.fechaRangoFiltro!.end.month}'
                                : 'Fechas',
                          ),
                          onPressed: () async {
                            final initialDateRange = controller.fechaRangoFiltro ??
                                DateTimeRange(
                                  start: DateTime.now(),
                                  end: DateTime.now().add(const Duration(days: 30)),
                                );
                            
                            final pickedRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDateRange: initialDateRange,
                            );
                            
                            if (pickedRange != null) {
                              controller.setFechaRangoFiltro(pickedRange);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Lista de eventos
            Expanded(
              child: Consumer<BuscadorEventosController>(
                builder: (context, controller, _) {
                  if (controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (controller.error != null) {
                    return Center(
                      child: Text('Error: ${controller.error}'),
                    );
                  }
                  
                  final eventosFiltrados = controller.eventos.where((evento) {
                    // Filtro por texto de búsqueda
                    final matchesText = controller.searchText.isEmpty ||
                        evento.nombreCliente.toLowerCase().contains(controller.searchText.toLowerCase()) ||
                        evento.codigo.toLowerCase().contains(controller.searchText.toLowerCase());
                    
                    // Filtro por facturable
                    final matchesFacturable = controller.facturableFiltro == null ||
                        evento.facturable == controller.facturableFiltro;
                    
                    // Filtro por estado
                    final matchesEstado = controller.estadoFiltro == null ||
                        evento.estado == controller.estadoFiltro;
                    
                    // Filtro por tipo
                    final matchesTipo = controller.tipoFiltro == null ||
                        evento.tipoEvento == controller.tipoFiltro;
                    
                    // Filtro por fecha
                    final matchesFecha = controller.fechaRangoFiltro == null ||
                        (evento.fecha.isAfter(controller.fechaRangoFiltro!.start) &&
                            evento.fecha.isBefore(controller.fechaRangoFiltro!.end));
                    
                    return matchesText && matchesFacturable && matchesEstado && matchesTipo && matchesFecha;
                  }).toList();
                  
                  if (eventosFiltrados.isEmpty) {
                    return const Center(
                      child: Text('No hay eventos que coincidan con los filtros'),
                    );
                  }
                  
                  return ListaEventos(
                    eventos: eventosFiltrados,
                    onVerDetalle: (evento) {
                      // TODO: Implementar navegación a pantalla de detalle
                    },
                    onEditar: (evento) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarEventoScreen(evento: evento),
                        ),
                      );
                    },
                    onEliminar: (evento) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar evento'),
                          content: Text('¿Seguro que deseas eliminar el evento "${evento.codigo}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await controller.eliminarEvento(evento.id!);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// editar_evento_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_insumo_evento.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_intermedio_evento.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_plato_evento.dart';

import 'package:golo_app/models/intermedio.dart';

import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/evento.dart';
import 'package:intl/intl.dart';
import '../widgets/lista_platos_evento.dart';
import '../widgets/lista_intermedios_evento.dart';
import '../widgets/lista_insumos_evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:provider/provider.dart';
import '../controllers/buscador_eventos_controller.dart';
import '../widgets/modal_agregar_platos_evento.dart';
import '../widgets/modal_agregar_intermedios_evento.dart';
import '../widgets/modal_agregar_insumos_evento.dart';

class EditarEventoScreen extends StatefulWidget {
  final Evento? evento;
  const EditarEventoScreen({Key? key, this.evento}) : super(key: key);

  @override
  State<EditarEventoScreen> createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  // Estado local para las listas del evento
  List<PlatoEvento> _platosEvento = [];
  List<IntermedioEvento> _intermediosEvento = [];
  List<InsumoEvento> _insumosEvento = [];

  Future<void> _abrirModalPlatos() async {
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    if (platoCtrl.platos.isEmpty) {
      await platoCtrl.cargarPlatos();
    }
    final seleccionados = await showDialog<List<Plato>>(
      context: context,
      builder:
          (ctx) => ModalAgregarPlatosEvento(
            platosIniciales: _platosEvento,
            onGuardar: (nuevos) {
              setState(() => _platosEvento = List.from(nuevos));
            },
          ),
    );
    if (seleccionados != null) {
      setState(() {
        final nuevos = List<PlatoEvento>.from(_platosEvento);
        final nuevosPlatos =
            seleccionados.map((plato) {
              final existente = nuevos.firstWhere(
                (pe) => pe.platoId == plato.id,
                orElse:
                    () => PlatoEvento(
                      eventoId: widget.evento?.id ?? '',
                      platoId: plato.id!,
                      cantidad: 1,
                    ),
              );
              return existente;
            }).toList();
        _platosEvento = nuevosPlatos;
      });
    }
  }

  Future<void> _editarPlatoRequerido(PlatoEvento pe) async {
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    if (platoCtrl.platos.isEmpty) await platoCtrl.cargarPlatos();
    final idx = platoCtrl.platos.indexWhere((x) => x.id == pe.platoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plato no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final plato = platoCtrl.platos[idx];
    final editado = await showDialog<PlatoEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadPlatoEvento(
            platoEvento: pe,
            plato: plato,
            onGuardar: (nuevaCantidad) {
              Navigator.of(
                ctx,
              ).pop(pe.copyWith(cantidad: nuevaCantidad.toInt()));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _platosEvento.indexWhere(
          (x) => x.platoId == pe.platoId,
        );
        if (idxLocal != -1) _platosEvento[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioEvento ie) async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty)
      await intermedioCtrl.cargarIntermedios();
    final idx = intermedioCtrl.intermedios.indexWhere(
      (x) => x.id == ie.intermedioId,
    );
    Intermedio intermedio;
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intermedio no encontrado en catálogo actual.'),
        ),
      );
      intermedio = Intermedio(
        id: ie.intermedioId,
        codigo: '',
        nombre: 'Intermedio desconocido',
        categorias: [],
        unidad: '',
        cantidadEstandar: 0,
        reduccionPorcentaje: 0,
        receta: '',
        tiempoPreparacionMinutos: 0,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        activo: true,
      );
    } else {
      intermedio = intermedioCtrl.intermedios[idx];
    }
    final editado = await showDialog<IntermedioEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioEvento(
            intermedioEvento: ie,
            intermedio: intermedio,
            onGuardar: (nuevaCantidad) {
              Navigator.of(
                ctx,
              ).pop(ie.copyWith(cantidad: nuevaCantidad.toInt()));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _intermediosEvento.indexWhere(
          (x) => x.intermedioId == ie.intermedioId,
        );
        if (idxLocal != -1) _intermediosEvento[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarInsumoRequerido(InsumoEvento ie) async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) await insumoCtrl.cargarInsumos();
    final idx = insumoCtrl.insumos.indexWhere((x) => x.id == ie.insumoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insumo no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final insumo = insumoCtrl.insumos[idx];
    final editado = await showDialog<InsumoEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoEvento(
            insumoEvento: ie,
            insumo: insumo,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(ie.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _insumosEvento.indexWhere(
          (x) => x.insumoId == ie.insumoId,
        );
        if (idxLocal != -1) _insumosEvento[idxLocal] = editado;
      });
    }
  }

  void _eliminarPlatoRequerido(PlatoEvento pe) {
    setState(() {
      _platosEvento.removeWhere((x) => x.platoId == pe.platoId);
    });
  }

  void _eliminarIntermedioRequerido(IntermedioEvento ie) {
    setState(() {
      _intermediosEvento.removeWhere((x) => x.intermedioId == ie.intermedioId);
    });
  }

  void _abrirModalIntermedios() async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty) {
      await intermedioCtrl.cargarIntermedios();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarIntermediosEvento(
            intermediosIniciales: _intermediosEvento,
            onGuardar: (nuevos) {
              setState(() => _intermediosEvento = List.from(nuevos));
            },
          ),
    );
  }

  void _abrirModalInsumos() async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      await insumoCtrl.cargarInsumos();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosEvento(
            insumosIniciales: _insumosEvento,
            onGuardar: (nuevos) {
              setState(() => _insumosEvento = List.from(nuevos));
            },
          ),
    );
  }

  // Etiquetas amigables para los enums
  String _etiquetaTipoEvento(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.matrimonio:
        return 'Matrimonio';
      case TipoEvento.produccionAudiovisual:
        return 'Producción Audiovisual';
      case TipoEvento.chefEnCasa:
        return 'Chef en Casa';
      case TipoEvento.institucional:
        return 'Institucional';
    }
  }

  String _etiquetaEstadoEvento(EstadoEvento estado) {
    switch (estado) {
      case EstadoEvento.cotizado:
        return 'Cotizado';
      case EstadoEvento.confirmado:
        return 'Confirmado';
      case EstadoEvento.esCotizacion:
        return 'En Cotización';
      case EstadoEvento.enPruebaMenu:
        return 'En Prueba de Menú';
      case EstadoEvento.completado:
        return 'Completado';
      case EstadoEvento.cancelado:
        return 'Cancelado';
    }
  }

  late TextEditingController _nombreClienteController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  late TextEditingController _ubicacionController;
  late TextEditingController _comentariosLogisticaController;
  late TextEditingController _numeroInvitadosController;
  late DateTime _fecha;
  late TipoEvento _tipoEvento;
  late EstadoEvento _estadoEvento;
  late bool _facturable;

  @override
  void initState() {
    final e = widget.evento;
    _nombreClienteController = TextEditingController(
      text: e?.nombreCliente ?? '',
    );
    _telefonoController = TextEditingController(text: e?.telefono ?? '');
    _correoController = TextEditingController(text: e?.correo ?? '');
    _ubicacionController = TextEditingController(text: e?.ubicacion ?? '');
    _comentariosLogisticaController = TextEditingController(
      text: e?.comentariosLogistica ?? '',
    );
    _numeroInvitadosController = TextEditingController(
      text: e?.numeroInvitados.toString() ?? '',
    );
    _fecha = e?.fecha ?? DateTime.now();
    _tipoEvento = e?.tipoEvento ?? TipoEvento.institucional;
    _estadoEvento = e?.estado ?? EstadoEvento.cotizado;
    _facturable = e?.facturable ?? false;
    super.initState();

    // Si es edición, cargar relaciones del evento desde el controller
    if (e != null && e.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = Provider.of<BuscadorEventosController>(
          context,
          listen: false,
        );
        await controller.cargarRelacionesPorEvento(e.id!);
        setState(() {
          _platosEvento = List.from(controller.platosEvento);
          _intermediosEvento = List.from(controller.intermediosEvento);
          _insumosEvento = List.from(controller.insumosEvento);
        });
      });
    }
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ubicacionController.dispose();
    _comentariosLogisticaController.dispose();
    _numeroInvitadosController.dispose();
    super.dispose();
  }

  void _guardarEvento() async {
    debugPrint('===> [_guardarEvento] Iniciando guardado de evento');

    // Validar campos requeridos
    if (_nombreClienteController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Nombre del cliente es requerido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del cliente es requerido')),
      );
      return;
    }

    if (_telefonoController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Teléfono es requerido');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El teléfono es requerido')));
      return;
    }

    if (_correoController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Correo es requerido');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El correo es requerido')));
      return;
    }

    if (!mounted) {
      debugPrint(
        '===> [_guardarEvento] Widget no montado, cancelando guardado',
      );
      return;
    }

    debugPrint('===> [_guardarEvento] Construyendo objeto Evento');
    final evento = Evento(
      id: widget.evento?.id,
      codigo: widget.evento?.codigo ?? '',
      nombreCliente: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      ubicacion: _ubicacionController.text.trim(),
      numeroInvitados: int.tryParse(_numeroInvitadosController.text) ?? 0,
      tipoEvento: _tipoEvento,
      estado: _estadoEvento,
      fecha: _fecha,
      fechaCotizacion: widget.evento?.fechaCotizacion,
      fechaConfirmacion: widget.evento?.fechaConfirmacion,
      fechaCreacion: widget.evento?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      comentariosLogistica: _comentariosLogisticaController.text.trim(),
      facturable: _facturable,
    );

    debugPrint(
      '===> [_guardarEvento] Evento construido: id=${evento.id}, nombreCliente=${evento.nombreCliente}, fecha=${evento.fecha}',
    );

    final controller = Provider.of<BuscadorEventosController>(
      context,
      listen: false,
    );
    bool exito;

    if (widget.evento == null) {
      debugPrint('===> [_guardarEvento] Creando evento nuevo');
      final creado = await controller.crearEventoConRelaciones(
        evento,
        _platosEvento,
        _insumosEvento,
        _intermediosEvento,
      );
      exito = creado != null;
    } else {
      debugPrint('===> [_guardarEvento] Actualizando evento existente');
      exito = await controller.actualizarEventoConRelaciones(
        evento,
        _platosEvento,
        _insumosEvento,
        _intermediosEvento,
      );
    }

    if (!mounted) {
      debugPrint(
        '===> [_guardarEvento] Widget desmontado después de guardar, no navego ni muestro SnackBar',
      );
      return;
    }

    if (exito) {
      debugPrint(
        '===> [_guardarEvento] Guardado exitoso, navegando hacia atrás',
      );
      Navigator.of(context).pop();
    } else {
      debugPrint('===> [_guardarEvento] Error al guardar: ${controller.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al guardar el evento'),
        ),
      );
    }

    debugPrint('===> [_guardarEvento] Fin de _guardarEvento');
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.evento != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Evento' : 'Nuevo Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esEdicion)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text(
                      'Código:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.evento!.codigo),
                  ],
                ),
              ),
            TextField(
              controller: _nombreClienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
              ),
            ),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: 'Ubicación'),
            ),
            TextField(
              controller: _numeroInvitadosController,
              decoration: const InputDecoration(
                labelText: 'Número de invitados',
              ),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Fecha del evento:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(_fecha)),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _fecha = picked);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text(
                      'Facturable',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _facturable,
                      onChanged: (v) => setState(() => _facturable = v),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoEvento>(
                    value:
                        TipoEvento.values.contains(_tipoEvento)
                            ? _tipoEvento
                            : null,
                    items:
                        TipoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_etiquetaTipoEvento(e)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _tipoEvento = v!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<EstadoEvento>(
                    value:
                        EstadoEvento.values.contains(_estadoEvento)
                            ? _estadoEvento
                            : null,
                    items:
                        EstadoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_etiquetaEstadoEvento(e)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _estadoEvento = v!),
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
              ],
            ),

            TextField(
              controller: _comentariosLogisticaController,
              decoration: const InputDecoration(
                labelText: 'Comentarios logística',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Platos del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _abrirModalPlatos,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaPlatosEvento(
                platosEvento: _platosEvento,
                onEditar: _editarPlatoRequerido,
                onEliminar: _eliminarPlatoRequerido,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Intermedios del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _abrirModalIntermedios,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaIntermediosEvento(
                intermediosEvento: _intermediosEvento,
                onEditar: _editarIntermedioRequerido,
                onEliminar: _eliminarIntermedioRequerido,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Insumos del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Insumos'),
                  onPressed: _abrirModalInsumos,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaInsumosEvento(
                insumosEvento: _insumosEvento,
                onEditar: _editarInsumoRequerido,
                onEliminar: (ie) {
                  setState(() {
                    _insumosEvento.removeWhere(
                      (x) => x.insumoId == ie.insumoId,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarEvento,
              child: Text(esEdicion ? 'Guardar cambios' : 'Crear evento'),
            ),
          ],
        ),
      ),
    );
  }
}


