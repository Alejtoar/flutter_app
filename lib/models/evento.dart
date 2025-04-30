
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