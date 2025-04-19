import 'package:cloud_firestore/cloud_firestore.dart';

/// Relación entre Plato e Insumo (cuando un plato usa insumos directos)
class InsumoRequerido {
  final String? id;
  final String platoId;
  final String insumoId;
  final double cantidad;
  const InsumoRequerido({
    this.id,
    required this.platoId,
    required this.insumoId,
    required this.cantidad,
  });

  factory InsumoRequerido.crear({
    String? id,
    required String platoId,
    required String insumoId,
    required double cantidad,
  }) {
    return InsumoRequerido(
      id: id,
      platoId: platoId,
      insumoId: insumoId,
      cantidad: cantidad,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'platoId': platoId,
      'insumoId': insumoId,
      'cantidad': cantidad,
    };
  }

  factory InsumoRequerido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoRequerido(
      id: doc.id,
      platoId: data['platoId'] as String,
      insumoId: data['insumoId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  factory InsumoRequerido.fromMap(Map<String, dynamic> data) {
    return InsumoRequerido(
      id: data['id'],
      platoId: data['platoId'] ?? '',
      insumoId: data['insumoId'] ?? '',
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  InsumoRequerido copyWith({
    String? id,
    String? platoId,
    String? insumoId,
    double? cantidad,
  }) {
    return InsumoRequerido(
      id: id ?? this.id,
      platoId: platoId ?? this.platoId,
      insumoId: insumoId ?? this.insumoId,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InsumoRequerido &&
            other.id == id &&
            other.platoId == platoId &&
            other.insumoId == insumoId &&
            other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, platoId, insumoId, cantidad);

  @override
  String toString() {
    return 'InsumoRequerido(id: $id, platoId: $platoId, insumoId: $insumoId, cantidad: $cantidad)';
  }
}
