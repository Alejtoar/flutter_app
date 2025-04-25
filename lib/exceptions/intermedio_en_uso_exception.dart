class IntermedioEnUsoException implements Exception {
  final List<String> usos;
  IntermedioEnUsoException(this.usos);

  @override
  String toString() => 'No se puede borrar el intermedio porque está en uso en: ${usos.join(', ')}';
}
