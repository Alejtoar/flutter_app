// evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Necesario para kDebugMode si quieres logs

// --- Enums ---
// Definidos fuera de la clase para mejor organización
enum TipoEvento {
  matrimonio,
  produccionAudiovisual,
  chefEnCasa,
  institucional
}

enum EstadoEvento {
  enCotizacion, // Estado inicial/default revisado
  cotizado,
  confirmado,
  enPruebaMenu,
  completado,
  cancelado
}

class Evento {
  // --- Campos del Modelo ---
  final String? id; // ID de Firestore
  final String codigo; // Código único legible (EV-001)
  final String nombreCliente;
  final String telefono;
  final String correo;
  final DateTime fecha; // Fecha del evento
  final String ubicacion;
  final int numeroInvitados;
  final TipoEvento tipoEvento;
  final EstadoEvento estado; // Usará el enum directamente
  final DateTime? fechaCotizacion; // Fecha en que se GENERÓ la cotización (puede ser null si se crea directo)
  final DateTime? fechaConfirmacion; // Fecha en que se confirmó el evento
  final DateTime fechaCreacion; // Fecha de creación del registro en Firestore
  final DateTime fechaActualizacion; // Fecha de la última actualización en Firestore
  final String? comentariosLogistica; // Notas adicionales
  final bool facturable; // Indica si el evento genera factura

  // --- Constructor Principal (const) ---
  // Usado internamente y para crear instancias inmutables.
  const Evento({
    this.id,
    required this.codigo,
    required this.nombreCliente,
    required this.telefono,
    required this.correo,
    required this.fecha,
    required this.ubicacion,
    required this.numeroInvitados,
    required this.tipoEvento,
    required this.estado,
    required this.fechaCreacion, // Requerida en el objeto final
    required this.fechaActualizacion, // Requerida en el objeto final
    this.fechaCotizacion, // Puede ser null
    this.fechaConfirmacion, // Puede ser null
    this.comentariosLogistica, // Puede ser null
    this.facturable = true, // Valor por defecto
  });

  // --- Factory Constructor con Validación y Defaults (`crear`) ---
  // Punto de entrada recomendado para crear nuevas instancias programáticamente.
  // Realiza validaciones básicas y establece valores por defecto.
  factory Evento.crear({
    String? id,
    required String codigo,
    required String nombreCliente,
    required String telefono,
    required String correo,
    required DateTime fecha,
    required String ubicacion,
    required int numeroInvitados,
    required TipoEvento tipoEvento,
    EstadoEvento? estado, // Opcional aquí para usar el default
    DateTime? fechaCotizacion,
    DateTime? fechaConfirmacion,
    DateTime? fechaCreacion, // Opcional aquí, se establece default
    DateTime? fechaActualizacion, // Opcional aquí, se establece default
    String? comentariosLogistica,
    bool? facturable, // Opcional aquí para usar el default
  }) {
    // Validaciones Esenciales (simplificadas según tu feedback)
    final errors = <String>[];

    if (codigo.isEmpty) errors.add('El código es requerido');
    if (nombreCliente.isEmpty) errors.add('El nombre del cliente es requerido');
    if (telefono.isEmpty) errors.add('El teléfono es requerido');
    if (correo.isEmpty) errors.add('El correo es requerido');
    if (ubicacion.isEmpty) errors.add('La ubicación es requerida');
    if (numeroInvitados <= 0) errors.add('El número de invitados debe ser positivo');

    // Validación de formato (mantenerlas es buena práctica)
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$'); // Un poco más flexible
    if (!phoneRegex.hasMatch(telefono)) {
      errors.add('Formato de teléfono no parece válido.');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(correo)) {
      errors.add('Correo electrónico no válido');
    }

    // --- Validación de Fechas (Comentadas - Activar si se necesitan) ---
    // final ahora = DateTime.now();
    // // Evitar fechas estrictamente en el pasado (ej. ayer), permitir hoy.
    // if (fecha.isBefore(DateTime(ahora.year, ahora.month, ahora.day))) {
    //   errors.add('La fecha del evento no puede ser anterior a hoy');
    // }
    // --- Fin Validaciones de Fechas ---


    if (errors.isNotEmpty) {
      throw ArgumentError('Error al crear evento:\n${errors.join('\n')}');
    }

    // Establecer Defaults
    final ahora = DateTime.now();
    return Evento(
      id: id,
      codigo: codigo,
      nombreCliente: nombreCliente,
      telefono: telefono,
      correo: correo,
      fecha: fecha,
      ubicacion: ubicacion,
      numeroInvitados: numeroInvitados,
      tipoEvento: tipoEvento,
      estado: estado ?? EstadoEvento.enCotizacion, // <<<--- DEFAULT A EN_COTIZACION
      fechaCotizacion: fechaCotizacion, // Puede ser null
      fechaConfirmacion: fechaConfirmacion, // Puede ser null
      fechaCreacion: fechaCreacion ?? ahora, // Default si no se provee
      fechaActualizacion: fechaActualizacion ?? ahora, // Default si no se provee
      comentariosLogistica: comentariosLogistica,
      facturable: facturable ?? true, // Default a true
    );
  }

