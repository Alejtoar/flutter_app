import 'package:cloud_firestore/cloud_firestore.dart';

class InsumoUtilizado {
  final String insumoId;
  final String codigo;
  final String nombre;
  final String unidad;
  final double cantidad;
  final double precioUnitario; // Snapshot del precio al momento de creación
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const InsumoUtilizado({
    required this.insumoId,
    required this.codigo,
    required this.nombre,
    required this.unidad,
    required this.cantidad,
    required this.precioUnitario,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  // Factory constructor con validación
  factory InsumoUtilizado.crear({
    required String insumoId,
    required String codigo,
    required String nombre,
    required String unidad,
    required double cantidad,
    required double precioUnitario,
    DateTime? fechaCreacion,
  }) {
    // Validación de campos
    final errors = <String>[];

    if (insumoId.isEmpty) errors.add('El ID del insumo es requerido');
    if (codigo.isEmpty) errors.add('El código del insumo es requerido');
    if (nombre.isEmpty) errors.add('El nombre del insumo es requerido');
    if (unidad.isEmpty) errors.add('La unidad es requerida');
    if (cantidad <= 0) errors.add('La cantidad debe ser mayor que cero');
    if (precioUnitario < 0) errors.add('El precio no puede ser negativo');

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    final ahora = DateTime.now();
    return InsumoUtilizado(
      insumoId: insumoId,
      codigo: codigo,
      nombre: nombre,
      unidad: unidad,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      fechaCreacion: fechaCreacion ?? ahora,
    );
  }

  // Factory constructor para Firestore
  factory InsumoUtilizado.fromFirestore(Map<String, dynamic> data) {
    return InsumoUtilizado.crear(
      insumoId: data['insumoId'] ?? '',
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      unidad: data['unidad'] ?? 'unidad',
      cantidad: (data['cantidad'] ?? 0).toDouble(),
      precioUnitario: (data['precioUnitario'] ?? 0).toDouble(),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
    );
  }

  // Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'insumoId': insumoId,
      'codigo': codigo,
      'nombre': nombre,
      'unidad': unidad,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      if (fechaActualizacion != null)
        'fechaActualizacion': Timestamp.fromDate(fechaActualizacion!),
    };
  }

  // Método copyWith para actualizaciones
  InsumoUtilizado copyWith({
    String? insumoId,
    String? codigo,
    String? nombre,
    String? unidad,
    double? cantidad,
    double? precioUnitario,
    DateTime? fechaActualizacion,
  }) {
    return InsumoUtilizado(
      insumoId: insumoId ?? this.insumoId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Métodos para comparación
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InsumoUtilizado &&
        other.insumoId == insumoId &&
        other.codigo == codigo &&
        other.nombre == nombre &&
        other.unidad == unidad &&
        other.cantidad == cantidad &&
        other.precioUnitario == precioUnitario;
  }

  @override
  int get hashCode {
    return Object.hash(
      insumoId,
      codigo,
      nombre,
      unidad,
      cantidad,
      precioUnitario,
    );
  }

  @override
  String toString() {
    return 'InsumoUtilizado(insumoId: $insumoId, nombre: $nombre, cantidad: $cantidad $unidad)';
  }
}