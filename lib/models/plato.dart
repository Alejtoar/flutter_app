// plato.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio_requerido.dart';



class Plato {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final List<String> categorias; // Lista de códigos de categoría
  final int porcionesMinimas;
  final String receta;
  final List<IntermedioRequerido> intermedios;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;

  // 2. Categorías predefinidas con sus propiedades
  static Map<String, Map<String, dynamic>> categoriasDisponibles = {
    'plato_fuerte': {
      'icon': Icons.set_meal,
      'color': Colors.amber[600]!,
      'nombre': 'Plato fuerte',
      'descripcion': 'Plato principal de la comida',
    },
    'postre': {
      'icon': Icons.cake,
      'color': Colors.pink[300]!,
      'nombre': 'Postre',
      'descripcion': 'Dulces y postres',
    },
    'entrada': {
      'icon': Icons.restaurant,
      'color': Colors.green[400]!,
      'nombre': 'Entrada',
      'descripcion': 'Aperitivos y entradas',
    },
    'sopa': {
      'icon': Icons.soup_kitchen,
      'color': Colors.orange[300]!,
      'nombre': 'Sopa',
      'descripcion': 'Sopas y cremas',
    },
    'ensalada': {
      'icon': Icons.eco,
      'color': Colors.lightGreen[400]!,
      'nombre': 'Ensalada',
      'descripcion': 'Ensaladas y guarniciones',
    },
  };

  // 3. Constructor const
  const Plato({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.categorias,
    required this.porcionesMinimas,
    required this.receta,
    required this.intermedios,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
  });

  // 4. Factory constructor con validación
  factory Plato.crear({
    String? id,
    required String codigo,
    required String nombre,
    required List<String> categorias,
    required int porcionesMinimas,
    String receta = '',
    required List<IntermedioRequerido> intermedios,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool activo = true,
  }) {
    // Validación de campos básicos
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (!codigo.startsWith('PC-')) errors.add('El código debe comenzar con "PC-"');
    if (nombre.isEmpty) errors.add('El nombre es requerido');
    if (nombre.length < 3) errors.add('Nombre muy corto (mín. 3 caracteres)');
    if (porcionesMinimas <= 0) errors.add('Las porciones mínimas deben ser mayores a cero');

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

    // Validación de intermedios
    if (intermedios.isEmpty) {
      errors.add('Debe agregar al menos un intermedio');
    }

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    final ahora = DateTime.now();
    return Plato(
      id: id,
      codigo: codigo,
      nombre: nombre,
      categorias: categorias,
      porcionesMinimas: porcionesMinimas,
      receta: receta,
      intermedios: intermedios,
      fechaCreacion: fechaCreacion ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 5. Factory constructor para Firestore
  factory Plato.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final intermediosData = List<Map<String, dynamic>>.from(data['intermedios'] ?? []);
    final intermedios = intermediosData.map((i) => IntermedioRequerido.fromMap(i)).toList();

    return Plato.crear(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      categorias: List<String>.from(data['categorias'] ?? ['plato_fuerte']),
      porcionesMinimas: (data['porcionesMinimas'] ?? 1).toInt(),
      receta: data['receta'] ?? '',
      intermedios: intermedios,
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
      'porcionesMinimas': porcionesMinimas,
      'receta': receta,
      'intermedios': intermedios.map((i) => i.toFirestore()).toList(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'activo': activo,
    };
  }

  // 7. Método copyWith
  Plato copyWith({
    String? id,
    String? codigo,
    String? nombre,
    List<String>? categorias,
    int? porcionesMinimas,
    String? receta,
    List<IntermedioRequerido>? intermedios,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Plato(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      categorias: categorias ?? this.categorias,
      porcionesMinimas: porcionesMinimas ?? this.porcionesMinimas,
      receta: receta ?? this.receta,
      intermedios: intermedios ?? this.intermedios,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? DateTime.now(),
      activo: activo ?? this.activo,
    );
  }

  // 8. Métodos para UI
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

  String get nombresCategorias {
    return categorias
        .map((categoria) => categoriasDisponibles[categoria]!['nombre'] as String)
        .join(', ');
  }

  // 9. Métodos para cálculo
  double get costoTotal {
    return intermedios.fold(0, (total, intermedio) {
      // Aquí necesitarías obtener el costo del intermedio desde la base de datos
      // Esto es un placeholder - implementación real dependerá de tu estructura
      final costoIntermedio = 0.0; // Reemplazar con lógica real
      return total + (intermedio.cantidad * costoIntermedio);
    });
  }

  @override
  String toString() {
    return 'Plato(id: $id, nombre: $nombre, categorias: ${categorias.join(',')})';
  }
}