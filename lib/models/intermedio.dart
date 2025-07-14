// intermedio.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Intermedio {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final List<String> categorias;
  final String unidad;
  final double cantidadEstandar;
  final double reduccionPorcentaje;
  final String receta;
  final int tiempoPreparacionMinutos;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  // 2. Categorías predefinidas con sus propiedades
  static Map<String, Map<String, dynamic>> categoriasDisponibles = {
    'salsa': {
      'icon': Icons.emoji_food_beverage,
      'color': Colors.red[200]!,
    },
    'guarnición': {
      'icon': Icons.rice_bowl,
      'color': Colors.green[200]!,
    },
    'base': {
      'icon': Icons.bakery_dining,
      'color': Colors.amber[200]!,
    },
    'relleno': {
      'icon': Icons.layers,
      'color': Colors.brown[200]!,
    },
    'aderezo': {
      'icon': Icons.opacity,
      'color': Colors.blue[200]!,
    },
    'decoración': {
      'icon': Icons.brush,
      'color': Colors.purple[200]!,
    },
    'proteína': {
      'icon': Icons.set_meal,
      'color': Colors.deepOrange[200]!,
    },
    'ensalada': {
      'icon': Icons.eco,
      'color': Colors.lightGreen[200]!,
    },
    'galletaría': {
      'icon': Icons.cookie,
      'color': Colors.brown[100]!,
    },
    'panadería': {
      'icon': Icons.bakery_dining,
      'color': Colors.amber[300]!,
    },
    'postre': {
      'icon': Icons.cake,
      'color': Colors.pink[200]!,
    },
    'guarnición fría': {
      'icon': Icons.ac_unit,
      'color': Colors.cyan[200]!,
    },
    'otros': {
      'icon': Icons.category,
      'color': Colors.grey[400]!,
    },
  };

  // 3. Constructor const
  const Intermedio({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.categorias,
    required this.unidad,
    required this.cantidadEstandar,
    required this.reduccionPorcentaje,
    required this.receta,
    required this.tiempoPreparacionMinutos,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  }) : assert(reduccionPorcentaje >= 0 && reduccionPorcentaje <= 100);

  // 4. Factory constructor con validación
  factory Intermedio.crear({
    String? id,
    required String codigo,
    required String nombre,
    required List<String> categorias,
    required String unidad,
    double? reduccionPorcentaje,
    double cantidadEstandar = 1.0,
    String receta = '',
    required int tiempoPreparacionMinutos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    // Validación de campos básicos
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    //if (!codigo.startsWith('PI-'))
      //errors.add('El código debe comenzar con "PI-"');
    if (nombre.isEmpty) errors.add('El nombre es requerido');
    if (unidad.isEmpty) errors.add('La unidad es requerida');
    if (cantidadEstandar <= 0)
      errors.add('La cantidad estándar debe ser mayor a 0');

    // Validación de categorías
    if (categorias.isEmpty) {
      errors.add('Seleccione al menos una categoría');
    } else {
      for (final categoria in categorias) {
        if (!categoriasDisponibles.containsKey(categoria)) {
          errors.add('Categoría "$categoria" no está permitida');
        }
      }
    }

    if (tiempoPreparacionMinutos <= 0) {
      errors.add('El tiempo de preparación debe ser positivo');
    }

    // Asignar reducción porcentual por defecto según categoría principal
    final reduccionDefault =
        categoriasDisponibles[categorias.first]?['reduccionDefault'] ?? 0.0;
    final reduccionFinal = reduccionPorcentaje ?? reduccionDefault;

    if (reduccionFinal < 0 || reduccionFinal > 100) {
      errors.add('La reducción porcentual debe estar entre 0 y 100');
    }

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    final ahora = DateTime.now();
    return Intermedio(
      id: id,
      codigo: codigo,
      nombre: nombre,
      categorias: categorias,
      unidad: unidad,
      cantidadEstandar: cantidadEstandar,
      reduccionPorcentaje: reduccionFinal,
      receta: receta,
      tiempoPreparacionMinutos: tiempoPreparacionMinutos,
      fechaCreacion: fechaCreacion ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 5. Factory constructor para Firestore
  factory Intermedio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Intermedio(
      id: doc.id,
      codigo: data['codigo'] as String,
      nombre: data['nombre'] as String,
      categorias: List<String>.from(data['categorias']),
      unidad: data['unidad'] as String,
      cantidadEstandar: (data['cantidadEstandar'] as num).toDouble(),
      reduccionPorcentaje: (data['reduccionPorcentaje'] as num).toDouble(),
      receta: data['receta'] as String,
      tiempoPreparacionMinutos: data['tiempoPreparacionMinutos'] as int,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp).toDate(),
      activo: data['activo'] as bool,
    );
  }

  // 6. Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'categorias': categorias,
      'unidad': unidad,
      'cantidadEstandar': cantidadEstandar,
      'reduccionPorcentaje': reduccionPorcentaje,
      'receta': receta,
      'tiempoPreparacionMinutos': tiempoPreparacionMinutos,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'activo': activo,
    };
  }

  // 7. Método copyWith
  Intermedio copyWith({
    String? id,
    String? codigo,
    String? nombre,
    List<String>? categorias,
    String? unidad,
    double? cantidadEstandar,
    double? reduccionPorcentaje,
    String? receta,
    int? tiempoPreparacionMinutos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Intermedio(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      categorias: categorias ?? this.categorias,
      unidad: unidad ?? this.unidad,
      cantidadEstandar: cantidadEstandar ?? this.cantidadEstandar,
      reduccionPorcentaje: reduccionPorcentaje ?? this.reduccionPorcentaje,
      receta: receta ?? this.receta,
      tiempoPreparacionMinutos:
          tiempoPreparacionMinutos ?? this.tiempoPreparacionMinutos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
    );
  }

  // 9. Helpers para UI
  List<IconData> get iconosCategorias {
    return categorias
        .map(
          (categoria) => categoriasDisponibles[categoria]!['icon'] as IconData,
        )
        .toList();
  }

  List<Color> get coloresCategorias {
    return categorias
        .map((categoria) => categoriasDisponibles[categoria]!['color'] as Color)
        .toList();
  }

  // 10. Método para obtener todas las categorías disponibles
  static List<String> get todasCategorias {
    return categoriasDisponibles.keys.toList();
  }

  // 11. Método para obtener propiedades de una categoría
  static Map<String, dynamic>? propiedadesCategoria(String categoria) {
    return categoriasDisponibles[categoria];
  }

  // 12. Override de toString para debugging
  @override
  String toString() {
    return 'Intermedio(id: $id, nombre: $nombre, categorías: ${categorias.join(', ')})';
  }

  // 13. Métodos para comparación
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Intermedio &&
            other.id == id &&
            other.codigo == codigo &&
            other.nombre == nombre &&
            listEquals(other.categorias, categorias) &&
            other.cantidadEstandar == cantidadEstandar &&
            other.reduccionPorcentaje == reduccionPorcentaje &&
            other.receta == receta &&
            other.tiempoPreparacionMinutos == tiempoPreparacionMinutos &&
            other.fechaCreacion == fechaCreacion &&
            other.fechaActualizacion == fechaActualizacion &&
            other.activo == activo;
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigo,
    nombre,
    Object.hashAll(categorias),
    cantidadEstandar,
    reduccionPorcentaje,
    receta,
    tiempoPreparacionMinutos,
    fechaCreacion,
    fechaActualizacion,
    activo,
  );
}
