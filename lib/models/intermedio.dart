import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo_utilizado.dart';

class Intermedio {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final List<String> categorias;
  final double reduccionPorcentaje;
  final String receta;
  final String instrucciones;
  final List<InsumoUtilizado> insumos;
  final int tiempoPreparacionMinutos;
  final double rendimientoFinal; // en gramos o mililitros
  final String versionReceta;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  // 2. Categorías predefinidas con sus propiedades
  static Map<String, Map<String, dynamic>> categoriasDisponibles = {
    'salsa': {
      'icon': Icons.emoji_food_beverage,
      'color': Colors.red[200]!,
      'reduccionDefault': 15.0,
    },
    'guarnición': {
      'icon': Icons.rice_bowl,
      'color': Colors.green[200]!,
      'reduccionDefault': 10.0,
    },
    'base': {
      'icon': Icons.bakery_dining,
      'color': Colors.amber[200]!,
      'reduccionDefault': 5.0,
    },
    'relleno': {
      'icon': Icons.layers,
      'color': Colors.brown[200]!,
      'reduccionDefault': 20.0,
    },
    'aderezo': {
      'icon': Icons.opacity,
      'color': Colors.blue[200]!,
      'reduccionDefault': 25.0,
    },
    'decoración': {
      'icon': Icons.brush,
      'color': Colors.purple[200]!,
      'reduccionDefault': 30.0,
    },
  };

  // 3. Constructor const
  const Intermedio({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.categorias,
    required this.reduccionPorcentaje,
    required this.receta,
    required this.instrucciones,
    required this.insumos,
    required this.tiempoPreparacionMinutos,
    required this.rendimientoFinal,
    required this.versionReceta,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  });

  // 4. Factory constructor con validación
  factory Intermedio.crear({
    String? id,
    required String codigo,
    required String nombre,
    required List<String> categorias,
    double? reduccionPorcentaje,
    String receta = '',
    String instrucciones = '',
    required List<InsumoUtilizado> insumos,
    required int tiempoPreparacionMinutos,
    required double rendimientoFinal,
    String versionReceta = '1.0',
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    // Validación de campos básicos
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (!codigo.startsWith('PI-')) errors.add('El código debe comenzar con "PI-"');
    if (nombre.isEmpty) errors.add('El nombre es requerido');
    if (nombre.length < 3) errors.add('Nombre muy corto (mín. 3 caracteres)');

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

    // Validación de insumos
    if (insumos.isEmpty) {
      errors.add('Debe agregar al menos un insumo');
    }

    if (tiempoPreparacionMinutos <= 0) {
      errors.add('El tiempo de preparación debe ser positivo');
    }

    if (rendimientoFinal <= 0) {
      errors.add('El rendimiento final debe ser positivo');
    }

    // Asignar reducción porcentual por defecto según categoría principal
    final reduccionDefault = categoriasDisponibles[categorias.first]?['reduccionDefault'] ?? 0.0;
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
      reduccionPorcentaje: reduccionFinal,
      receta: receta,
      instrucciones: instrucciones,
      insumos: insumos,
      tiempoPreparacionMinutos: tiempoPreparacionMinutos,
      rendimientoFinal: rendimientoFinal,
      versionReceta: versionReceta,
      fechaCreacion: fechaCreacion ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 5. Factory constructor para Firestore
  factory Intermedio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final insumosData = List<Map<String, dynamic>>.from(data['insumos'] ?? []);
    final insumos = insumosData.map((i) => InsumoUtilizado.fromFirestore(i)).toList();

    return Intermedio.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      categorias: List<String>.from(data['categorias'] ?? []),
      reduccionPorcentaje: (data['reduccionPorcentaje'] ?? 0).toDouble(),
      receta: data['receta'] ?? '',
      instrucciones: data['instrucciones'] ?? '',
      insumos: insumos,
      tiempoPreparacionMinutos: data['tiempoPreparacionMinutos'] ?? 0,
      rendimientoFinal: (data['rendimientoFinal'] ?? 0).toDouble(),
      versionReceta: data['versionReceta'] ?? '1.0',
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate(),
      activo: data['activo'] ?? true,
    );
  }

  // 6. Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'categorias': categorias,
      'reduccionPorcentaje': reduccionPorcentaje,
      'receta': receta,
      'instrucciones': instrucciones,
      'insumos': insumos.map((i) => i.toFirestore()).toList(),
      'tiempoPreparacionMinutos': tiempoPreparacionMinutos,
      'rendimientoFinal': rendimientoFinal,
      'versionReceta': versionReceta,
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
    double? reduccionPorcentaje,
    String? receta,
    String? instrucciones,
    List<InsumoUtilizado>? insumos,
    int? tiempoPreparacionMinutos,
    double? rendimientoFinal,
    String? versionReceta,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Intermedio(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      categorias: categorias ?? this.categorias,
      reduccionPorcentaje: reduccionPorcentaje ?? this.reduccionPorcentaje,
      receta: receta ?? this.receta,
      instrucciones: instrucciones ?? this.instrucciones,
      insumos: insumos ?? this.insumos,
      tiempoPreparacionMinutos: tiempoPreparacionMinutos ?? this.tiempoPreparacionMinutos,
      rendimientoFinal: rendimientoFinal ?? this.rendimientoFinal,
      versionReceta: versionReceta ?? this.versionReceta,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      activo: activo ?? this.activo,
    );
  }

  // 8. Métodos para cálculo de costos
  double get costoTotalInsumos {
    return insumos.fold(0, (total, insumo) => total + (insumo.cantidad * insumo.precioUnitario));
  }

  double get costoConReduccion {
    return costoTotalInsumos * (1 - (reduccionPorcentaje / 100));
  }

  // 9. Helpers para UI
  List<IconData> get iconosCategorias {
    return categorias
        .map((categoria) => categoriasDisponibles[categoria]!['icon'] as IconData)
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
    if (identical(this, other)) return true;
    return other is Intermedio &&
        other.id == id &&
        other.codigo == codigo &&
        other.nombre == nombre &&
        listEquals(other.categorias, categorias);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      codigo,
      nombre,
      Object.hashAll(categorias),
    );
  }
}