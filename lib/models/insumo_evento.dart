// insumo_evento.dart
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
    final data = doc.data() as Map<String, dynamic>?; // Hacer data nullable

    if (data == null) {
      // Opción 1: Lanzar excepción específica si la data es totalmente nula
      throw Exception(
        "Documento ${doc.id} en 'insumos_eventos' no contiene datos.",
      );
      // Opción 2: Retornar un objeto inválido (menos recomendado para relaciones)
      // return InsumoEvento(id: doc.id, eventoId: 'ERROR_NULL_DATA', insumoId: 'ERROR_NULL_DATA', cantidad: 0, unidad: 'ERR');
    }

    // Validar campos requeridos String
    final eventoId = data['eventoId'] as String?;
    final insumoId = data['insumoId'] as String?;
    final unidad =
        data['unidad'] as String?; // Hacer la unidad nullable si puede serlo

    if (eventoId == null || eventoId.isEmpty) {
      throw Exception(
        "Campo 'eventoId' faltante o vacío en InsumoEvento ${doc.id}",
      );
    }
    if (insumoId == null || insumoId.isEmpty) {
      throw Exception(
        "Campo 'insumoId' faltante o vacío en InsumoEvento ${doc.id}",
      );
    }
    // Considera si 'unidad' puede ser null o vacía. Si no, añade validación.
    // if (unidad == null || unidad.isEmpty) {
    //   throw Exception("Campo 'unidad' faltante o vacío en InsumoEvento ${doc.id}");
    // }

    return InsumoEvento(
      id: doc.id,
      eventoId: eventoId,
      insumoId: insumoId,
      cantidad:
          (data['cantidad'] as num?)?.toDouble() ??
          0.0, // Manejo seguro de cantidad
      unidad:
          unidad ?? 'sin unidad', // Usar '?' u otro default si puede ser null/vacía, sino usar unidad!
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
