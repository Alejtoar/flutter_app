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