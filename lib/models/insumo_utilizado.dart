// insumo_utilizado.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa la relación entre un intermedio y un insumo,
/// conteniendo solo datos específicos de esta relación
class InsumoUtilizado {
  final String? id;
  final String insumoId; // Referencia al insumo
  final String intermedioId; // Referencia al intermedio
  final double cantidad; // Cantidad utilizada en esta relación

  const InsumoUtilizado({
    this.id,
    required this.insumoId,
    required this.intermedioId,
    required this.cantidad,
  });

  factory InsumoUtilizado.fromMap(Map<String, dynamic> data) {
    return InsumoUtilizado(
      id: data['id'] as String?,
      insumoId: data['insumoId'] as String,
      intermedioId: data['intermedioId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  /// Factory para crear desde Firestore
  factory InsumoUtilizado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoUtilizado(
      id: doc.id,
      insumoId: data['insumoId'] as String,
      intermedioId: data['intermedioId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  /// Este metodo es para servicios
  static Future<InsumoUtilizado> crearValidado({
    required String insumoId,
    required String intermedioId,
    required double cantidad,
    required String insumosCollection,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection(insumosCollection)
        .doc(insumoId)
        .get();

    if (!doc.exists) {
      throw ArgumentError('El insumo $insumoId no existe');
    }

    return InsumoUtilizado(
      insumoId: insumoId,
      intermedioId: intermedioId,
      cantidad: cantidad,
    );
  }

  /// Conversión para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'insumoId': insumoId,
      'intermedioId': intermedioId,
      'cantidad': cantidad,
    };
  }

  /// Método para actualizaciones parciales
  InsumoUtilizado copyWith({
    String? id,
    String? insumoId,
    String? intermedioId,
    double? cantidad,
  }) {
    return InsumoUtilizado(
      id: id ?? this.id,
      insumoId: insumoId ?? this.insumoId,
      intermedioId: intermedioId ?? this.intermedioId,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InsumoUtilizado &&
        other.id == id &&
        other.insumoId == insumoId &&
        other.intermedioId == intermedioId &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, insumoId, intermedioId, cantidad);

  @override
  String toString() {
    return 'InsumoUtilizado(id: $id, insumoId: $insumoId, intermedioId: $intermedioId, cantidad: $cantidad)';
  }
}