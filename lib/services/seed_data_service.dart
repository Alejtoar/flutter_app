import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class SeedDataService {
  final FirebaseFirestore _db;

  SeedDataService(this._db);

  /// Puebla la base de datos con datos de ejemplo para un usuario específico.
  /// Solo se ejecuta si los datos no han sido sembrados previamente para ese UID.
  Future<void> seedDataForUser(String uid) async {
    // Referencia al documento principal del usuario
    final userDocRef = _db.collection('usuarios').doc(uid);

    // 1. Verificar si ya hemos sembrado datos para este usuario
    try {
      final docSnapshot = await userDocRef.get();
      if (docSnapshot.exists && (docSnapshot.data()?['dataSeeded'] == true)) {
        debugPrint("[SeedService] Los datos ya existen para el usuario $uid. Omitiendo sembrado.");
        return; // Salir de la función si ya se hizo
      }
    } catch (e) {
       debugPrint("[SeedService][ERROR] No se pudo verificar el estado de sembrado para $uid: $e. Procediendo con el sembrado por si acaso.");
       // Continuar igualmente puede ser una opción segura. Si el sembrado falla, no es crítico.
    }


    debugPrint("[SeedService] Sembrando datos de ejemplo para el nuevo usuario $uid...");
    final WriteBatch batch = _db.batch();

    try {
      // --- CREACIÓN DE DATOS DE EJEMPLO ---

      // 1. Proveedor de Ejemplo
      final provRef = userDocRef.collection('proveedores').doc();
      batch.set(provRef, {
        'codigo': 'P-DEMO',
        'nombre': 'Proveedor de Demostración',
        'telefono': '5551234774',
        'correo': 'demo@proveedor.com',
        'tiposInsumos': ['frutas', 'vegetales'],
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // 2. Insumos de Ejemplo
      final tomateRef = userDocRef.collection('insumos').doc();
      batch.set(tomateRef, {
        'codigo': 'I-001', 'nombre': 'Tomate Chonto', 'unidad': 'kg',
        'categorias': ['vegetales'], 'precioUnitario': 2.5, 'proveedorId': provRef.id,
        'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(), 'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      final cebollaRef = userDocRef.collection('insumos').doc();
      batch.set(cebollaRef, {
        'codigo': 'I-002', 'nombre': 'Cebolla Cabezona', 'unidad': 'kg',
        'categorias': ['vegetales'], 'precioUnitario': 1.8, 'proveedorId': provRef.id,
        'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(), 'fechaActualizacion': FieldValue.serverTimestamp(),
      });
       final polloRef = userDocRef.collection('insumos').doc();
      batch.set(polloRef, {
        'codigo': 'I-003', 'nombre': 'Pechuga de Pollo', 'unidad': 'kg',
        'categorias': ['cárnicos'], 'precioUnitario': 12.0, 'proveedorId': '', // Sin proveedor
        'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(), 'fechaActualizacion': FieldValue.serverTimestamp(),
      });


      // 3. Intermedio de Ejemplo
      final sofritoRef = userDocRef.collection('intermedios').doc();
      batch.set(sofritoRef, {
        'codigo': 'INT-001', 'nombre': 'Sofrito Base', 'unidad': 'gr',
        'cantidadEstandar': 500, 'reduccionPorcentaje': 10, 'categorias': ['Salsas'],
        'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(), 'fechaActualizacion': FieldValue.serverTimestamp(),
        'receta': 'Picar y sofreir tomate y cebolla.', 'tiempoPreparacionMinutos': 15,
      });

      // Relación Intermedio -> Insumo
      batch.set(userDocRef.collection('insumos_utilizados').doc(), {
        'intermedioId': sofritoRef.id, 'insumoId': tomateRef.id, 'cantidad': 300,
      });
      batch.set(userDocRef.collection('insumos_utilizados').doc(), {
        'intermedioId': sofritoRef.id, 'insumoId': cebollaRef.id, 'cantidad': 200,
      });

      // 4. Plato de Ejemplo
      final platoRef = userDocRef.collection('platos').doc();
      batch.set(platoRef, {
        'codigo': 'PC-001', 'nombre': 'Pollo en Sofrito', 'porcionesMinimas': 4,
        'descripcion': 'Un delicioso plato de demostración.', 'receta': 'Cocinar el pollo y bañar en sofrito.',
        'categorias': ['plato_fuerte'], 'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(), 'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // Relación Plato -> Intermedio
      batch.set(userDocRef.collection('intermedios_requeridos').doc(), {
        'platoId': platoRef.id, 'intermedioId': sofritoRef.id, 'cantidad': 400, // 400gr por 4 porciones
      });
      // Relación Plato -> Insumo
      batch.set(userDocRef.collection('insumos_requeridos').doc(), {
        'platoId': platoRef.id, 'insumoId': polloRef.id, 'cantidad': 0.8, // 0.8kg (800gr) por 4 porciones
      });

      // 5. Evento de Ejemplo
      final eventoRef = userDocRef.collection('eventos').doc();
      batch.set(eventoRef, {
        'codigo': 'EV-DEMO',
        'nombreCliente': 'Visitante del Portafolio',
        'fecha': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))), // Un evento en una semana
        'ubicacion': 'Tu Oficina',
        'numeroInvitados': 20,
        'tipoEvento': 'institucional', // Usar el 'name' del enum
        'estado': 'confirmado', // Usar el 'name' del enum
        'facturable': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'fechaCotizacion': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'comentariosLogistica': 'Este es un evento de ejemplo generado automáticamente para que puedas probar la aplicación.',
        'telefono': '555555445',
        'correo': 'visitante@example.com',
      });

      // Relación Evento -> Plato
      batch.set(userDocRef.collection('platos_eventos').doc(), {
        'eventoId': eventoRef.id,
        'platoId': platoRef.id,
        'cantidad': 20, // 20 porciones
      });

      // --- FIN DE DATOS DE EJEMPLO ---

      // 6. Marcar que ya hemos sembrado los datos para este usuario
      // Esto previene que se vuelva a ejecutar en futuras visitas
      batch.set(userDocRef, {'dataSeeded': true, 'createdAt': FieldValue.serverTimestamp()});

      // 7. Ejecutar todas las operaciones en un solo batch
      await batch.commit();
      debugPrint("[SeedService] Datos de ejemplo sembrados exitosamente para $uid.");
    } catch (e, st) {
      debugPrint("[SeedService][ERROR] Falló el batch de sembrado para $uid: $e\n$st");
      // No re-lanzar la excepción para no bloquear el inicio de la app.
      // Es mejor que el usuario entre a una app vacía a que no pueda entrar.
    }
  }
}