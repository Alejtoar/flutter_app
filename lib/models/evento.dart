import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  final String? id;
  final String codigo;
  final String nombreCliente;
  final String telefono;
  final String correo;
  final DateTime fecha;
  final String ubicacion;
  final int numeroInvitados;
  final List<PlatoEvento> platos;
  final TipoEvento tipoEvento;
  final EstadoEvento estado;
  final double presupuestoTotal;
  final double costoTotal;
  final Map<String, dynamic> requisitosEspeciales;
  final DateTime fechaCotizacion;
  final DateTime? fechaConfirmacion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool requiereInventario;
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
    required this.platos,
    required this.tipoEvento,
    required this.estado,
    required this.presupuestoTotal,
    required this.costoTotal,
    required this.requisitosEspeciales,
    required this.fechaCotizacion,
    this.fechaConfirmacion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.requiereInventario,
    this.comentariosLogistica,
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
    required List<PlatoEvento> platos,
    required TipoEvento tipoEvento,
    required EstadoEvento estado,
    required double presupuestoTotal,
    required double costoTotal,
    required Map<String, dynamic> requisitosEspeciales,
    required DateTime fechaCotizacion,
    DateTime? fechaConfirmacion,
    required DateTime fechaCreacion,
    required DateTime fechaActualizacion,
    required bool requiereInventario,
    String? comentariosLogistica,
  }) {
    // Validaciones
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (!codigo.startsWith('E-')) errors.add('El código debe comenzar con "E-"');
    if (nombreCliente.isEmpty) errors.add('El nombre del cliente es requerido');
    if (telefono.isEmpty) errors.add('El teléfono es requerido');
    if (correo.isEmpty) errors.add('El correo es requerido');
    if (ubicacion.isEmpty) errors.add('La ubicación es requerida');
    if (numeroInvitados <= 0) errors.add('El número de invitados debe ser positivo');
    if (platos.isEmpty) errors.add('Debe incluir al menos un plato');
    if (presupuestoTotal <= 0) errors.add('El presupuesto debe ser positivo');
    if (costoTotal <= 0) errors.add('El costo debe ser positivo');

    // Validación de teléfono y correo
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(telefono)) {
      errors.add('Teléfono no válido. Use formato internacional');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(correo)) {
      errors.add('Correo electrónico no válido');
    }

    final ahora = DateTime.now();
    if (fecha.isBefore(ahora)) {
      errors.add('La fecha del evento debe ser futura');
    }

    // Validaciones específicas por tipo de evento
    final diasHastaEvento = fecha.difference(ahora).inDays;

    if (tipoEvento == TipoEvento.planificado && diasHastaEvento < 15) {
      errors.add('Los eventos planificados requieren al menos 15 días de anticipación');
    }

    if (tipoEvento == TipoEvento.inmediato && diasHastaEvento > 7) {
      errors.add('Los eventos inmediatos deben estar dentro de los próximos 7 días');
    }

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
      platos: platos,
      tipoEvento: tipoEvento,
      estado: estado,
      presupuestoTotal: presupuestoTotal,
      costoTotal: costoTotal,
      requisitosEspeciales: requisitosEspeciales,
      fechaCotizacion: fechaCotizacion,
      fechaConfirmacion: fechaConfirmacion,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      requiereInventario: requiereInventario,
      comentariosLogistica: comentariosLogistica,
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evento.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombreCliente: data['nombreCliente'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      ubicacion: data['ubicacion'] ?? '',
      numeroInvitados: data['numeroInvitados'] ?? 0,
      platos: (data['platos'] as List<dynamic>)
          .map((p) => PlatoEvento.fromMap(p as Map<String, dynamic>))
          .toList(),
      tipoEvento: TipoEvento.values.firstWhere(
        (e) => e.toString() == data['tipoEvento'],
        orElse: () => TipoEvento.planificado,
      ),
      estado: EstadoEvento.values.firstWhere(
        (e) => e.toString() == data['estado'],
        orElse: () => EstadoEvento.cotizado,
      ),
      presupuestoTotal: (data['presupuestoTotal'] ?? 0).toDouble(),
      costoTotal: (data['costoTotal'] ?? 0).toDouble(),
      requisitosEspeciales: data['requisitosEspeciales'] ?? {},
      fechaCotizacion: (data['fechaCotizacion'] as Timestamp).toDate(),
      fechaConfirmacion: (data['fechaConfirmacion'] as Timestamp?)?.toDate(),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
      requiereInventario: data['requiereInventario'] ?? false,
      comentariosLogistica: data['comentariosLogistica'],
    );
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
      'platos': platos.map((p) => p.toMap()).toList(),
      'tipoEvento': tipoEvento.toString(),
      'estado': estado.toString(),
      'presupuestoTotal': presupuestoTotal,
      'costoTotal': costoTotal,
      'requisitosEspeciales': requisitosEspeciales,
      'fechaCotizacion': Timestamp.fromDate(fechaCotizacion),
      if (fechaConfirmacion != null) 'fechaConfirmacion': Timestamp.fromDate(fechaConfirmacion!),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'requiereInventario': requiereInventario,
      if (comentariosLogistica != null) 'comentariosLogistica': comentariosLogistica,
    };
  }

  Evento copyWith({
    String? id,
    String? codigo,
    String? nombreCliente,
    String? telefono,
    String? correo,
    DateTime? fecha,
    String? ubicacion,
    int? numeroInvitados,
    List<PlatoEvento>? platos,
    TipoEvento? tipoEvento,
    EstadoEvento? estado,
    double? presupuestoTotal,
    double? costoTotal,
    Map<String, dynamic>? requisitosEspeciales,
    DateTime? fechaCotizacion,
    DateTime? fechaConfirmacion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? requiereInventario,
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
      platos: platos ?? this.platos,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      estado: estado ?? this.estado,
      presupuestoTotal: presupuestoTotal ?? this.presupuestoTotal,
      costoTotal: costoTotal ?? this.costoTotal,
      requisitosEspeciales: requisitosEspeciales ?? this.requisitosEspeciales,
      fechaCotizacion: fechaCotizacion ?? this.fechaCotizacion,
      fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      requiereInventario: requiereInventario ?? this.requiereInventario,
      comentariosLogistica: comentariosLogistica ?? this.comentariosLogistica,
    );
  }

  double get margen => ventaTotalPlatos - costoTotalPlatos;

  // Métodos de utilidad
  double get ventaTotalPlatos => platos.fold(0, (total, plato) => total + plato.ventaTotal);
  double get costoTotalPlatos => platos.fold(0, (total, plato) => total + plato.costoTotal);
  double get margenGanancia => ventaTotalPlatos - costoTotalPlatos;
  double get porcentajeMargen => (margenGanancia / costoTotalPlatos) * 100;
  bool get esRentable => margenGanancia > 0;
  
  Duration get tiempoHastaEvento => fecha.difference(DateTime.now());
  bool get necesitaAtencionUrgente => tiempoHastaEvento.inDays <= 7;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
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

class PlatoEvento {
  final String platoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double costoPorcion;
  final double precioVenta;
  final Map<String, dynamic>? modificaciones;

  const PlatoEvento({
    required this.platoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.costoPorcion,
    required this.precioVenta,
    this.modificaciones,
  });

  factory PlatoEvento.fromMap(Map<String, dynamic> map) {
    return PlatoEvento(
      platoId: map['platoId'] ?? '',
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      costoPorcion: (map['costoPorcion'] ?? 0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0).toDouble(),
      modificaciones: map['modificaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platoId': platoId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      'costoPorcion': costoPorcion,
      'precioVenta': precioVenta,
      if (modificaciones != null) 'modificaciones': modificaciones,
    };
  }

  double get costoTotal => costoPorcion * cantidad;
  double get ventaTotal => precioVenta * cantidad;
  double get margen => ventaTotal - costoTotal;
}

enum TipoEvento {
  planificado, // Matrimonios, eventos grandes con planificación extendida
  inmediato    // Producciones, grabaciones, eventos con poca anticipación
}

enum EstadoEvento {
  cotizado,
  confirmado,
  enPreparacion,
  enProgreso,
  completado,
  cancelado
}
