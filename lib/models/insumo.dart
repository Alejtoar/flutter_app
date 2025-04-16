// insumo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Insumo {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final List<String> categorias;
  final String unidad;
  final double precioUnitario;
  final String proveedorId;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  // Categorías predefinidas con sus iconos y colores
  static Map<String, Map<String, dynamic>> categoriasInsumos = {
    'lácteos': {'icon': Icons.local_drink, 'color': Colors.blueAccent},
    'cárnicos': {'icon': Icons.set_meal, 'color': Colors.redAccent},
    'vegetales': {'icon': Icons.eco, 'color': Colors.greenAccent},
    'frutas': {'icon': Icons.apple, 'color': Colors.red[200]!},
    'especias': {'icon': Icons.spa, 'color': Colors.orangeAccent},
    'granos': {'icon': Icons.grain, 'color': Colors.brown[300]!},
    'panadería': {'icon': Icons.bakery_dining, 'color': Colors.amber[200]!},
    'repostería': {'icon': Icons.cake, 'color': Colors.pinkAccent},
    'bebidas': {'icon': Icons.local_bar, 'color': Colors.purpleAccent},
    'empaques': {'icon': Icons.redeem, 'color': Colors.brown[200]!},
    'limpieza': {
      'icon': Icons.cleaning_services,
      'color': Colors.blueGrey[200]!,
    },
    'equipos': {'icon': Icons.kitchen, 'color': Colors.deepOrange[200]!},
    'otros': {'icon': Icons.category, 'color': Colors.grey[600]!},
  };

  // 2. Constructor const (sin validaciones directas)
  const Insumo({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.categorias,
    required this.unidad,
    required this.precioUnitario,
    required this.proveedorId,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  });

  // 3. Factory constructor con validación
  factory Insumo.crear({
    String? id,
    required String codigo,
    required String nombre,
    required List<String> categorias,
    required String unidad,
    required double precioUnitario,
    required String proveedorId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    _validarCampos(
      codigo: codigo,
      nombre: nombre,
      unidad: unidad,
      precioUnitario: precioUnitario,
      proveedorId: proveedorId,
      categorias: categorias,
    );

    return Insumo(
      id: id,
      codigo: codigo,
      nombre: nombre,
      categorias: categorias,
      unidad: unidad,
      precioUnitario: precioUnitario,
      proveedorId: proveedorId,
      fechaCreacion: fechaCreacion ?? DateTime.now(),
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      activo: activo,
    );
  }

  static List<String> get nombresCategorias => categoriasInsumos.keys.toList();

  static IconData iconoCategoria(String nombre) {
    return categoriasInsumos[nombre]?['icon'] ?? Icons.category;
  }

  static Color colorCategoria(String nombre) {
    return categoriasInsumos[nombre]?['color'] ?? Colors.grey;
  }

  // 4. Factory constructor para Firestore
  factory Insumo.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return Insumo.crear(
        id: doc.id,
        codigo: data['codigo'] ?? '',
        nombre: data['nombre'] ?? '',
        categorias: List<String>.from(data['categorias'] ?? []),
        unidad: data['unidad'] ?? 'unidad',
        precioUnitario: (data['precioUnitario'] ?? 0).toDouble(),
        proveedorId: data['proveedorId'] ?? '',
        fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
        fechaActualizacion:
            (data['fechaActualizacion'] as Timestamp?)?.toDate(),
        activo: data['activo'] ?? true,
      );
    } catch (e) {
      throw Exception('Error convirtiendo documento a Insumo: $e');
    }
  }

  factory Insumo.fromMap(Map<String, dynamic> data) {
    return Insumo.crear(
      id: data['id'] ?? '',
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      categorias: data['categorias'] ?? [],
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
    required List<String> categorias,
  }) {
    final errors = <String>[];

    // Validación de campos básicos
    if (codigo.isEmpty) errors.add('El código es requerido');
    if (nombre.isEmpty) errors.add('El nombre es requerido');
    if (unidad.isEmpty) errors.add('La unidad es requerida');
    if (precioUnitario <= 0)
      {errors.add('El precio unitario debe ser mayor a 0');}
    //if (proveedorId.isEmpty) errors.add('El proveedor es requerido');

    // Validación de categorías
    if (categorias.isEmpty) {
      errors.add('Seleccione al menos una categoría');
    } else {
      for (final categoria in categorias) {
        if (!categoriasInsumos.containsKey(categoria)) {
          errors.add('Categoría "$categoria" no está permitida');
        }
      }
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
      'categorias': categorias,
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
    List<String>? categorias,
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
      categorias: categorias ?? this.categorias,
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
        other.categorias == categorias &&
        other.unidad == unidad &&
        other.precioUnitario == precioUnitario &&
        other.proveedorId == proveedorId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      codigo,
      nombre,
      categorias,
      unidad,
      precioUnitario,
      proveedorId,
    );
  }
}
