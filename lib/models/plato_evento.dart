import 'package:cloud_firestore/cloud_firestore.dart';

class PlatoEvento {
  // Personalización temporal para el evento
  final String? nombrePersonalizado;
  final List<dynamic>? insumosExtra;
  final List<String>? insumosRemovidos;
  final List<dynamic>? intermediosExtra;
  final List<String>? intermediosRemovidos;
  final String? id;
  final String eventoId;
  final String platoId;
  final int cantidad;

  const PlatoEvento({
    this.id,
    required this.eventoId,
    required this.platoId,
    required this.cantidad,
    this.nombrePersonalizado,
    this.insumosExtra,
    this.insumosRemovidos,
    this.intermediosExtra,
    this.intermediosRemovidos,
  });

  factory PlatoEvento.fromMap(Map<String, dynamic> map) {
    return PlatoEvento(
      id: map['id'] as String?,
      eventoId: map['eventoId'] as String,
      platoId: map['platoId'] as String,
      cantidad: map['cantidad'] as int,
      nombrePersonalizado: map['nombrePersonalizado'] as String?,
      insumosExtra: map['insumosExtra'] as List<dynamic>?,
      insumosRemovidos: (map['insumosRemovidos'] as List<dynamic>?)?.cast<String>(),
      intermediosExtra: map['intermediosExtra'] as List<dynamic>?,
      intermediosRemovidos: (map['intermediosRemovidos'] as List<dynamic>?)?.cast<String>(),
    );
  }

  factory PlatoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatoEvento(
      id: doc.id,
      eventoId: data['eventoId'] as String,
      platoId: data['platoId'] as String,
      cantidad: data['cantidad'] as int,
      nombrePersonalizado: data['nombrePersonalizado'] as String?,
      insumosExtra: data['insumosExtra'] as List<dynamic>?,
      insumosRemovidos: (data['insumosRemovidos'] as List<dynamic>?)?.cast<String>(),
      intermediosExtra: data['intermediosExtra'] as List<dynamic>?,
      intermediosRemovidos: (data['intermediosRemovidos'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
      if (nombrePersonalizado != null) 'nombrePersonalizado': nombrePersonalizado,
      if (insumosExtra != null) 'insumosExtra': insumosExtra,
      if (insumosRemovidos != null) 'insumosRemovidos': insumosRemovidos,
      if (intermediosExtra != null) 'intermediosExtra': intermediosExtra,
      if (intermediosRemovidos != null) 'intermediosRemovidos': intermediosRemovidos,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
      if (nombrePersonalizado != null) 'nombrePersonalizado': nombrePersonalizado,
      if (insumosExtra != null) 'insumosExtra': insumosExtra,
      if (insumosRemovidos != null) 'insumosRemovidos': insumosRemovidos,
      if (intermediosExtra != null) 'intermediosExtra': intermediosExtra,
      if (intermediosRemovidos != null) 'intermediosRemovidos': intermediosRemovidos,
    };
  }

  PlatoEvento copyWith({
    String? id,
    String? eventoId,
    String? platoId,
    int? cantidad,
    String? nombrePersonalizado,
    List<dynamic>? insumosExtra,
    List<String>? insumosRemovidos,
    List<dynamic>? intermediosExtra,
    List<String>? intermediosRemovidos,
  }) {
    return PlatoEvento(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      platoId: platoId ?? this.platoId,
      cantidad: cantidad ?? this.cantidad,
      nombrePersonalizado: nombrePersonalizado ?? this.nombrePersonalizado,
      insumosExtra: insumosExtra ?? this.insumosExtra,
      insumosRemovidos: insumosRemovidos ?? this.insumosRemovidos,
      intermediosExtra: intermediosExtra ?? this.intermediosExtra,
      intermediosRemovidos: intermediosRemovidos ?? this.intermediosRemovidos,
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
    return 'PlatoEvento(id: $id, eventoId: $eventoId, platoId: $platoId, cantidad: $cantidad, nombrePersonalizado: $nombrePersonalizado, insumosExtra: $insumosExtra, insumosRemovidos: $insumosRemovidos, intermediosExtra: $intermediosExtra, intermediosRemovidos: $intermediosRemovidos)';
  }
}
