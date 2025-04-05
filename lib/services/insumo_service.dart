import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/insumo.dart';
// import '../models/proveedor.dart';
import './proveedor_service.dart';

class InsumoService {
  final FirebaseFirestore _db;
  final ProveedorService _proveedorService;
  final String _coleccion = 'insumos';

  // Inyección de dependencias para mejor testabilidad
  InsumoService({
    FirebaseFirestore? db,
    ProveedorService? proveedorService,
  }) : _db = db ?? FirebaseFirestore.instance,
       _proveedorService = proveedorService ?? ProveedorService();

  // Operaciones CRUD básicas
  Future<Insumo> crearInsumo(Insumo insumo) async {
    try {
      final docRef = await _db.collection(_coleccion).add(insumo.toFirestore());
      return insumo.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Insumo> obtenerInsumo(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Insumo no encontrado');
      
      final insumo = Insumo.fromFirestore(doc);
      // Opcional: Cargar datos del proveedor si es necesario
      // if (insumo.proveedorId.isNotEmpty) {
      //   final proveedor = await _proveedorService.obtenerProveedor(insumo.proveedorId);
      //   // Aquí podrías enriquecer el modelo de insumo si lo necesitas
      // }
      
      return insumo;
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Insumo>> obtenerInsumos(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _db.collection(_coleccion)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Insumo.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Insumo>> obtenerTodos({String? proveedorId}) async {
    try {
      Query query = _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .orderBy('nombre');
          
      if (proveedorId != null) {
        query = query.where('proveedorId', isEqualTo: proveedorId);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Insumo.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarInsumo(Insumo insumo) async {
    try {
      await _db.collection(_coleccion)
          .doc(insumo.id)
          .update(insumo.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> desactivarInsumo(String id) async {
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

  // Métodos específicos de negocio
  Future<Insumo> crearInsumoConValidacion({
    required String codigo,
    required String nombre,
    required String unidad,
    required double precioUnitario,
    required String proveedorId,
  }) async {
    // Validar que el proveedor exista
    try {
      await _proveedorService.obtenerProveedor(proveedorId);
    } catch (e) {
      throw Exception('El proveedor especificado no existe');
    }

    // Crear insumo con validación incorporada
    final insumo = Insumo.crear(
      codigo: codigo,
      nombre: nombre,
      unidad: unidad,
      precioUnitario: precioUnitario,
      proveedorId: proveedorId,
    );

    return insumo;
  }

  Future<List<Insumo>> buscarInsumosPorNombre(String query) async {
    try {
      final snapshot = await _db.collection(_coleccion)
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThanOrEqualTo: '$query\uf8ff')
          .where('activo', isEqualTo: true)
          .limit(10)
          .get();
          
      return snapshot.docs.map((doc) => Insumo.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<String> generarNuevoCodigo() async {
    try {
      final count = await _db.collection(_coleccion).count().get();
      return 'I-${(count.count! + 1).toString().padLeft(3, '0')}';
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  // Manejo centralizado de errores
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

  Future<void> desactivarInsumosPorProveedor(String proveedorId) async {
  final batch = _db.batch();
  final insumos = await _db.collection('insumos')
     .where('proveedorId', isEqualTo: proveedorId)
     .where('activo', isEqualTo: true)
     .get();

  for (final doc in insumos.docs) {
    batch.update(doc.reference, {
      'activo': false,
      'fechaActualizacion': FieldValue.serverTimestamp()
    });
  }

  await batch.commit();
}

Future<int?> contarInsumosActivosPorProveedor(String proveedorId) async {
  final snapshot = await _db.collection('insumos')
     .where('proveedorId', isEqualTo: proveedorId)
     .where('activo', isEqualTo: true)
     .count()
     .get();
     
  return snapshot.count;
}
}