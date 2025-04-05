import 'package:cloud_firestore/cloud_firestore.dart';

class Insumo {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final String unidad;
  final double precioUnitario;
  final String proveedorId;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  // 2. Constructor const (sin validaciones directas)
  const Insumo({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.unidad,
    required this.precioUnitario,
    required this.proveedorId,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  });

  // 3. Factory constructor para creación con validación
  factory Insumo.crear({
    String? id,
    required String codigo,
    required String nombre,
    required String unidad,
    required double precioUnitario,
    required String proveedorId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    // Validar campos básicos
    _validarCampos(
      codigo: codigo,
      nombre: nombre,
      unidad: unidad,
      precioUnitario: precioUnitario,
      proveedorId: proveedorId,
    );

    final ahora = DateTime.now();
    return Insumo(
      id: id,
      codigo: codigo,
      nombre: nombre,
      unidad: unidad,
      precioUnitario: precioUnitario,
      proveedorId: proveedorId,
      fechaCreacion: fechaCreacion ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 4. Factory constructor para Firestore
  factory Insumo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Insumo.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      unidad: data['unidad'] ?? 'unidad',
      precioUnitario: (data['precioUnitario'] ?? 0).toDouble(),
      proveedorId: data['proveedorId'] ?? '',
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate(),
      activo: data['activo'] ?? true,
    );
  }

  // 5. Método de validación estático privado
  static void _validarCampos({
    required String codigo,
    required String nombre,
    required String unidad,
    required double precioUnitario,
    required String proveedorId,
  }) {
    final errors = <String>[];

    // Validación de código
    if (codigo.isEmpty) {
      errors.add('El código del insumo es requerido');
    } else if (!codigo.startsWith('I-')) {
      errors.add('El código debe comenzar con "I-"');
    }

    // Validación de nombre
    if (nombre.isEmpty) {
      errors.add('El nombre del insumo es requerido');
    } else if (nombre.length < 3) {
      errors.add('El nombre debe tener al menos 3 caracteres');
    }

    // Validación de unidad
    const unidadesValidas = ['unidad', 'kg', 'gr', 'lt', 'ml'];
    if (!unidadesValidas.contains(unidad)) {
      errors.add('Unidad no válida. Use: ${unidadesValidas.join(', ')}');
    }

    // Validación de precio
    if (precioUnitario <= 0) {
      errors.add('El precio unitario debe ser mayor a cero');
    }

    // Validación de proveedor
    if (proveedorId.isEmpty) {
      errors.add('Debe especificar un proveedor');
    }

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }
  }

  // 6. Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'unidad': unidad,
      'precioUnitario': precioUnitario,
      'proveedorId': proveedorId,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'activo': activo,
    };
  }

  // 7. Método copyWith para actualizaciones
  Insumo copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? unidad,
    double? precioUnitario,
    String? proveedorId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Insumo(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      proveedorId: proveedorId ?? this.proveedorId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
    );
  }

  // 8. Override de toString para debugging
  @override
  String toString() {
    return 'Insumo(id: $id, codigo: $codigo, nombre: $nombre, precio: \$$precioUnitario/$unidad)';
  }

  // 9. Métodos para comparación
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Insumo &&
        other.id == id &&
        other.codigo == codigo &&
        other.nombre == nombre &&
        other.unidad == unidad &&
        other.precioUnitario == precioUnitario &&
        other.proveedorId == proveedorId;
  }

  @override
  int get hashCode {
    return Object.hash(id, codigo, nombre, unidad, precioUnitario, proveedorId);
  }
}