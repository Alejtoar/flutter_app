class PlatoEvento {
  final String? id;
  final String platoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double costoPorcion;
  final double precioVenta;
  final Map<String, dynamic>? modificaciones;

  const PlatoEvento({
    this.id,
    required this.platoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.costoPorcion,
    required this.precioVenta,
    this.modificaciones,
  });

  factory PlatoEvento.fromMap(Map<String, dynamic> map) {
    return PlatoEvento(
      id: map['id'],
      platoId: map['platoId'] ?? '',
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      costoPorcion: (map['costoPorcion'] ?? 0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0).toDouble(),
      modificaciones: map['modificaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'platoId': platoId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      'costoPorcion': costoPorcion,
      'precioVenta': precioVenta,
      if (modificaciones != null) 'modificaciones': modificaciones,
    };
  }

  double get costoTotal => costoPorcion * cantidad;
  double get ventaTotal => precioVenta * cantidad;
  double get margen => ventaTotal - costoTotal;
}
