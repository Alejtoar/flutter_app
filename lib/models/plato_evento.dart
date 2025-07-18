// lib/models/plato_evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

// *** IMPORTANTE: Importa el archivo donde definiste ItemExtra ***
import 'package:golo_app/models/item_extra.dart'; // Ajusta esta ruta!

class PlatoEvento {
  // --- Campos del Modelo ---
  final String? id; // ID del documento de la relación en Firestore
  final String eventoId; // ID del Evento al que pertenece
  final String platoId; // ID del Plato base
  final int cantidad; // Cantidad de este plato para el evento

  // --- Campos de Personalización Opcional ---
  final String?
  nombrePersonalizado; // Si se le da un nombre diferente para este evento
  final List<ItemExtra>?
  insumosExtra; // Lista de insumos añadidos específicamente
  final List<String>? insumosRemovidos; // Lista de IDs de insumos base a quitar
  final List<ItemExtra>? intermediosExtra; // Lista de intermedios añadidos
  final List<String>?
  intermediosRemovidos; // Lista de IDs de intermedios base a quitar

  // --- Constructor Principal ---
  const PlatoEvento({
    this.id,
    required this.eventoId,
    required this.platoId,
    required this.cantidad,
    this.nombrePersonalizado,
    this.insumosExtra,
    this.insumosRemovidos,
    this.intermediosExtra,
    this.intermediosRemovidos,
  });

  // --- Factory desde Firestore ---
  factory PlatoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Hacer data nullable

    if (data == null) {
      throw Exception(
        "Documento ${doc.id} en 'platos_eventos' no contiene datos.",
      );
    }

    // Validar campos requeridos String
    final eventoId = data['eventoId'] as String?;
    final platoId = data['platoId'] as String?;

    if (eventoId == null || eventoId.isEmpty) {
      throw Exception(
        "Campo 'eventoId' faltante o vacío en PlatoEvento ${doc.id}",
      );
    }
    if (platoId == null || platoId.isEmpty) {
      throw Exception(
        "Campo 'platoId' faltante o vacío en PlatoEvento ${doc.id}",
      );
    }

    // Helper interno para parsear listas de ItemExtra de forma segura
    List<ItemExtra>? parseExtras(dynamic listData) {
      if (listData is List) {
        return listData
            .map((item) {
              if (item is Map<String, dynamic>) {
                try {
                  // Usa el factory ItemExtra.fromJson que definiste
                  return ItemExtra.fromJson(item);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      "Error parseando ItemExtra en PlatoEvento ${doc.id}: $e, Item: $item",
                    );
                  }
                  return null; // Ignorar item mal formado
                }
              }
              if (kDebugMode) {
                print(
                  "Item en lista extra de PlatoEvento ${doc.id} no es un mapa: $item",
                );
              }
              return null; // Ignorar elementos que no son mapas
            })
            .where(
              (item) => item != null && item.id.isNotEmpty,
            ) // Filtrar nulos o con ID vacío
            .cast<ItemExtra>() // Castear a ItemExtra
            .toList();
      }
      return null; // Devolver null si no es una lista
    }

    // Helper interno para parsear listas de IDs (String) de forma segura
    List<String>? parseRemovedIds(dynamic listData) {
      if (listData is List) {
        return listData
            .map(
              (item) => item?.toString(),
            ) // Intenta convertir cada item a String
            .where(
              (id) => id != null && id.isNotEmpty,
            ) // Filtra nulos y strings vacíos
            .toList()
            .cast<String>();
      }
      return null;
    }

    return PlatoEvento(
      id: doc.id,
      eventoId: eventoId, // Ya validado
      platoId: platoId, // Ya validado
      cantidad:
          (data['cantidad'] as num?)?.toInt() ?? 0, // Manejo seguro de cantidad
      nombrePersonalizado: data['nombrePersonalizado'] as String?,

      // Usar los helpers para parsear
      insumosExtra: parseExtras(data['insumosExtra']),
      intermediosExtra: parseExtras(data['intermediosExtra']),
      insumosRemovidos: parseRemovedIds(data['insumosRemovidos']),
      intermediosRemovidos: parseRemovedIds(data['intermediosRemovidos']),
    );
  }

  // --- Método para convertir a Map para Firestore ---
  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'platoId': platoId,
      'cantidad': cantidad,
      // Incluir campos opcionales solo si no son null
      if (nombrePersonalizado != null && nombrePersonalizado!.isNotEmpty)
        'nombrePersonalizado': nombrePersonalizado,
      // Convertir listas de ItemExtra a listas de Map (JSON)
      if (insumosExtra != null && insumosExtra!.isNotEmpty)
        'insumosExtra': insumosExtra!.map((item) => item.toJson()).toList(),
      if (intermediosExtra != null && intermediosExtra!.isNotEmpty)
        'intermediosExtra':
            intermediosExtra!.map((item) => item.toJson()).toList(),
      // Las listas de String (IDs removidos) se guardan directamente
      if (insumosRemovidos != null && insumosRemovidos!.isNotEmpty)
        'insumosRemovidos': insumosRemovidos,
      if (intermediosRemovidos != null && intermediosRemovidos!.isNotEmpty)
        'intermediosRemovidos': intermediosRemovidos,
    };
    // Nota: El 'id' del documento de Firestore NO se incluye aquí.
  }

  // --- Método `copyWith` ---
  PlatoEvento copyWith({
    String? id,
    String? eventoId,
    String? platoId,
    int? cantidad,
    // Usar ValueGetter para permitir establecer null explícitamente
    ValueGetter<String?>? nombrePersonalizado,
    ValueGetter<List<ItemExtra>?>? insumosExtra,
    ValueGetter<List<String>?>? insumosRemovidos,
    ValueGetter<List<ItemExtra>?>? intermediosExtra,
    ValueGetter<List<String>?>? intermediosRemovidos,
  }) {
    return PlatoEvento(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      platoId: platoId ?? this.platoId,
      cantidad: cantidad ?? this.cantidad,
      nombrePersonalizado:
          nombrePersonalizado != null
              ? nombrePersonalizado()
              : this.nombrePersonalizado,
      insumosExtra: insumosExtra != null ? insumosExtra() : this.insumosExtra,
      insumosRemovidos:
          insumosRemovidos != null ? insumosRemovidos() : this.insumosRemovidos,
      intermediosExtra:
          intermediosExtra != null ? intermediosExtra() : this.intermediosExtra,
      intermediosRemovidos:
          intermediosRemovidos != null
              ? intermediosRemovidos()
              : this.intermediosRemovidos,
    );
  }

  // --- Igualdad y HashCode ---
  // Basado en ID si existe, sino en la combinación eventoId/platoId
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatoEvento &&
        other.id == id && // Compara ID si ambos existen
        (id != null ||
            (other.eventoId == eventoId &&
                other.platoId == platoId)); // Si no hay ID, compara la relación
  }

  @override
  int get hashCode => id?.hashCode ?? Object.hash(eventoId, platoId);

  // --- Representación String ---
  @override
  String toString() {
    return 'PlatoEvento(id: $id, eventoId: $eventoId, platoId: $platoId, cantidad: $cantidad, extras: ${insumosExtra?.length ?? 0}/${intermediosExtra?.length ?? 0}, removidos: ${insumosRemovidos?.length ?? 0}/${intermediosRemovidos?.length ?? 0})';
  }
}

// --- Helper para ValueGetter si no lo tienes globalmente ---
// Puedes poner esto al final del archivo o en un archivo de utilidades común
typedef ValueGetter<T> = T Function();
