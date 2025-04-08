import 'package:cloud_firestore/cloud_firestore.dart';

class PlatoEvento {
  final String? id;
  final String eventoId;
  final String platoId;
  final int cantidad;

  const PlatoEvento({
    this.id,
    required this.eventoId,
    required this.platoId,
    required this.cantidad,
  });

  factory PlatoEvento.fromMap(Map<String, dynamic> map) {
    return PlatoEvento(
      id: map['id'] as String?,
      eventoId: map['eventoId'] as String,
      platoId: map['platoId'] as String,
      cantidad: map['cantidad'] as int,
    );
  }

  factory PlatoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatoEvento(
      id: doc.id,
      eventoId: data['eventoId'] as String,
      platoId: data['platoId'] as String,
      cantidad: data['cantidad'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
    };
  }

  PlatoEvento copyWith({
    String? id,
    String? eventoId,
    String? platoId,
    int? cantidad,
  }) {
    return PlatoEvento(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      platoId: platoId ?? this.platoId,
      cantidad: cantidad ?? this.cantidad,
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
    return 'PlatoEvento(id: $id, eventoId: $eventoId, platoId: $platoId, cantidad: $cantidad)';
  }
}
