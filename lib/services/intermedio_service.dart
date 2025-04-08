import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intermedio.dart';

class IntermedioService {
  final FirebaseFirestore _db;
  final String _coleccion = 'intermedios';

  IntermedioService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Operaciones CRUD mejoradas
  Future<Intermedio> crearIntermedio(Intermedio intermedio) async {
    try {
      final docRef = await _db.collection(_coleccion).add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('No tienes permiso para crear intermedios');
        } else if (e.code == 'resource-exhausted') {
          throw Exception('Se ha alcanzado el límite de intermedios');
        }
      }
      throw Exception('Error al crear intermedio: ${e.toString()}');
    }
  }

  Future<Intermedio> obtenerIntermedio(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Intermedio no encontrado');
      return Intermedio.fromFirestore(doc);
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('No tienes permiso para ver intermedios');
        }
      }
      throw Exception('Error al obtener intermedio: ${e.toString()}');
    }
  }

  Future<void> actualizarIntermedio(Intermedio intermedio) async {
    try {
      if (intermedio.id == null) throw Exception('ID de intermedio no válido');
      await _db.collection(_coleccion).doc(intermedio.id).update(intermedio.toFirestore());
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('No tienes permiso para actualizar intermedios');
        }
      }
      throw Exception('Error al actualizar intermedio: ${e.toString()}');
    }
  }

  Future<void> eliminarIntermedio(String id) async {
    try {
      await _db.collection(_coleccion).doc(id).delete();
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('No tienes permiso para eliminar intermedios');
        }
      }
      throw Exception('Error al eliminar intermedio: ${e.toString()}');
    }
  }

  Stream<List<Intermedio>> obtenerTodos() {
    return _db
        .collection(_coleccion)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Intermedio.fromFirestore(doc))
            .toList());
  }

  // Métodos específicos de negocio
  Future<Intermedio> crearIntermedioConValidacion({
    required String codigo,
    required String nombre,
    required List<String> categorias,
    required double reduccionPorcentaje,
    required String receta,
    required int tiempoPreparacionMinutos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    required bool activo,
  }) async {
    try {
      // Validar campos
      final errores = <String>[];

      if (codigo.isEmpty) {
        errores.add('El código es requerido');
      }

      if (nombre.isEmpty) {
        errores.add('El nombre es requerido');
      }

      if (categorias.isEmpty) {
        errores.add('Debe seleccionar al menos una categoría');
      }

      if (reduccionPorcentaje < 0 || reduccionPorcentaje > 100) {
        errores.add('La reducción debe estar entre 0 y 100');
      }

      if (tiempoPreparacionMinutos <= 0) {
        errores.add('El tiempo de preparación debe ser positivo');
      }

      if (errores.isNotEmpty) {
        throw Exception(errores.join('\n'));
      }

      // Crear intermedio
      final intermedio = Intermedio(
        codigo: codigo,
        nombre: nombre,
        categorias: categorias,
        reduccionPorcentaje: reduccionPorcentaje,
        receta: receta,
        tiempoPreparacionMinutos: tiempoPreparacionMinutos,
        fechaCreacion: fechaCreacion ?? DateTime.now(),
        fechaActualizacion: fechaActualizacion ?? DateTime.now(),
        activo: activo,
      );

      // Guardar en Firestore
      final docRef = await _db.collection('intermedios').add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('No tienes permiso para crear intermedios');
        }
      }
      throw Exception('Error al crear intermedio: ${e.toString()}');
    }
  }
}