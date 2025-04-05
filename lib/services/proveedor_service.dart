import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:golo_app/models/insumo.dart';
import '../models/proveedor.dart';
import './insumo_service.dart';

class ProveedorService {
  final FirebaseFirestore _db;
  final InsumoService _insumoService;
  final String _coleccion = 'proveedores';

  // Inyección de dependencias para mejor testabilidad
  ProveedorService({
    FirebaseFirestore? db,
    InsumoService? insumoService,
  }) : _db = db ?? FirebaseFirestore.instance,
       _insumoService = insumoService ?? InsumoService();

  // Operaciones CRUD básicas
  Future<Proveedor> crearProveedor(Proveedor proveedor) async {
    try {
      final docRef = await _db.collection(_coleccion).add(proveedor.toFirestore());
      return proveedor.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Proveedor> obtenerProveedor(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Proveedor no encontrado');
      return Proveedor.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Proveedor>> obtenerProveedores(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      
      final query = await _db.collection(_coleccion)
          .where(FieldPath.documentId, whereIn: ids)
          .where('activo', isEqualTo: true)
          .get();
          
      return query.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Proveedor>> obtenerTodos({List<String>? tiposInsumos}) async {
    try {
      Query query = _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .orderBy('nombre');
          
      if (tiposInsumos != null && tiposInsumos.isNotEmpty) {
        query = query.where('tiposInsumos', arrayContainsAny: tiposInsumos);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarProveedor(Proveedor proveedor) async {
    try {
      await _db.collection(_coleccion)
          .doc(proveedor.id)
          .update(proveedor.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> desactivarProveedor(String id) async {
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
  Future<Proveedor> crearProveedorConValidacion({
    required String codigo,
    required String nombre,
    required String telefono,
    required String correo,
    required List<String> tiposInsumos,
  }) async {
    // Crear proveedor con validación incorporada
    final proveedor = Proveedor.crear(
      codigo: codigo,
      nombre: nombre,
      telefono: telefono,
      correo: correo,
      tiposInsumos: tiposInsumos,
    );

    return proveedor;
  }

  Future<List<Proveedor>> buscarProveedoresPorNombre(String query) async {
    try {
      final snapshot = await _db.collection(_coleccion)
          .where('nombre', isGreaterThanOrEqualTo: query)
          .where('nombre', isLessThanOrEqualTo: '$query\uf8ff')
          .where('activo', isEqualTo: true)
          .limit(10)
          .get();
          
      return snapshot.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Proveedor>> buscarPorTipoInsumo(String tipoInsumo) async {
    try {
      final snapshot = await _db.collection(_coleccion)
          .where('tiposInsumos', arrayContains: tipoInsumo)
          .where('activo', isEqualTo: true)
          .get();
          
      return snapshot.docs.map((doc) => Proveedor.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<String> generarNuevoCodigo() async {
    try {
      final count = await _db.collection(_coleccion).count().get();
      return 'P-${(count.count! + 1).toString().padLeft(3, '0')}';
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  // Manejo centralizado de errores
  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para acceder a los proveedores');
      case 'not-found':
        return Exception('Proveedor no encontrado');
      case 'invalid-argument':
        return Exception('Datos del proveedor no válidos');
      default:
        return Exception('Error al acceder a los proveedores: ${e.message}');
    }
  }

  // --- Métodos de Integración ---

  // a) Desactivación en cascada (con transacción)
  Future<void> desactivarProveedorConInsumos(String id) async {
    await _db.runTransaction((transaction) async {
      // 1. Desactivar proveedor
      final proveedorRef = _db.collection(_coleccion).doc(id);
      transaction.update(proveedorRef, {
        'activo': false,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // 2. Desactivar insumos asociados (sin necesidad de _insumoService)
      final insumos = await transaction.get(
        _db.collection('insumos')
           .where('proveedorId', isEqualTo: id)
           .where('activo', isEqualTo: true) as DocumentReference<Object?>,
      );

      for (final doc in insumos.docs) {
        transaction.update(doc.reference, {
          'activo': false,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // b) Estadísticas del proveedor (usa InsumoService para lógica compleja)
  Future<Map<String, dynamic>> obtenerEstadisticasProveedor(String id) async {
    final proveedor = await obtenerProveedor(id);
    final insumos = await _insumoService.obtenerTodos(proveedorId: id);

    return {
      'proveedor': proveedor.nombre,
      'totalInsumos': insumos.length,
      'activo': proveedor.activo,
      'metricas': _calcularMetricas(insumos), // Método privado
      'categorias': proveedor.tiposInsumos,
    };
  }

  // --- Método privado de apoyo ---
  Map<String, dynamic> _calcularMetricas(List<Insumo> insumos) {
    if (insumos.isEmpty) return {'mensaje': 'Sin insumos registrados'};

    final precios = insumos.map((i) => i.precioUnitario).toList();
    return {
      'precioPromedio': precios.reduce((a, b) => a + b) / precios.length,
      'precioMinimo': precios.reduce((a, b) => a < b ? a : b),
      'precioMaximo': precios.reduce((a, b) => a > b ? a : b),
    };
  }
}

extension on DocumentSnapshot<Object?> {
  get docs => null;
}