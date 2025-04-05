// intermedio_requerido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IntermedioRequerido {
  final String? id;
  final String intermedioId;
  final String codigo;
  final String nombre;
  final double cantidad;
  final String? instruccionesEspeciales;
  final DateTime fechaCreacion;
  final int orden;

  const IntermedioRequerido({
    this.id,
    required this.intermedioId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    this.instruccionesEspeciales,
    required this.fechaCreacion,
    required this.orden,
  });

  // Factory constructor con validación
  factory IntermedioRequerido.crear({
    String? id,
    required String intermedioId,
    required String codigo,
    required String nombre,
    required double cantidad,
    String? instruccionesEspeciales,
    DateTime? fechaCreacion,
    int orden = 0,
  }) {
    if (intermedioId.isEmpty) throw ArgumentError('ID de intermedio requerido');
    if (codigo.isEmpty) throw ArgumentError('Código requerido');
    if (nombre.isEmpty) throw ArgumentError('Nombre requerido');
    if (cantidad <= 0) throw ArgumentError('Cantidad debe ser positiva');

    return IntermedioRequerido(
      id: id,
      intermedioId: intermedioId,
      codigo: codigo,
      nombre: nombre,
      cantidad: cantidad,
      instruccionesEspeciales: instruccionesEspeciales,
      fechaCreacion: fechaCreacion ?? DateTime.now(),
      orden: orden,
    );
  }

  // Factory constructor para Firestore
  factory IntermedioRequerido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntermedioRequerido.fromMap(data);
  }

  // Factory constructor para Map
  factory IntermedioRequerido.fromMap(Map<String, dynamic> data) {
    return IntermedioRequerido.crear(
      id: data['id'],
      intermedioId: data['intermedioId'] ?? '',
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      instruccionesEspeciales: data['instruccionesEspeciales'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
      orden: data['orden'] ?? 0,
    );
  }

  // Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'intermedioId': intermedioId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      if (instruccionesEspeciales != null)
        'instruccionesEspeciales': instruccionesEspeciales,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'orden': orden,
    };
  }

  // Método copyWith
  IntermedioRequerido copyWith({
    String? id,
    String? intermedioId,
    String? codigo,
    String? nombre,
    double? cantidad,
    String? instruccionesEspeciales,
    int? orden,
  }) {
    return IntermedioRequerido(
      id: id ?? this.id,
      intermedioId: intermedioId ?? this.intermedioId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      instruccionesEspeciales: instruccionesEspeciales ?? this.instruccionesEspeciales,
      fechaCreacion: fechaCreacion,
      orden: orden ?? this.orden,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntermedioRequerido &&
          runtimeType == other.runtimeType &&
          intermedioId == other.intermedioId &&
          codigo == other.codigo;

  @override
  int get hashCode => Object.hash(intermedioId, codigo);

  @override
  String toString() {
    return 'IntermedioRequerido(intermedioId: $intermedioId, nombre: $nombre, cantidad: $cantidad, orden: $orden)';
  }
}
