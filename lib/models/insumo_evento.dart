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