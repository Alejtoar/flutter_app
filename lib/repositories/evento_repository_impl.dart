// evento_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/config/app_config.dart';

// Asumiendo que tienes una interfaz EventoRepository definida en alguna parte
// abstract class EventoRepository { ... }

class EventoFirestoreRepository implements EventoRepository {
  final FirebaseFirestore _db;
  final String _coleccion = 'eventos';
  final bool _isMultiUser =
      AppConfig
          .instance
          .isMultiUser; //aca ya inicie la var pero aun no lo cambio todo


  EventoFirestoreRepository(this._db);

  CollectionReference _getCollection({String? uid}) {
    if (_isMultiUser) {
      // Si es multi-usuario, DEBEMOS tener un uid.
      if (uid == null || uid.isEmpty) {
        throw Exception(
          "UID de usuario es requerido para operaciones en modo multi-usuario.",
        );
      }
      // Construye la ruta anidada
      return _db.collection('usuarios').doc(uid).collection(_coleccion);
    } else {
      // Si no, usamos la colección a nivel raíz.
      return _db.collection(_coleccion);
    }
  }

  @override
  Future<Evento> crear(Evento evento, {String? uid}) async {
    try {
      // La validación del código único y la generación se manejan mejor ANTES de llamar a este método,
      // posiblemente en el Controller o Service, para mantener el repo enfocado en la interacción con DB.
      // Sin embargo, si quieres mantener la verificación aquí:
      if (await existeCodigo(evento.codigo, uid: uid)) {
        throw Exception('El código ${evento.codigo} ya está en uso para otro evento.');
      }

      // El objeto 'evento' ya debería venir con fechaCreacion y fechaActualizacion iniciales
      // establecidas por Evento.crear()
      final eventoData = evento.toFirestore();

      final docRef = await _getCollection(uid: uid).add(eventoData);
      if (kDebugMode) {
        print('Evento creado en Firestore con ID: ${docRef.id}');
      }
      // Retornamos el evento original pero con el ID asignado por Firestore
      return evento.copyWith(id: docRef.id);

    } on FirebaseException catch (e) {
       if (kDebugMode) {
         print('Error Firebase al crear evento: ${e.code} - ${e.message}');
       }
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) {
         print('Error general al crear evento: $e');
       }
      // Re-lanzar errores inesperados
      throw Exception('Error inesperado al crear el evento: $e');
    }
  }

  @override
  Future<Evento> obtener(String id, {String? uid}) async {
    try {
      final doc = await _getCollection(uid: uid).doc(id).get();
      if (!doc.exists) {
        throw Exception('Evento con ID $id no encontrado.');
      }
      // Usamos el factory actualizado que maneja nulls y parsing de enums
      return Evento.fromFirestore(doc);

    } on FirebaseException catch (e) {
       if (kDebugMode) {
         print('Error Firebase al obtener evento $id: ${e.code} - ${e.message}');
       }
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) {
         print('Error general al obtener evento $id: $e');
       }
       if (e is Exception && e.toString().contains('no encontrado')) {
          rethrow; // Lanza la excepción específica de "no encontrado"
       }
       throw Exception('Error inesperado al obtener el evento $id: $e');
    }
  }

  @override
  Future<void> actualizar(Evento evento, {String? uid}) async {
    // Validación básica
    if (evento.id == null || evento.id!.isEmpty) {
      throw ArgumentError('El evento debe tener un ID para ser actualizado.');
    }

    try {
      final docRef = _getCollection(uid: uid).doc(evento.id!);

      // Preparamos los datos usando toFirestore()
      final eventoData = evento.toFirestore();

      // *** IMPORTANTE: Añadir la fecha de actualización del servidor ***
      eventoData['fechaActualizacion'] = FieldValue.serverTimestamp();

      // No es necesario verificar si existe antes con get(), update falla si no existe.
      await docRef.update(eventoData);
      if (kDebugMode) {
        print('Evento actualizado en Firestore con ID: ${evento.id}');
      }

    } on FirebaseException catch (e) {
       if (kDebugMode) {
         print('Error Firebase al actualizar evento ${evento.id}: ${e.code} - ${e.message}');
       }
      // Manejar específicamente el caso 'not-found' si queremos un mensaje más claro
      if (e.code == 'not-found') {
         throw Exception('No se pudo actualizar: Evento con ID ${evento.id} no encontrado.');
      }
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) {
         print('Error general al actualizar evento ${evento.id}: $e');
       }
       throw Exception('Error inesperado al actualizar el evento ${evento.id}: $e');
    }
  }

  @override
  Future<void> eliminar(String id, {String? uid}) async {
     if (id.isEmpty) {
      throw ArgumentError('Se requiere un ID para eliminar un evento.');
    }
    try {
      // Considerar verificaciones de dependencia aquí si es necesario en el futuro
      // (ej. no eliminar si está 'confirmado' o 'completado'?)
      await _getCollection(uid: uid).doc(id).delete();
      if (kDebugMode) {
        print('Evento eliminado de Firestore con ID: $id');
      }
    } on FirebaseException catch (e) {
       if (kDebugMode) {
         print('Error Firebase al eliminar evento $id: ${e.code} - ${e.message}');
       }
       // Si no se encuentra, podría no ser un error crítico dependiendo del caso de uso
       if (e.code == 'not-found') {
         print('Advertencia: Se intentó eliminar el evento $id, pero no se encontró.');
         // No relanzar la excepción si no encontrar no es un error fatal
         return;
       }
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) {
         print('Error general al eliminar evento $id: $e');
       }
       throw Exception('Error inesperado al eliminar el evento $id: $e');
    }
  }

  @override
  Future<List<Evento>> obtenerTodos({String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          // Puedes añadir un orderBy por defecto si lo deseas, ej. por fecha de evento o creación
          // .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();

    } on FirebaseException catch (e) {
       if (kDebugMode) {
         print('Error Firebase al obtener todos los eventos: ${e.code} - ${e.message}');
       }
      throw _handleFirestoreError(e);
    } catch (e) {
       if (kDebugMode) {
         print('Error general al obtener todos los eventos: $e');
       }
      throw Exception('Error inesperado al obtener todos los eventos: $e');
    }
  }

  @override
  Future<List<Evento>> obtenerPorEstado(EstadoEvento estado, {String? uid}) async {
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('estado', isEqualTo: estado.name) // <<<--- Usar .name para la query
          .get();
      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al obtener eventos por estado ${estado.name}: $e');
    }
  }

  @override
  Future<List<Evento>> obtenerPorTipo(TipoEvento tipo, {String? uid}) async {
     try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('tipoEvento', isEqualTo: tipo.name) // <<<--- Usar .name para la query
          .get();
      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al obtener eventos por tipo ${tipo.name}: $e');
    }
  }

  @override
  Future<List<Evento>> obtenerPorRangoFechas(DateTime desde, DateTime hasta, {String? uid}) async {
    // Asegúrate de que 'hasta' incluya todo el día si es necesario
    final hastaEndOfDay = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59);
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(hastaEndOfDay))
          .orderBy('fecha') // Es bueno ordenar por el campo del rango
          .get();
      return querySnapshot.docs.map((doc) => Evento.fromFirestore(doc)).toList();

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al obtener eventos por rango de fechas: $e');
    }
  }

  @override
  Future<String> generarNuevoCodigo({String? uid}) async {
    // Esta implementación busca el último código numérico y lo incrementa.
    // Puede ser menos robusta si hay códigos no numéricos o eliminaciones.
    // Una alternativa es usar un contador separado en Firestore (más complejo).
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      String ultimoCodigo = 'EV-000'; // Base si no hay eventos
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
        final codigoDb = data?['codigo'] as String?;
        // Validar formato antes de parsear
        if (codigoDb != null && codigoDb.startsWith('EV-') && codigoDb.length > 3) {
           ultimoCodigo = codigoDb;
        } else if (kDebugMode) {
          print('Advertencia: Último código encontrado ($codigoDb) no sigue el formato EV-XXX. Usando base EV-000.');
        }
      }

      int numero = 0;
      try {
         // Extraer la parte numérica de forma segura
         final parts = ultimoCodigo.split('-');
         if (parts.length == 2) {
            numero = int.tryParse(parts[1]) ?? 0;
         }
      } catch (_) {
         // Ignorar error de parseo, se queda en 0
         if (kDebugMode) {
           print('Advertencia: No se pudo parsear el número del último código ($ultimoCodigo). Usando base 0.');
         }
      }

      // Incrementar y formatear
      final nuevoNumero = numero + 1;
      return 'EV-${nuevoNumero.toString().padLeft(3, '0')}';

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
      throw Exception('Error inesperado al generar nuevo código de evento: $e');
    }
  }

  @override
  Future<bool> existeCodigo(String codigo, {String? uid}) async {
     if (codigo.isEmpty) return false; // No buscar códigos vacíos
    try {
      final querySnapshot = await _getCollection(uid: uid)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al verificar existencia del código $codigo: $e');
    }
  }

  // --- Métodos que podrían no estar en uso activo (revisar si se necesitan) ---

  @override
  Future<Evento> obtenerPorCodigo(String codigo, {String? uid}) async {
    try {
      final query = await _getCollection(uid: uid)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception('Evento con código $codigo no encontrado');
      return Evento.fromFirestore(query.docs.first);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  @override
  Future<List<Evento>> buscarPorNombre(String query, {String? uid}) async {
     // Firestore no soporta búsqueda de subcadenas eficientemente.
     // Esta implementación trae todos y filtra en cliente (puede ser ineficiente).
     // Considerar soluciones como Algolia/Elasticsearch para búsquedas complejas.
    try {
      final todosLosEventos = await obtenerTodos(uid: uid); // Reutiliza obtenerTodos

      if (query.isEmpty) return todosLosEventos; // Devuelve todos si no hay query

      final queryLower = query.toLowerCase();
      final filtrados = todosLosEventos.where((evento) {
        // Buscar en nombreCliente y código (puedes añadir otros campos)
        return evento.nombreCliente.toLowerCase().contains(queryLower) ||
               evento.codigo.toLowerCase().contains(queryLower);
               // evento.correo.toLowerCase().contains(queryLower) // Ejemplo adicional
      }).toList();

      return filtrados;

    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    } catch (e) {
       throw Exception('Error inesperado al buscar eventos por nombre "$query": $e');
    }
  }

  @override
  Future<bool> existeEventoConNombre(String nombre, {String? uid}) async {
    // Nota: Firestore es sensible a mayúsculas/minúsculas en queries 'isEqualTo'.
    // Para búsqueda insensible, se necesita filtrar en cliente (como en buscarPorNombre)
    // o normalizar el campo (ej. guardar nombreClienteLower).
    try {
       final query = await _getCollection(uid: uid)
           .where('nombreCliente', isEqualTo: nombre) // Búsqueda exacta (case-sensitive)
           .limit(1)
           .get();
       return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
       throw _handleFirestoreError(e);
    }
  }

  // --- Manejador de Errores de Firestore ---
  Exception _handleFirestoreError(FirebaseException e) {
    if (kDebugMode) {
      print("Firebase Error Code: ${e.code}, Message: ${e.message}");
    }
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permiso denegado para acceder a los eventos.');
      case 'not-found':
        // Este código a veces es ambiguo (puede ser el doc o la colección)
        // Se maneja más específicamente en los métodos que lo usan.
        return Exception('Recurso no encontrado en Firestore (podría ser el evento o la colección).');
      case 'unavailable':
         return Exception('El servicio de Firestore no está disponible. Revisa tu conexión.');
       case 'invalid-argument':
         return Exception('Argumento inválido enviado a Firestore. Revisa los datos.');
      // Añadir otros códigos comunes si es necesario
      default:
        return Exception('Error inesperado de Firestore al operar con eventos: ${e.message ?? e.code}');
    }
  }
}