// intermedio_requerido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IntermedioRequerido {
  final String intermedioId;
  final String codigo;
  final String nombre;
  final double cantidad;
  final String? instruccionesEspeciales;
  final DateTime fechaCreacion;

  const IntermedioRequerido({
    required this.intermedioId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    this.instruccionesEspeciales,
    required this.fechaCreacion,
  });

  // Factory constructor con validación
  factory IntermedioRequerido.crear({
    required String intermedioId,
    required String codigo,
    required String nombre,
    required double cantidad,
    String? instruccionesEspeciales,
    DateTime? fechaCreacion,
  }) {
    if (intermedioId.isEmpty) throw ArgumentError('ID de intermedio requerido');
    if (codigo.isEmpty) throw ArgumentError('Código requerido');
    if (nombre.isEmpty) throw ArgumentError('Nombre requerido');
    if (cantidad <= 0) throw ArgumentError('Cantidad debe ser positiva');

    return IntermedioRequerido(
      intermedioId: intermedioId,
      codigo: codigo,
      nombre: nombre,
      cantidad: cantidad,
      instruccionesEspeciales: instruccionesEspeciales,
      fechaCreacion: fechaCreacion ?? DateTime.now(),
    );
  }

  // Factory constructor para Firestore
  factory IntermedioRequerido.fromFirestore(Map<String, dynamic> data) {
    return IntermedioRequerido.crear(
      intermedioId: data['intermedioId'] ?? '',
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      instruccionesEspeciales: data['instruccionesEspeciales'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
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
    };
  }

  // Método copyWith
  IntermedioRequerido copyWith({
    String? intermedioId,
    String? codigo,
    String? nombre,
    double? cantidad,
    String? instruccionesEspeciales,
  }) {
    return IntermedioRequerido(
      intermedioId: intermedioId ?? this.intermedioId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      instruccionesEspeciales: instruccionesEspeciales ?? this.instruccionesEspeciales,
      fechaCreacion: fechaCreacion,
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
    return 'IntermedioRequerido(intermedioId: $intermedioId, nombre: $nombre, cantidad: $cantidad)';
  }
}
