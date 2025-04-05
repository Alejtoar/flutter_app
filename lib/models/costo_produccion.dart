import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoCosto {
  directo,
  indirecto,
  adicional
}

class CostoProduccion {
  final String? id;
  final String codigo;
  final String itemId;
  final String eventoId;
  final double costoDirecto;
  final double costoIndirecto;
  final double costosIndirectos;
  final double costoTotal;
  final double margenGanancia;
  final double precioVenta;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  const CostoProduccion._crear({
    this.id,
    required this.codigo,
    required this.itemId,
    required this.eventoId,
    required this.costoDirecto,
    required this.costoIndirecto,
    required this.costosIndirectos,
    required this.costoTotal,
    required this.margenGanancia,
    required this.precioVenta,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory CostoProduccion.crear({
    String? id,
    required String codigo,
    required String itemId,
    required String eventoId,
    required double costoDirecto,
    required double costoIndirecto,
    required double costosIndirectos,
    double? costoTotal,
    double? margenGanancia,
    double? precioVenta,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    final calculatedCostoTotal = costoTotal ?? (costoDirecto + costoIndirecto + costosIndirectos);
    final calculatedMargen = margenGanancia ?? 0.0;
    final calculatedPrecioVenta = precioVenta ?? calculatedCostoTotal * (1 + calculatedMargen / 100);

    return CostoProduccion._crear(
      id: id,
      codigo: codigo,
      itemId: itemId,
      eventoId: eventoId,
      costoDirecto: costoDirecto,
      costoIndirecto: costoIndirecto,
      costosIndirectos: costosIndirectos,
      costoTotal: calculatedCostoTotal,
      margenGanancia: calculatedMargen,
      precioVenta: calculatedPrecioVenta,
      fechaCreacion: fechaCreacion ?? DateTime.now(),
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
    );
  }

  factory CostoProduccion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final costoDirecto = (data['costoDirecto'] ?? 0).toDouble();
    final costoIndirecto = (data['costoIndirecto'] ?? 0).toDouble();
    final costosIndirectos = (data['costosIndirectos'] ?? 0).toDouble();
    final costoTotal = (data['costoTotal'] ?? 0).toDouble();
    final margenGanancia = (data['margenGanancia'] ?? 0).toDouble();
    final precioVenta = (data['precioVenta'] ?? 0).toDouble();
    
    return CostoProduccion.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      itemId: data['itemId'] ?? '',
      eventoId: data['eventoId'] ?? '',
      costoDirecto: costoDirecto,
      costoIndirecto: costoIndirecto,
      costosIndirectos: costosIndirectos,
      costoTotal: costoTotal,
      margenGanancia: margenGanancia,
      precioVenta: precioVenta,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'codigo': codigo,
      'itemId': itemId,
      'eventoId': eventoId,
      'costoDirecto': costoDirecto,
      'costoIndirecto': costoIndirecto,
      'costosIndirectos': costosIndirectos,
      'costoTotal': costoTotal,
      'margenGanancia': margenGanancia,
      'precioVenta': precioVenta,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
    };
  }

  CostoProduccion copyWith({
    String? id,
    String? codigo,
    String? itemId,
    String? eventoId,
    double? costoDirecto,
    double? costoIndirecto,
    double? costosIndirectos,
    double? costoTotal,
    double? margenGanancia,
    double? precioVenta,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return CostoProduccion.crear(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      itemId: itemId ?? this.itemId,
      eventoId: eventoId ?? this.eventoId,
      costoDirecto: costoDirecto ?? this.costoDirecto,
      costoIndirecto: costoIndirecto ?? this.costoIndirecto,
      costosIndirectos: costosIndirectos ?? this.costosIndirectos,
      costoTotal: costoTotal ?? this.costoTotal,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      precioVenta: precioVenta ?? this.precioVenta,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Métodos de cálculo
  double get costoTotalCalculado => costoDirecto + costoIndirecto + costosIndirectos;
  double get utilidad => precioVenta - costoTotal;
  double get margenUtilidadPorcentaje => costoTotal > 0 ? (utilidad / costoTotal) * 100 : 0;

  double get precioVentaSugerido {
    final factor = 1 + (margenGanancia / 100);
    return costoTotal * factor;
  }

  double get utilidadEstimada => precioVentaSugerido - costoTotal;

  // Métodos de análisis
  Map<String, double> get distribucionCostos {
    if (costoTotal <= 0) {
      return {
      'directo': 0,
      'indirecto': 0,
      'adicional': 0
    };
    }

    return {
      'directo': (costoDirecto / costoTotal) * 100,
      'indirecto': (costoIndirecto / costoTotal) * 100,
      'adicional': (costosIndirectos / costoTotal) * 100,
    };
  }

  bool get esRentable => margenGanancia >= 30; // Umbral configurable

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CostoProduccion &&
        other.id == id &&
        other.codigo == codigo;
  }

  @override
  int get hashCode => Object.hash(id, codigo);

  @override
  String toString() {
    return 'CostoProduccion(id: $id, codigo: $codigo, itemId: $itemId, costoTotal: $costoTotal)';
  }
}
