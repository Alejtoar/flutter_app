// intermedio_requerido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IntermedioRequerido {
  final String? id;
  final String platoId;
  final String intermedioId;
  final double cantidad;

  const IntermedioRequerido({
    this.id,
    required this.platoId,
    required this.intermedioId,
    required this.cantidad,
  });

  factory IntermedioRequerido.crear({
    String? id,
    required String platoId,
    required String intermedioId,
    required double cantidad,
  }) {
    return IntermedioRequerido(
      id: id,
      platoId: platoId,
      intermedioId: intermedioId,
      cantidad: cantidad,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'platoId': platoId,
      'intermedioId': intermedioId,
      'cantidad': cantidad,
    };
  }

  factory IntermedioRequerido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntermedioRequerido(
      id: doc.id,
      platoId: data['platoId'] as String,
      intermedioId: data['intermedioId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  factory IntermedioRequerido.fromMap(Map<String, dynamic> data) {
    return IntermedioRequerido(
      id: data['id'] ?? '',
      platoId: data['platoId'] ?? '',
      intermedioId: data['intermedioId'] ?? '',
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  IntermedioRequerido copyWith({
    String? id,
    String? platoId,
    String? intermedioId,
    double? cantidad,
  }) {
    return IntermedioRequerido(
      id: id ?? this.id,
      platoId: platoId ?? this.platoId,
      intermedioId: intermedioId ?? this.intermedioId,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IntermedioRequerido &&
        other.id == id &&
        other.platoId == platoId &&
        other.intermedioId == intermedioId &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, platoId, intermedioId, cantidad);

  @override
  String toString() {
    return 'IntermedioRequerido(id: $id, platoId: $platoId, intermedioId: $intermedioId, cantidad: $cantidad)';
  }
}
