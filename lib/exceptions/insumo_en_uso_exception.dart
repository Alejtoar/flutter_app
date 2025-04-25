class InsumoEnUsoException implements Exception {
  final List<String> usos;
  InsumoEnUsoException(this.usos);

  @override
  String toString() => 'No se puede borrar el insumo porque está en uso en: ${usos.join(', ')}';
}
