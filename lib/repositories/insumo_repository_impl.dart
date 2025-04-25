import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
import '../models/insumo.dart';
import 'package:golo_app/exceptions/insumo_en_uso_exception.dart';

class InsumoFirestoreRepository implements InsumoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'insumos';

  InsumoFirestoreRepository(this._db);

  @override
  Future<Insumo> crear(Insumo insumo) async {
    _validarCategorias(insumo.categorias);
    try {
      // Validar unicidad del código
      if (await existeCodigo(insumo.codigo)) {
        throw Exception('El código ${insumo.codigo} ya está registrado');
      }

      final docRef = await _db.collection(_coleccion).add(insumo.toFirestore());
      return insumo.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<Insumo> obtener(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Insumo no encontrado');
      return Insumo.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> obtenerTodos() async {
    try {
      Query query = _db.collection(_coleccion);
      // .where('activo', isEqualTo: true)
      // .orderBy('nombre');

      final querySnapshot = await query.get();
      debugPrint('Documentos obtenidos: ${querySnapshot.docs.length}');
      return querySnapshot.docs
          .map((doc) => Insumo.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> obtenerVarios(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      final query =
          await _db
              .collection(_coleccion)
              .where(FieldPath.documentId, whereIn: ids)
              .where('activo', isEqualTo: true)
              .get();

      return query.docs.map((doc) => Insumo.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> actualizar(Insumo insumo) async {
    _validarCategorias(insumo.categorias);
    try {
      await _db
          .collection(_coleccion)
          .doc(insumo.id)
          .update(insumo.toFirestore());
      _codigoCache[insumo.codigo] = insumo; // Actualiza caché
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivar(String id) async {
    try {
      // 1. Primero obtenemos el insumo para saber su código
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Insumo no encontrado');

      final insumo = Insumo.fromFirestore(doc);

      // 2. Actualizamos en Firestore
      await _db.collection(_coleccion).doc(id).update({
        'activo': false,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // 3. Eliminamos del caché usando el código
      _codigoCache.remove(insumo.codigo);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> buscarPorNombre(String query) async {
    try {
      // Crear una expresión regular con la opción 'i' para insensibilidad a mayúsculas
      final regex = RegExp(query, caseSensitive: false);

      final snapshot =
          await _db
              .collection(_coleccion)
              .where('activo', isEqualTo: true)
              .get();

      // Filtrar los resultados usando la expresión regular
      final docs = snapshot.docs.where((doc) {
        final nombre = doc.data()['nombre'] as String;
        return regex.hasMatch(nombre);
      });

      return docs.map((doc) => Insumo.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  final _codigoCache = <String, Insumo>{}; // Mapa en memoria
  @override
  Future<Insumo> obtenerPorCodigo(String codigo) async {
    try {
      if (_codigoCache.containsKey(codigo)) {
        return _codigoCache[codigo]!;
      }
      final query =
          await _db
              .collection(_coleccion)
              .where('codigo', isEqualTo: codigo)
              .where('activo', isEqualTo: true)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        throw Exception('No se encontró ningún insumo con el código $codigo');
      }
      final insumo = Insumo.fromFirestore(query.docs.first);
      _codigoCache[codigo] = insumo;
      return insumo;
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
        codigo =
            'I-${(count.count! + 1 + intentos).toString().padLeft(3, '0')}';
        codigoExiste = await existeCodigo(codigo);
        intentos++;

        if (intentos > maxIntentos) {
          throw Exception(
            'No se pudo generar un código único después de $maxIntentos intentos',
          );
        }
      } while (codigoExiste);

      return codigo;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> desactivarPorProveedor(String proveedorId) async {
    try {
      final batch = _db.batch();
      final insumos =
          await _db
              .collection(_coleccion)
              .where('proveedorId', isEqualTo: proveedorId)
              .where('activo', isEqualTo: true)
              .get();

      for (final doc in insumos.docs) {
        batch.update(doc.reference, {
          'activo': false,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<int> contarActivosPorProveedor(String proveedorId) async {
    try {
      final snapshot =
          await _db
              .collection(_coleccion)
              .where('proveedorId', isEqualTo: proveedorId)
              .where('activo', isEqualTo: true)
              .count()
              .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<void> eliminarInsumo(String id) async {
    // 1. Verificar relaciones en insumo_requerido, insumo_utilizado, insumo_evento
    final usos = <String>[];
    // Insumo requerido (en platos)
    final insumoRequeridoSnap = await _db.collection('insumos_requeridos').where('insumoId', isEqualTo: id).limit(1).get();
    if (insumoRequeridoSnap.docs.isNotEmpty) usos.add('Platos');
    // Insumo utilizado (en intermedios)
    final insumoUtilizadoSnap = await _db.collection('insumos_utilizados').where('insumoId', isEqualTo: id).limit(1).get();
    if (insumoUtilizadoSnap.docs.isNotEmpty) usos.add('Intermedios');
    // Insumo evento (en eventos)
    final insumoEventoSnap = await _db.collection('insumos_eventos').where('insumoId', isEqualTo: id).limit(1).get();
    if (insumoEventoSnap.docs.isNotEmpty) usos.add('Eventos');
    if (usos.isNotEmpty) {
      // Lanzar excepción personalizada
      throw InsumoEnUsoException(usos);
    }
    // Si no está en uso, borrar normalmente
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> filtrarInsumosPorCategoria(String categoria) async {
    try {
      final querySnapshot =
          await _db
              .collection(_coleccion)
              .where('categorias', arrayContains: categoria)
              .where('activo', isEqualTo: true)
              .get();
      return querySnapshot.docs
          .map((doc) => Insumo.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> filtrarInsumosPorCategorias(
    List<String> categorias,
  ) async {
    try {
      final querySnapshot =
          await _db
              .collection(_coleccion)
              .where('categorias', arrayContainsAny: categorias)
              .where('activo', isEqualTo: true)
              .get();
      return querySnapshot.docs
          .map((doc) => Insumo.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> filtrarInsumosPorProveedor(String proveedorId) async {
    try {
      final querySnapshot =
          await _db
              .collection(_coleccion)
              .where('proveedorId', isEqualTo: proveedorId)
              .where('activo', isEqualTo: true)
              .get();
      return querySnapshot.docs
          .map((doc) => Insumo.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Insumo>> obtenerInsumos() async {
    try {
      final querySnapshot =
          await _db
              .collection(_coleccion)
              .where('activo', isEqualTo: true)
              .orderBy('nombre')
              .get();
      return querySnapshot.docs
          .map((doc) => Insumo.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a los insumos');
      case 'not-found':
        return Exception('Insumo no encontrado');
      case 'invalid-argument':
        return Exception('Datos del insumo no válidos');
      default:
        return Exception('Error al acceder a los insumos: ${e.message}');
    }
  }

  @override
  Future<bool> existeCodigo(String codigo) async {
    try {
      final query =
          await _db
              .collection(_coleccion)
              .where('codigo', isEqualTo: codigo)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  void _validarCategorias(List<String> categorias) {
    for (final cat in categorias) {
      if (!Insumo.categoriasInsumos.containsKey(cat)) {
        throw Exception('Categoría "$cat" no está permitida');
      }
    }
  }
}
