import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class Proveedor {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final String telefono;
  final String correo;
  final List<String> tiposInsumos;
  final DateTime fechaRegistro;
  final DateTime fechaActualizacion;
  final bool activo;

  // 2. Categorías predefinidas con sus iconos y colores
  static  Map<String, Map<String, dynamic>> categoriasInsumos = {
    'lácteos': {
      'icon': Icons.local_drink,
      'color': Colors.blueAccent,
    },
    'cárnicos': {
      'icon': Icons.set_meal,
      'color': Colors.redAccent,
    },
    'vegetales': {
      'icon': Icons.eco,
      'color': Colors.greenAccent,
    },
    'frutas': {
      'icon': Icons.apple,
      'color': Colors.red[200]!,
    },
    'especias': {
      'icon': Icons.spa,
      'color': Colors.orangeAccent,
    },
    'granos': {
      'icon': Icons.grain,
      'color': Colors.brown[300]!,
    },
    'panadería': {
      'icon': Icons.bakery_dining,
      'color': Colors.amber[200]!,
    },
    'repostería': {
      'icon': Icons.cake,
      'color': Colors.pinkAccent,
    },
    'bebidas': {
      'icon': Icons.local_bar,
      'color': Colors.purpleAccent,
    },
    'empaques': {
      'icon': Icons.redeem,
      'color': Colors.brown[200]!,
    },
    'limpieza': {
      'icon': Icons.cleaning_services,
      'color': Colors.blueGrey[200]!,
    },
    'equipos': {
      'icon': Icons.kitchen,
      'color': Colors.deepOrange[200]!,
    },
    'otros': {
      'icon': Icons.category,
      'color': Colors.grey[600]!,
    },
  };

  // 3. Constructor const
  const Proveedor({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.tiposInsumos,
    required this.fechaRegistro,
    required this.fechaActualizacion,
    this.activo = true,
  });

  // 4. Factory constructor con validación
  factory Proveedor.crear({
    String? id,
    required String codigo,
    required String nombre,
    required String telefono,
    required String correo,
    List<String>? tiposInsumos,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    // Validación de campos básicos
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (!codigo.startsWith('P-')) errors.add('El código debe comenzar con "P-"');
    if (nombre.isEmpty) errors.add('El nombre es requerido');
    if (telefono.isEmpty) errors.add('Teléfono es requerido');
    if (correo.isEmpty) errors.add('Correo electrónico es requerido');

    // Validación de teléfono (formato internacional simplificado)
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(telefono)) {
      errors.add('Teléfono no válido. Use formato internacional');
    }

    // Validación de correo electrónico
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(correo)) {
      errors.add('Correo electrónico no válido');
    }

    // Validación de categorías
    if (tiposInsumos == null || tiposInsumos.isEmpty) {
      errors.add('Seleccione al menos una categoría de insumo');
    } else {
      for (final tipo in tiposInsumos) {
        if (!categoriasInsumos.containsKey(tipo)) {
          errors.add('Categoría "$tipo" no está permitida');
        }
      }
    }

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    final ahora = DateTime.now();
    return Proveedor(
      id: id,
      codigo: codigo,
      nombre: nombre,
      telefono: telefono,
      correo: correo,
      tiposInsumos: tiposInsumos ?? [],
      fechaRegistro: fechaRegistro ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 5. Factory constructor para Firestore
  factory Proveedor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Proveedor.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      tiposInsumos: List<String>.from(data['tiposInsumos'] ?? []),
      fechaRegistro: (data['fechaRegistro'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate(),
      activo: data['activo'] ?? true,
    );
  }

  // 6. Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'telefono': telefono,
      'correo': correo,
      'tiposInsumos': tiposInsumos,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'activo': activo,
    };
  }

  // 7. Método copyWith
  Proveedor copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? telefono,
    String? correo,
    List<String>? tiposInsumos,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Proveedor(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      tiposInsumos: tiposInsumos ?? this.tiposInsumos,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
    );
  }

  // 8. Helpers para UI
  List<IconData> get iconosCategorias {
    return tiposInsumos
        .map((tipo) => categoriasInsumos[tipo]!['icon'] as IconData)
        .toList();
  }

  List<Color> get coloresCategorias {
    return tiposInsumos
        .map((tipo) => categoriasInsumos[tipo]!['color'] as Color)
        .toList();
  }

  // 9. Método para obtener todas las categorías disponibles
  static List<String> get categoriasDisponibles {
    return categoriasInsumos.keys.toList();
  }

  // 10. Método para obtener icono y color de una categoría específica
  static Map<String, dynamic>? getIconoYColor(String categoria) {
    return categoriasInsumos[categoria];
  }

  // 11. Override de toString para debugging
  @override
  String toString() {
    return 'Proveedor(id: $id, nombre: $nombre, categorías: ${tiposInsumos.join(', ')})';
  }

  // 12. Métodos para comparación
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proveedor &&
        other.id == id &&
        other.codigo == codigo &&
        other.nombre == nombre &&
        other.telefono == telefono &&
        other.correo == correo &&
        listEquals(other.tiposInsumos, tiposInsumos);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      codigo,
      nombre,
      telefono,
      correo,
      Object.hashAll(tiposInsumos),
    );
  }
}