  // --- Factory Constructor desde Firestore (`fromFirestore`) ---
  // Convierte un DocumentSnapshot de Firestore a un objeto Evento.
  factory Evento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Hacer el mapa nullable

    // Proveer valores por defecto si data es null o el campo falta
    if (data == null) {
       if (kDebugMode) { // Log en modo debug si falta data
         print('Advertencia: Documento ${doc.id} en colección "eventos" no tiene datos.');
       }
       // Retornar un objeto 'inválido' o lanzar excepción, según prefieras.
       // Aquí retornamos uno con valores mínimos para evitar crash, pero podría ser mejor lanzar error.
       final now = DateTime.now();
       return Evento(
           id: doc.id,
           codigo: 'ERR-${doc.id.substring(0, 4)}',
           nombreCliente: 'Cliente Desconocido',
           telefono: '-', correo: '-', fecha: now, ubicacion: 'Desconocida',
           numeroInvitados: 0, tipoEvento: TipoEvento.institucional, estado: EstadoEvento.cancelado,
           fechaCreacion: now, fechaActualizacion: now, facturable: false
       );
    }

    final ahora = DateTime.now(); // Para defaults de fechas si faltan

    // Helper para parsear enums de forma segura
    T _parseEnum<T>(List<T> enumValues, String? name, T defaultValue) {
      if (name == null) return defaultValue;
      try {
        return enumValues.firstWhere((e) => (e as Enum).name == name);
      } catch (e) {
        if (kDebugMode) {
          print('Advertencia: Valor de enum "$name" no encontrado para ${T.toString()}. Usando default: $defaultValue');
        }
        return defaultValue;
      }
    }

