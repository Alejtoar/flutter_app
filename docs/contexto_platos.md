MODELOS USADOS
// plato.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Plato {
  // 1. Campos del modelo
  final String? id;
  final String codigo;
  final String nombre;
  final List<String> categorias; // Lista de códigos de categoría
  final int porcionesMinimas;
  final String receta;
  final String descripcion;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
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
    this.descripcion = '',
    this.fechaCreacion,
    this.fechaActualizacion,
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
    String descripcion = '',
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
      descripcion: descripcion,
      fechaCreacion: fechaCreacion ?? ahora,
      fechaActualizacion: fechaActualizacion ?? ahora,
      activo: activo,
    );
  }

  // 5. Factory constructor para Firestore
  factory Plato.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plato(
      id: doc.id,
      codigo: data['codigo'] as String,
      nombre: data['nombre'] as String,
      categorias: List<String>.from(data['categorias']),
      porcionesMinimas: data['porcionesMinimas'] as int,
      receta: data['receta'] as String,
      descripcion: data['descripcion'] as String,
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : null,
      fechaActualizacion: data['fechaActualizacion'] != null
          ? (data['fechaActualizacion'] as Timestamp).toDate()
          : null,
      activo: data['activo'] as bool,
    );
  }

  factory Plato.fromMap(Map<String, dynamic> data) {
    return Plato(
      id: data['id'] as String?,
      codigo: data['codigo'] as String,
      nombre: data['nombre'] as String,
      categorias: List<String>.from(data['categorias']),
      porcionesMinimas: data['porcionesMinimas'] as int,
      receta: data['receta'] as String,
      descripcion: data['descripcion'] as String,
      fechaCreacion: data['fechaCreacion'] != null
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : null,
      fechaActualizacion: data['fechaActualizacion'] != null
          ? (data['fechaActualizacion'] as Timestamp).toDate()
          : null,
      activo: data['activo'] as bool,
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
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion != null ? Timestamp.fromDate(fechaCreacion!) : null,
      'fechaActualizacion': fechaActualizacion != null ? Timestamp.fromDate(fechaActualizacion!) : null,
      'activo': activo,
    };
  }

  Plato copyWith({
    String? id,
    String? codigo,
    String? nombre,
    List<String>? categorias,
    int? porcionesMinimas,
    String? receta,
    String? descripcion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
  }) {
    return Plato(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      categorias: categorias ?? List.from(this.categorias),
      porcionesMinimas: porcionesMinimas ?? this.porcionesMinimas,
      receta: receta ?? this.receta,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
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

  String get categoria => categorias.isNotEmpty ? categorias.first : '';

  @override
  String toString() {
    return 'Plato(id: $id, nombre: $nombre, categorias: ${categorias.join(',')})';
  }
}

// insumo_requerido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Relación entre Plato e Insumo (cuando un plato usa insumos directos)
class InsumoRequerido {
  final String? id;
  final String platoId;
  final String insumoId;
  final double cantidad;
  const InsumoRequerido({
    this.id,
    required this.platoId,
    required this.insumoId,
    required this.cantidad,
  });

  factory InsumoRequerido.crear({
    String? id,
    required String platoId,
    required String insumoId,
    required double cantidad,
  }) {
    return InsumoRequerido(
      id: id,
      platoId: platoId,
      insumoId: insumoId,
      cantidad: cantidad,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'platoId': platoId,
      'insumoId': insumoId,
      'cantidad': cantidad,
    };
  }

  factory InsumoRequerido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoRequerido(
      id: doc.id,
      platoId: data['platoId'] as String,
      insumoId: data['insumoId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  factory InsumoRequerido.fromMap(Map<String, dynamic> data) {
    return InsumoRequerido(
      id: data['id'],
      platoId: data['platoId'] ?? '',
      insumoId: data['insumoId'] ?? '',
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  InsumoRequerido copyWith({
    String? id,
    String? platoId,
    String? insumoId,
    double? cantidad,
  }) {
    return InsumoRequerido(
      id: id ?? this.id,
      platoId: platoId ?? this.platoId,
      insumoId: insumoId ?? this.insumoId,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InsumoRequerido &&
            other.id == id &&
            other.platoId == platoId &&
            other.insumoId == insumoId &&
            other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, platoId, insumoId, cantidad);

  @override
  String toString() {
    return 'InsumoRequerido(id: $id, platoId: $platoId, insumoId: $insumoId, cantidad: $cantidad)';
  }
}

// intermedio_requerido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IntermedioRequerido {
  final String? id;
  final String platoId;
  final String intermedioId;
  final double cantidad;

  const IntermedioRequerido({
    this.id,
    required this.platoId,
    required this.intermedioId,
    required this.cantidad,
  });

  factory IntermedioRequerido.crear({
    String? id,
    required String platoId,
    required String intermedioId,
    required double cantidad,
  }) {
    return IntermedioRequerido(
      id: id,
      platoId: platoId,
      intermedioId: intermedioId,
      cantidad: cantidad,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'platoId': platoId,
      'intermedioId': intermedioId,
      'cantidad': cantidad,
    };
  }

  factory IntermedioRequerido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntermedioRequerido(
      id: doc.id,
      platoId: data['platoId'] as String,
      intermedioId: data['intermedioId'] as String,
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  factory IntermedioRequerido.fromMap(Map<String, dynamic> data) {
    return IntermedioRequerido(
      id: data['id'] ?? '',
      platoId: data['platoId'] ?? '',
      intermedioId: data['intermedioId'] ?? '',
      cantidad: (data['cantidad'] as num).toDouble(),
    );
  }

  IntermedioRequerido copyWith({
    String? id,
    String? platoId,
    String? intermedioId,
    double? cantidad,
  }) {
    return IntermedioRequerido(
      id: id ?? this.id,
      platoId: platoId ?? this.platoId,
      intermedioId: intermedioId ?? this.intermedioId,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IntermedioRequerido &&
        other.id == id &&
        other.platoId == platoId &&
        other.intermedioId == intermedioId &&
        other.cantidad == cantidad;
  }

  @override
  int get hashCode => Object.hash(id, platoId, intermedioId, cantidad);

  @override
  String toString() {
    return 'IntermedioRequerido(id: $id, platoId: $platoId, intermedioId: $intermedioId, cantidad: $cantidad)';
  }
}


REPOSITORIOS 

//plato_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/exceptions/plato_en_uso_exception.dart';

class PlatoFirestoreRepository implements PlatoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'platos';

  PlatoFirestoreRepository(this._db);

  @override
  Future<Plato> crear(Plato plato) async {
    try {
      // Validación adicional
      if (await existeCodigo(plato.codigo)) {
        throw Exception('El código ${plato.codigo} ya está en uso');
      }

      final docRef = await _db.collection(_coleccion).add(plato.toFirestore());
      return plato.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Plato> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Plato no encontrado');
      return Plato.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerTodos({String? categoria}) async {
    try {
      Query query = _db.collection(_coleccion);

      if (categoria != null) {
        query = query.where('categorias', arrayContains: categoria);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerVarios(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _db.collection(_coleccion)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Plato plato) async {
    try {
      await _db.collection(_coleccion)
          .doc(plato.id)
          .update(plato.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivar(String id) async {
    try {
      await _db.collection(_coleccion)
          .doc(id)
          .update({
            'activo': false,
            'fechaActualizacion': FieldValue.serverTimestamp()
          });
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    // 1. Verificar relaciones en eventos (platosId) y en intermedios_requeridos
    final usos = <String>[];
    // Evento (campo platosId contiene el id)
    final eventosSnap = await _db.collection('eventos').where('platosId', arrayContains: id).limit(1).get();
    if (eventosSnap.docs.isNotEmpty) usos.add('Eventos');
    // Intermedios requeridos (campo platoId)
    final intermediosRequeridosSnap = await _db.collection('intermedios_requeridos').where('platoId', isEqualTo: id).limit(1).get();
    if (intermediosRequeridosSnap.docs.isNotEmpty) usos.add('Intermedios');
    if (usos.isNotEmpty) {
      // Lanzar excepción personalizada
      throw PlatoEnUsoException(usos);
    }
    // Si no está en uso, borrar normalmente
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> buscarPorNombre(String query) async {
    try {
      final regex = RegExp(query, caseSensitive: false);
      
      final snapshot = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .get();
          
      final docs = snapshot.docs.where((doc) {
        final nombre = doc.data()['nombre'] as String;
        return regex.hasMatch(nombre);
      });
      
      return docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<String> generarNuevoCodigo() async {
  try {
    String codigo;
    bool codigoExiste;
    int intentos = 0;
    const maxIntentos = 5;

    do {
      final count = await _db.collection(_coleccion).count().get();
      codigo = 'PC-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
      codigoExiste = await existeCodigo(codigo);
      intentos++;
      
      if (intentos > maxIntentos) {
        throw Exception('No se pudo generar un código único después de $maxIntentos intentos');
      }
    } while (codigoExiste);

    return codigo;
  } on FirebaseException catch (e) {
    throw _handleFirestoreError(e);
  }
}

  @override
  Future<bool> existeCodigo(String codigo) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategoria(String categoria) async {
    try {
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContains: categoria)
          .where('activo', isEqualTo: true)
          .get();
          
      return querySnapshot.docs.map((doc) => Plato.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Plato>> obtenerPorCategorias(List<String> categorias) async {
    try {
      if (categorias.isEmpty) return [];
      
      // Firestore no soporta arrayContainsAll nativamente, usamos arrayContainsAny
      // y filtramos localmente para obtener solo los que tienen TODAS las categorías
      final querySnapshot = await _db.collection(_coleccion)
          .where('categorias', arrayContainsAny: categorias)
          .where('activo', isEqualTo: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => Plato.fromFirestore(doc))
          .where((plato) => categorias.every((c) => plato.categorias.contains(c)))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<DateTime?> obtenerFechaActualizacion(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return data['fechaActualizacion']?.toDate();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a los platos');
      case 'not-found':
        return Exception('Plato no encontrado');
      case 'invalid-argument':
        return Exception('Datos del plato no válidos');
      default:
        return Exception('Error al acceder a los platos: ${e.message}');
    }
  }
}

// insumo_requerido_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/repositories/insumo_requerido_repository.dart';

class InsumoRequeridoFirestoreRepository implements InsumoRequeridoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos_requeridos';

  InsumoRequeridoFirestoreRepository(this._db);

  @override
  Future<InsumoRequerido> crear(InsumoRequerido relacion) async {
    try {
      if (await existeRelacion(relacion.platoId, relacion.insumoId)) {
        throw Exception('Esta relación plato-insumo ya existe');
      }
      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<InsumoRequerido> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return InsumoRequerido.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(InsumoRequerido relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update(relacion.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoRequerido>> obtenerPorPlato(String platoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .get();
      return query.docs.map((doc) => InsumoRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<InsumoRequerido>> obtenerPorInsumo(String insumoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('insumoId', isEqualTo: insumoId)
          .get();
      return query.docs.map((doc) => InsumoRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> reemplazarInsumosDePlato(
    String platoId,
    Map<String, double> nuevosInsumos
  ) async {
    try {
      final batch = _db.batch();
      // 1. Eliminar relaciones existentes
      final relacionesExistentes = await obtenerPorPlato(platoId);
      for (final relacion in relacionesExistentes) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }
      // 2. Crear nuevas relaciones
      for (final entry in nuevosInsumos.entries) {
        final nuevaRelacion = InsumoRequerido(
          platoId: platoId,
          insumoId: entry.key,
          cantidad: entry.value,
        );
        final docRef = _db.collection(_coleccion).doc();
        batch.set(docRef, nuevaRelacion.toFirestore());
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeRelacion(String platoId, String insumoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .where('insumoId', isEqualTo: insumoId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorPlato(String platoId) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorPlato(platoId);
      for (final relacion in relaciones) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a estas relaciones');
      case 'not-found':
        return Exception('Relación no encontrada');
      case 'invalid-argument':
        return Exception('Datos de relación no válidos');
      default:
        return Exception('Error al acceder a las relaciones: ${e.message}');
    }
  }
}


// intermedio_requerido_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';

class IntermedioRequeridoFirestoreRepository implements IntermedioRequeridoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios_requeridos';

  IntermedioRequeridoFirestoreRepository(this._db);

  @override
  Future<IntermedioRequerido> crear(IntermedioRequerido relacion) async {
    try {
      // Verificar si la relación ya existe
      if (await existeRelacion(relacion.platoId, relacion.intermedioId)) {
        throw Exception('Esta relación plato-intermedio ya existe');
      }

      final docRef = await _db.collection(_coleccion).add(relacion.toFirestore());
      return relacion.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<IntermedioRequerido> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Relación no encontrada');
      return IntermedioRequerido.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(IntermedioRequerido relacion) async {
    try {
      await _db.collection(_coleccion)
          .doc(relacion.id)
          .update(relacion.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<IntermedioRequerido>> obtenerPorPlato(String platoId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .get();
          
      return query.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<IntermedioRequerido>> obtenerPorIntermedio(String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('intermedioId', isEqualTo: intermedioId)
          .get();
          
      return query.docs.map((doc) => IntermedioRequerido.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> reemplazarIntermediosDePlato(
    String platoId, 
    Map<String, double> nuevosIntermedios
  ) async {
    try {
      final batch = _db.batch();
      
      // 1. Eliminar relaciones existentes
      final relacionesExistentes = await obtenerPorPlato(platoId);
      for (final relacion in relacionesExistentes) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }
      
      // 2. Crear nuevas relaciones
      for (final entry in nuevosIntermedios.entries) {
        final nuevaRelacion = IntermedioRequerido(
          platoId: platoId,
          intermedioId: entry.key,
          cantidad: entry.value,
        );
        final docRef = _db.collection(_coleccion).doc();
        batch.set(docRef, nuevaRelacion.toFirestore());
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<bool> existeRelacion(String platoId, String intermedioId) async {
    try {
      final query = await _db.collection(_coleccion)
          .where('platoId', isEqualTo: platoId)
          .where('intermedioId', isEqualTo: intermedioId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarPorPlato(String platoId) async {
    try {
      final batch = _db.batch();
      final relaciones = await obtenerPorPlato(platoId);

      for (final relacion in relaciones) {
        batch.delete(_db.collection(_coleccion).doc(relacion.id));
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a estas relaciones');
      case 'not-found':
        return Exception('Relación no encontrada');
      case 'invalid-argument':
        return Exception('Datos de relación no válidos');
      default:
        return Exception('Error al acceder a las relaciones: ${e.message}');
    }
  }
}

UI y controlador

// plato_controller.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/repositories/plato_repository_impl.dart';
import 'package:golo_app/exceptions/plato_en_uso_exception.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository_impl.dart';
import 'package:golo_app/repositories/insumo_requerido_repository_impl.dart';

class PlatoController extends ChangeNotifier {
  Future<String> generarNuevoCodigo() async {
    return await _platoRepository.generarNuevoCodigo();
  }
  final PlatoFirestoreRepository _platoRepository;
  final IntermedioRequeridoFirestoreRepository _intermedioRequeridoRepository;
  final InsumoRequeridoFirestoreRepository _insumoRequeridoRepository;

  PlatoController(
    this._platoRepository,
    this._intermedioRequeridoRepository,
    this._insumoRequeridoRepository,
  );

  List<Plato> _platos = [];
  List<Plato> get platos => _platos;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // Relaciones actuales cargadas para edición
  List<IntermedioRequerido> _intermediosRequeridos = [];
  List<IntermedioRequerido> get intermediosRequeridos => _intermediosRequeridos;
  List<InsumoRequerido> _insumosRequeridos = [];
  List<InsumoRequerido> get insumosRequeridos => _insumosRequeridos;

  Future<void> cargarPlatos() async {
    _loading = true;
    notifyListeners();
    try {
      _platos = await _platoRepository.obtenerTodos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> eliminarPlato(String id) async {
    try {
      await _platoRepository.eliminar(id);
      await _intermedioRequeridoRepository.eliminarPorPlato(id);
      await _insumoRequeridoRepository.eliminarPorPlato(id);
      _platos.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
    } on PlatoEnUsoException catch (e) {
      _error = e.toString();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Crear un plato y sus relaciones (intermedios e insumos requeridos)
  Future<Plato?> crearPlatoConRelaciones(
    Plato plato,
    List<IntermedioRequerido> intermedios,
    List<InsumoRequerido> insumos,
  ) async {
    debugPrint('===> [crearPlatoConRelaciones] Iniciando creación de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}');
    debugPrint('===> [crearPlatoConRelaciones] Intermedios: ${intermedios.length}, Insumos: ${insumos.length}');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('===> [crearPlatoConRelaciones] Creando plato en repositorio...');
      final creado = await _platoRepository.crear(plato);
      debugPrint('===> [crearPlatoConRelaciones] Plato creado con id: ${creado.id}');
      final intermediosConId = intermedios.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      final insumosConId = insumos.map((ir) => ir.copyWith(platoId: creado.id!)).toList();
      debugPrint('===> [crearPlatoConRelaciones] Reemplazando intermedios requeridos...');
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        creado.id!,
        { for (var i in intermediosConId) i.intermedioId: i.cantidad },
      );
      debugPrint('===> [crearPlatoConRelaciones] Reemplazando insumos requeridos...');
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(
        creado.id!,
        { for (var i in insumosConId) i.insumoId: i.cantidad },
      );
      _platos.add(creado);
      _error = null;
      debugPrint('===> [crearPlatoConRelaciones] Plato y relaciones guardados correctamente.');
      notifyListeners();
      return creado;
    } catch (e, st) {
      debugPrint('===> [crearPlatoConRelaciones][ERROR] $e');
      debugPrint('===> [crearPlatoConRelaciones][STACK] $st');
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      debugPrint('===> [crearPlatoConRelaciones] Finalizado.');
      notifyListeners();
    }
  }

  /// Actualizar un plato y sus relaciones (intermedios e insumos requeridos)
  Future<bool> actualizarPlatoConRelaciones(
    Plato plato,
    List<IntermedioRequerido> nuevosIntermedios,
    List<InsumoRequerido> nuevosInsumos,
  ) async {
    debugPrint('===> [actualizarPlatoConRelaciones] Iniciando actualización de plato: \n  Plato: \n  id: ${plato.id}, nombre: ${plato.nombre}, categorias: ${plato.categorias}, receta: ${plato.receta}, descripcion: ${plato.descripcion}');
    debugPrint('===> [actualizarPlatoConRelaciones] Intermedios: ${nuevosIntermedios.length}, Insumos: ${nuevosInsumos.length}');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('===> [actualizarPlatoConRelaciones] Actualizando plato en repositorio...');
      await _platoRepository.actualizar(plato);
      debugPrint('===> [actualizarPlatoConRelaciones] Reemplazando intermedios requeridos...');
      await _intermedioRequeridoRepository.reemplazarIntermediosDePlato(
        plato.id!,
        { for (var i in nuevosIntermedios) i.intermedioId: i.cantidad },
      );
      debugPrint('===> [actualizarPlatoConRelaciones] Reemplazando insumos requeridos...');
      await _insumoRequeridoRepository.reemplazarInsumosDePlato(
        plato.id!,
        { for (var i in nuevosInsumos) i.insumoId: i.cantidad },
      );
      final idx = _platos.indexWhere((p) => p.id == plato.id);
      if (idx != -1) _platos[idx] = plato;
      _error = null;
      debugPrint('===> [actualizarPlatoConRelaciones] Plato y relaciones actualizados correctamente.');
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('===> [actualizarPlatoConRelaciones][ERROR] $e');
      debugPrint('===> [actualizarPlatoConRelaciones][STACK] $st');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      debugPrint('===> [actualizarPlatoConRelaciones] Finalizado.');
      notifyListeners();
    }
  }

  /// Cargar relaciones de un plato específico
  Future<void> cargarRelacionesPorPlato(String platoId) async {
    _loading = true;
    notifyListeners();
    try {
      _intermediosRequeridos = await _intermedioRequeridoRepository.obtenerPorPlato(platoId);
      _insumosRequeridos = await _insumoRequeridoRepository.obtenerPorPlato(platoId);
      _error = null;
    } catch (e) {
      _intermediosRequeridos = [];
      _insumosRequeridos = [];
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}

// platos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/plato_controller.dart';
import '../widgets/busqueda_bar.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/features/common/selector_categorias.dart';
import 'plato_edit_screen.dart';
import '../widgets/lista_platos.dart';
import 'plato_detalle_screen.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({Key? key}) : super(key: key);

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<PlatoController>(context, listen: false).cargarPlatos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlatoEditScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            BusquedaBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SelectorCategorias(
              categorias: Plato.categoriasDisponibles.keys.toList(),
              seleccionadas: _categoriasFiltro,
              onChanged: (cats) => setState(() => _categoriasFiltro = cats),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<PlatoController>(
                builder: (context, controller, _) {
                  if (controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final platos = controller.platos;
                  if (platos.isEmpty) {
                    return const Center(child: Text('No hay platos'));
                  }
                  // Filtrado por texto y categorías
                  final filtered = platos.where((p) {
                    final matchesText = _searchController.text.isEmpty ||
                      p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
                    final matchesCats = _categoriasFiltro.isEmpty ||
                      p.categorias.any((cat) => _categoriasFiltro.contains(cat));
                    return matchesText && matchesCats;
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No hay platos que coincidan con la búsqueda'));
                  }
                  // Usa ListaPlatos para mostrar los platos con opciones de ver, editar y eliminar
                  return ListaPlatos(
                    platos: filtered,
                    onVerDetalle: (plato) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlatoDetalleScreen(plato: plato),
                        ),
                      );
                    },
                    onEditar: (plato) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlatoEditScreen(plato: plato),
                        ),
                      );
                    },
                    onEliminar: (plato) async {
                      final controller = Provider.of<PlatoController>(context, listen: false);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar plato'),
                          content: Text('¿Seguro que deseas eliminar "${plato.nombre}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await controller.eliminarPlato(plato.id!);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// plato_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/features/catalogos/platos/widgets/lista_insumos_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/lista_intermedios_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_insumos_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_intermedios_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_insumo_requerido.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_intermedio_requerido.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/common/selector_categorias.dart';

class PlatoEditScreen extends StatefulWidget {
  final Plato? plato;
  const PlatoEditScreen({Key? key, this.plato}) : super(key: key);

  @override
  State<PlatoEditScreen> createState() => _PlatoEditScreenState();
}

class _PlatoEditScreenState extends State<PlatoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _codigoGenerado;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _recetaController;
  late TextEditingController _porcionesController;
  List<String> _categorias = [];
  List<InsumoRequerido> _insumos = [];
  List<IntermedioRequerido> _intermedios = [];

  Future<void> _editarInsumoRequerido(InsumoRequerido iu) async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) await insumoCtrl.cargarInsumos();
    final idx = insumoCtrl.insumos.indexWhere((x) => x.id == iu.insumoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insumo no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final insumo = insumoCtrl.insumos[idx];
    final editado = await showDialog<InsumoRequerido>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoRequerido(
            insumoRequerido: iu,
            insumo: insumo,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(iu.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _insumos.indexWhere((x) => x.insumoId == iu.insumoId);
        if (idxLocal != -1) _insumos[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioRequerido ir) async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty)
      await intermedioCtrl.cargarIntermedios();
    final idx = intermedioCtrl.intermedios.indexWhere(
      (x) => x.id == ir.intermedioId,
    );
    Intermedio intermedio;
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intermedio no encontrado en catálogo actual.'),
        ),
      );
      intermedio = Intermedio(
        id: ir.intermedioId,
        codigo: '',
        nombre: 'Intermedio desconocido',
        categorias: [],
        unidad: '',
        cantidadEstandar: 0,
        reduccionPorcentaje: 0,
        receta: '',
        tiempoPreparacionMinutos: 0,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        activo: true,
      );
    } else {
      intermedio = intermedioCtrl.intermedios[idx];
    }
    final editado = await showDialog<IntermedioRequerido>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioRequerido(
            intermedioRequerido: ir,
            intermedio: intermedio,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(ir.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _intermedios.indexWhere(
          (x) => x.intermedioId == ir.intermedioId,
        );
        if (idxLocal != -1) _intermedios[idxLocal] = editado;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.plato;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _recetaController = TextEditingController(text: p?.receta ?? '');
    _porcionesController = TextEditingController(
      text: (p?.porcionesMinimas ?? 1).toString(),
    );
    _categorias = List.from(p?.categorias ?? []);

    // Asegura la carga de catálogos globales de insumos e intermedios
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      final intermedioCtrl = Provider.of<IntermedioController>(
        context,
        listen: false,
      );
      if (insumoCtrl.insumos.isEmpty) {
        await insumoCtrl.cargarInsumos();
      }
      if (intermedioCtrl.intermedios.isEmpty) {
        await intermedioCtrl.cargarIntermedios();
      }
    });

    if (p == null) {
      // Generar código automáticamente al crear
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctrl = Provider.of<PlatoController>(context, listen: false);
        final codigo = await ctrl.generarNuevoCodigo();
        if (!mounted) return;
        setState(() => _codigoGenerado = codigo);
      });
    } else {
      _codigoGenerado = p.codigo;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final platoCtrl = Provider.of<PlatoController>(context, listen: false);
        await platoCtrl.cargarRelacionesPorPlato(p.id!);
        setState(() {
          _insumos = List.from(platoCtrl.insumosRequeridos);
          _intermedios = List.from(platoCtrl.intermediosRequeridos);
        });
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _recetaController.dispose();
    _porcionesController.dispose();
    super.dispose();
  }

  void _abrirModalInsumos() async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      await insumoCtrl.cargarInsumos();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosRequeridos(
            insumosIniciales: _insumos,
            onGuardar: (nuevos) {
              setState(() => _insumos = List.from(nuevos));
            },
          ),
    );
  }

  void _abrirModalIntermedios() async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty) {
      await intermedioCtrl.cargarIntermedios();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarIntermediosRequeridos(
            intermediosIniciales: _intermedios,
            onGuardar: (nuevos) {
              setState(() => _intermedios = List.from(nuevos));
            },
          ),
    );
  }

  void _guardar() async {
    debugPrint('===> [_guardar] Iniciando guardado de plato');
    if (!_formKey.currentState!.validate()) {
      debugPrint('===> [_guardar] Formulario inválido');
      return;
    }
    if (_categorias.isEmpty) {
      debugPrint('===> [_guardar] No hay categorías seleccionadas');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos una categoría'),
        ),
      );
      return;
    }
    if (!mounted) {
      debugPrint('===> [_guardar] Widget no montado, cancelando guardado');
      return;
    }
    debugPrint('===> [_guardar] Leyendo valores de controladores');
    final plato = Plato(
      id: widget.plato?.id,
      codigo: _codigoGenerado ?? '',
      nombre: _nombreController.text.trim(),
      categorias: _categorias,
      porcionesMinimas: int.tryParse(_porcionesController.text) ?? 1,
      receta: _recetaController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      fechaCreacion: widget.plato?.fechaCreacion,
      fechaActualizacion: DateTime.now(),
      activo: widget.plato?.activo ?? true,
    );
    debugPrint(
      '===> [_guardar] Plato construido: id=${plato.id}, nombre=${plato.nombre}, categorias=${plato.categorias}, receta=${plato.receta}, descripcion=${plato.descripcion}',
    );
    final controller = Provider.of<PlatoController>(context, listen: false);
    bool exito;
    if (widget.plato == null) {
      debugPrint('===> [_guardar] Creando plato nuevo');
      final creado = await controller.crearPlatoConRelaciones(
        plato,
        _intermedios,
        _insumos,
      );
      exito = creado != null;
    } else {
      debugPrint('===> [_guardar] Actualizando plato existente');
      exito = await controller.actualizarPlatoConRelaciones(
        plato,
        _intermedios,
        _insumos,
      );
    }
    if (!mounted) {
      debugPrint(
        '===> [_guardar] Widget desmontado después de guardar, no navego ni muestro SnackBar',
      );
      return;
    }
    if (exito) {
      debugPrint('===> [_guardar] Guardado exitoso, navegando hacia atrás');
      Navigator.of(context).pop();
    } else {
      debugPrint('===> [_guardar] Error al guardar: ${controller.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al guardar el plato'),
        ),
      );
    }
    debugPrint('===> [_guardar] Fin de _guardar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plato == null ? 'Crear Plato' : 'Editar Plato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_codigoGenerado != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Código'),
                    child: Text(
                      _codigoGenerado!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _porcionesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Porciones estándar',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final n = int.tryParse(v);
                  if (n == null || n < 1)
                    return 'Debe ser un número entero mayor a 0';
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectorCategorias(
                  categorias: Plato.categoriasDisponibles.keys.toList(),
                  seleccionadas: _categorias,
                  onChanged: (cats) => setState(() => _categorias = cats),
                ),
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _recetaController,
                decoration: const InputDecoration(
                  labelText: 'Receta (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Insumos requeridos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _abrirModalInsumos,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar insumos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListaInsumosRequeridos(
                  insumos: _insumos,
                  onEditar: _editarInsumoRequerido,
                  onEliminar: (iu) {
                    setState(() {
                      _insumos.removeWhere((x) => x.insumoId == iu.insumoId);
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Intermedios requeridos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _abrirModalIntermedios,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar intermedios'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListaIntermediosRequeridos(
                  intermedios: _intermedios,
                  onEditar: _editarIntermedioRequerido,
                  onEliminar: (ir) {
                    setState(() {
                      _intermedios.removeWhere(
                        (x) => x.intermedioId == ir.intermedioId,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardar,
                child: Text(widget.plato == null ? 'Crear' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

