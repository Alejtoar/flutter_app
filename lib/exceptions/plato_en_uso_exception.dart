class PlatoEnUsoException implements Exception {
  final List<String> usos;
  PlatoEnUsoException(this.usos);

  @override
  String toString() => 'No se puede borrar el plato porque está en uso en: ${usos.join(', ')}';
}
