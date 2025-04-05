import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intermedio.dart';
import '../models/insumo_utilizado.dart';
import './insumo_service.dart';

class IntermedioService {
  final FirebaseFirestore _db;
  final InsumoService _insumoService;
  final String _coleccion = 'intermedios';

  // Inyección de dependencias para mejor testabilidad
  IntermedioService({
    FirebaseFirestore? db,
    InsumoService? insumoService,
  }) : _db = db ?? FirebaseFirestore.instance,
       _insumoService = insumoService ?? InsumoService();

  // Operaciones CRUD mejoradas
  Future<Intermedio> crearIntermedio(Intermedio intermedio) async {
    try {
      final docRef = await _db.collection(_coleccion).add(intermedio.toFirestore());
      return intermedio.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Intermedio> obtenerIntermedio(String id) async {
    try {
      final doc = await _db.collection(_coleccion).doc(id).get();
      if (!doc.exists) throw Exception('Intermedio no encontrado');
      return Intermedio.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<Intermedio>> obtenerTodos() async {
    try {
      final query = await _db.collection(_coleccion)
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      return query.docs.map((doc) => Intermedio.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> actualizarIntermedio(Intermedio intermedio) async {
    try {
      await _db.collection(_coleccion)
          .doc(intermedio.id)
          .update(intermedio.toFirestore());
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> desactivarIntermedio(String id) async {
    try {
      await _db.collection(_coleccion)
          .doc(id)
          .update({'activo': false, 'fechaActualizacion': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  // Métodos específicos de negocio
  Future<Intermedio> crearIntermedioConValidacion({
    required String nombre,
    required List<Map<String, dynamic>> insumosData,
    required List<String> categorias,
    double? reduccionPorcentaje,
    String? receta,
    String? instrucciones,
  }) async {
    // Validación de insumos
    final insumosCompletos = await _validarYObtenerInsumos(insumosData);

    // Crear intermedio con validación incorporada
    final intermedio = Intermedio.crear(
      codigo: await _generarCodigo(),
      nombre: nombre,
      categorias: categorias,
      reduccionPorcentaje: reduccionPorcentaje,
      receta: receta ?? '',
      instrucciones: instrucciones ?? '',
      insumos: insumosCompletos,
    );

    return intermedio;
  }

  Future<List<InsumoUtilizado>> _validarYObtenerInsumos(
      List<Map<String, dynamic>> insumosData) async {
    if (insumosData.isEmpty) {
      throw ArgumentError('Debe proporcionar al menos un insumo');
    }

    final insumosIds = insumosData.map((i) => i['insumoId'] as String).toList();
    final insumos = await _insumoService.obtenerInsumos(insumosIds);

    if (insumos.length != insumosIds.length) {
      throw Exception('Algunos insumos no fueron encontrados');
    }

    return insumosData.map((data) {
      final insumo = insumos.firstWhere((i) => i.id == data['insumoId']);
      return InsumoUtilizado.crear(
        insumoId: insumo.id!,
        codigo: insumo.codigo,
        nombre: insumo.nombre,
        unidad: insumo.unidad,
        cantidad: (data['cantidad'] ?? 0).toDouble(),
        precioUnitario: insumo.precioUnitario,
      );
    }).toList();
  }

  Future<String> _generarCodigo() async {
    try {
      final count = await _db.collection(_coleccion).count().get();
      return 'PI-${(count.count! + 1).toString().padLeft(3, '0')}';
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  // Manejo centralizado de errores
  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('No tienes permiso para realizar esta acción');
      case 'not-found':
        return Exception('Recurso no encontrado');
      default:
        return Exception('Error de Firestore: ${e.message}');
    }
  }
}