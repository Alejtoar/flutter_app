class ItemExtra {
  final String id;
  final num cantidad; // Usar num para aceptar int o double

  const ItemExtra({required this.id, required this.cantidad});

  // Para Firestore
  Map<String, dynamic> toJson() => {'id': id, 'cantidad': cantidad};

  // Desde Firestore
  factory ItemExtra.fromJson(Map<String, dynamic> json) {
    return ItemExtra(
      id: json['id'] as String? ?? '', // Manejo de nulos
      cantidad: json['cantidad'] as num? ?? 0, // Manejo de nulos
    );
  }
}