    return Evento(
      id: doc.id,
      codigo: data['codigo'] as String? ?? 'SIN-CODIGO',
      nombreCliente: data['nombreCliente'] as String? ?? 'Sin Nombre',
      telefono: data['telefono'] as String? ?? '-',
      correo: data['correo'] as String? ?? '-',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? ahora,
      ubicacion: data['ubicacion'] as String? ?? 'Sin Ubicación',
      numeroInvitados: (data['numeroInvitados'] as num?)?.toInt() ?? 0,
      tipoEvento: _parseEnum(
        TipoEvento.values,
        data['tipoEvento'] as String?, // Espera el 'name' del enum
        TipoEvento.institucional, // Default si falla
      ),
      estado: _parseEnum(
        EstadoEvento.values,
        data['estado'] as String?, // Espera el 'name' del enum
        EstadoEvento.enCotizacion, // Default si falla (o el que prefieras)
      ),
      fechaCotizacion: (data['fechaCotizacion'] as Timestamp?)?.toDate(), // Null si no existe
      fechaConfirmacion: (data['fechaConfirmacion'] as Timestamp?)?.toDate(), // Null si no existe
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? ahora, // Default si no existe
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate() ?? ahora, // Default si no existe
      comentariosLogistica: data['comentariosLogistica'] as String?, // Null si no existe
      facturable: data['facturable'] as bool? ?? true, // Default a true si no existe
    );
  }

  // --- Método para convertir a Map para Firestore (`toFirestore`) ---
  // Prepara el objeto para ser guardado/actualizado en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombreCliente': nombreCliente,
      'telefono': telefono,
      'correo': correo,
      'fecha': Timestamp.fromDate(fecha),
      'ubicacion': ubicacion,
      'numeroInvitados': numeroInvitados,
      'tipoEvento': tipoEvento.name, // <<<--- GUARDA EL NOMBRE DEL ENUM
      'estado': estado.name, // <<<--- GUARDA EL NOMBRE DEL ENUM
      // Guarda Timestamp o null para fechas opcionales
      'fechaCotizacion': fechaCotizacion != null ? Timestamp.fromDate(fechaCotizacion!) : null,
      'fechaConfirmacion': fechaConfirmacion != null ? Timestamp.fromDate(fechaConfirmacion!) : null,
      // Siempre incluir fechaCreacion (se establece una vez)
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      // IMPORTANTE: fechaActualizacion se manejará usualmente con FieldValue.serverTimestamp()
      // en el repositorio al ACTUALIZAR. Al CREAR, se usa el valor inicial.
      // No lo incluimos aquí para evitar sobreescribirlo accidentalmente en updates.
      'comentariosLogistica': comentariosLogistica,
      'facturable': facturable,
    };
    // NOTA: El repositorio se encargará de añadir 'fechaActualizacion': FieldValue.serverTimestamp()
    // cuando se llame al método de actualizar.
  }

  // --- Método `copyWith` ---
  // Útil para crear copias modificadas del objeto (patrón de inmutabilidad).
  Evento copyWith({
    String? id,
    String? codigo,
    String? nombreCliente,
    String? telefono,
    String? correo,
    DateTime? fecha,
    String? ubicacion,
    int? numeroInvitados,
    TipoEvento? tipoEvento,
    EstadoEvento? estado,
    ValueGetter<DateTime?>? fechaCotizacion, // Usa ValueGetter para poder poner null explícitamente
    ValueGetter<DateTime?>? fechaConfirmacion, // Usa ValueGetter para poder poner null explícitamente
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion, // Permite actualizarla explícitamente si es necesario
    ValueGetter<String?>? comentariosLogistica, // Usa ValueGetter para poder poner null explícitamente
    bool? facturable,
  }) {
    // ValueGetter permite diferenciar entre no pasar el parámetro (usa this)
    // y pasar null explícitamente.
    return Evento(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      fecha: fecha ?? this.fecha,
      ubicacion: ubicacion ?? this.ubicacion,
      numeroInvitados: numeroInvitados ?? this.numeroInvitados,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      estado: estado ?? this.estado,
      // Usa ?? solo si el parámetro no es ValueGetter o si quieres que null no sobreescriba
      fechaCotizacion: fechaCotizacion != null ? fechaCotizacion() : this.fechaCotizacion,
      fechaConfirmacion: fechaConfirmacion != null ? fechaConfirmacion() : this.fechaConfirmacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      // Si se pasa fechaActualizacion, se usa; si no, se mantiene la existente.
      // El repo la sobreescribirá en updates con serverTimestamp.
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      comentariosLogistica: comentariosLogistica != null ? comentariosLogistica() : this.comentariosLogistica,
      facturable: facturable ?? this.facturable,
    );
  }

  // --- Igualdad y HashCode ---
  // Basado en ID si existe, sino en código (o combinación si prefieres).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evento &&
        other.id == id && // Compara ID si ambos existen
        (id != null || other.codigo == codigo); // Si no hay ID, compara código
  }

  @override
  int get hashCode => id?.hashCode ?? codigo.hashCode;

  // --- Representación String ---
  @override
  String toString() {
    return 'Evento(id: $id, codigo: $codigo, cliente: $nombreCliente, fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}, estado: ${estado.name})';
  }
}

// Helper para ValueGetter en copyWith si no lo tienes ya
typedef ValueGetter<T> = T Function();