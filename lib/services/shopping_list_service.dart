// services/shopping_list_service.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Para .groupListsBy
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:golo_app/models/proveedor.dart'; // Necesario para agrupar

// Repositorios
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/repositories/plato_evento_repository.dart';
import 'package:golo_app/repositories/intermedio_evento_repository.dart';
import 'package:golo_app/repositories/insumo_evento_repository.dart';
import 'package:golo_app/repositories/plato_repository.dart';
import 'package:golo_app/repositories/intermedio_repository.dart';
import 'package:golo_app/repositories/insumo_repository.dart';
import 'package:golo_app/repositories/insumo_requerido_repository.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository.dart';
import 'package:golo_app/repositories/proveedor_repository.dart'; // Necesario para agrupar

// --- Definiciones de Tipos (Fuera de la clase) ---

// Estructura interna para acumular totales por unidad
// insumoId -> { unidad -> cantidadTotal }
typedef ShoppingListTotals = Map<String, Map<String, double>>;

// Estructura para representar un item individual en la lista final (con objeto Insumo)
class ShoppingListItem {
  final Insumo insumo;
  final String unidad;
  final double cantidad;
  final double costoItem;
  final bool? esFacturable; // Null si es combinado, true/false si está separado

  const ShoppingListItem({
    required this.insumo,
    required this.unidad,
    required this.cantidad,
    required this.costoItem,
    this.esFacturable,
  });

  // Para ordenar o mostrar
  @override
  String toString() =>
      '${insumo.nombre} - ${cantidad.toStringAsFixed(2)} $unidad (Costo: \$${costoItem.toStringAsFixed(2)})';
}

// Estructura para el resultado final agrupado por proveedor
// Proveedor? (null para sin proveedor) -> Lista de ShoppingListItem
typedef GroupedShoppingListResult = Map<Proveedor?, List<ShoppingListItem>>;

class QuantityBreakdown {
  double facturable = 0.0;
  double noFacturable = 0.0;

  double get total => facturable + noFacturable;
}

// Nueva estructura intermedia: insumoId -> { unidad -> QuantityBreakdown }
typedef DetailedShoppingListTotals =
    Map<String, Map<String, QuantityBreakdown>>;

// --- Clase Principal del Servicio ---
class ShoppingListService {
  // Inyectar todos los repositorios necesarios
  final EventoRepository eventoRepo;
  final PlatoEventoRepository platoEventoRepo;
  final IntermedioEventoRepository intermedioEventoRepo;
  final InsumoEventoRepository insumoEventoRepo;
  final PlatoRepository platoRepo;
  final IntermedioRepository intermedioRepo;
  final InsumoRepository insumoRepo;
  final InsumoRequeridoRepository insumoRequeridoRepo;
  final IntermedioRequeridoRepository intermedioRequeridoRepo;
  final InsumoUtilizadoRepository insumoUtilizadoRepo;
  final ProveedorRepository proveedorRepo;

  ShoppingListService({
    required this.eventoRepo,
    required this.platoEventoRepo,
    required this.intermedioEventoRepo,
    required this.insumoEventoRepo,
    required this.platoRepo,
    required this.intermedioRepo,
    required this.insumoRepo,
    required this.insumoRequeridoRepo,
    required this.intermedioRequeridoRepo,
    required this.insumoUtilizadoRepo,
    required this.proveedorRepo,
  });

  // --- Cachés Temporales ---
  Map<String, Plato> _platoCache = {};
  Map<String, Intermedio> _intermedioCache = {};
  Map<String, Insumo> _insumoCache = {}; // Caché para insumos base también
  Map<String, List<InsumoRequerido>> _insumoRequeridoCache = {};
  Map<String, List<IntermedioRequerido>> _intermedioRequeridoCache = {};
  Map<String, List<InsumoUtilizado>> _insumoUtilizadoCache = {};

  // // --- Método Principal Combinado ---
  // Future<GroupedShoppingListResult> generateAndGroupShoppingList(
  //   List<String> eventoIds,
  // ) async {
  //   debugPrint(
  //     "[ShoppingListService] Iniciando generación COMBINADA y AGRUPADA para ${eventoIds.length} eventos.",
  //   );
  //   _clearCaches();
  //   final ShoppingListTotals totals = {}; // Acumulador global por unidad

  //   // 1. Procesar todos los eventos para obtener los totales acumulados
  //   for (final eventoId in eventoIds) {
  //     debugPrint(
  //       "[ShoppingListService] Procesando evento combinado: $eventoId",
  //     );
  //     try {
  //       await _processSingleEventIntoTotals(totals, eventoId);
  //     } catch (e, st) {
  //       debugPrint(
  //         "[ShoppingListService][ERROR] Falló procesamiento $eventoId (combinado): $e\n$st",
  //       );
  //       // Continuar con los otros eventos
  //     }
  //   }

  //   // 2. Convertir totales a lista de ShoppingListItem
  //   debugPrint(
  //     "[ShoppingListService] Totales por unidad calculados: ${totals.length} insumos únicos.",
  //   );
  //   final List<ShoppingListItem> flatList = await _mapTotalsToShoppingListItems(
  //     totals,
  //   );

  //   // 3. Agrupar la lista plana por proveedor
  //   debugPrint(
  //     "[ShoppingListService] Agrupando ${flatList.length} items por proveedor...",
  //   );
  //   final groupedList = await _groupShoppingListByProvider(flatList);
  //   debugPrint(
  //     "[ShoppingListService] Agrupación finalizada. ${groupedList.length} grupos (incluyendo sin proveedor).",
  //   );

  //   return groupedList;
  // }

  // --- Función Interna para Procesar UN Evento y añadir a Totales ---
  // Future<void> _processSingleEventIntoTotals(
  //   ShoppingListTotals totals,
  //   String eventoId,
  // ) async {
  //   // 1. Cargar relaciones de ESTE evento
  //   final List<PlatoEvento> platosEvento = await platoEventoRepo
  //       .obtenerPorEvento(eventoId);
  //   final List<IntermedioEvento> intermediosEvento = await intermedioEventoRepo
  //       .obtenerPorEvento(eventoId);
  //   final List<InsumoEvento> insumosEvento = await insumoEventoRepo
  //       .obtenerPorEvento(eventoId);

  //   // 2. Procesar Insumos Directos (con unidad)
  //   for (final insumoEv in insumosEvento) {
  //     await _addInsumoQuantity(
  //       totals,
  //       insumoEv.insumoId,
  //       insumoEv.unidad,
  //       insumoEv.cantidad,
  //     );
  //   }

  //   // 3. Procesar Intermedios Directos (recursivo)
  //   for (final intermedioEv in intermediosEvento) {
  //     await _processIntermedio(
  //       totals,
  //       intermedioEv.intermedioId,
  //       intermedioEv.cantidad.toDouble(),
  //     );
  //   }

  //   // 4. Procesar Platos (recursivo con personalización)
  //   for (final platoEv in platosEvento) {
  //     await _processPlatoEvento(totals, platoEv);
  //   }
  // }

  // --- Métodos Helper Internos ---

  void _clearCaches() {
    _platoCache = {};
    _intermedioCache = {};
    _insumoCache = {};
    _insumoRequeridoCache = {};
    _intermedioRequeridoCache = {};
    _insumoUtilizadoCache = {};
    debugPrint("[ShoppingListService] Cachés limpiadas.");
  }

  // Añade cantidad a un insumo/unidad específicos
  // Future<void> _addInsumoQuantity(
  //   ShoppingListTotals totals,
  //   String insumoId,
  //   String? unidad,
  //   double quantity,
  // ) async {
  //   if (insumoId.isEmpty || quantity <= 0) return;

  //   String unidadNormalizada =
  //       unidad?.trim().toLowerCase() ??
  //       'unidad'; // Usar 'unidad' o similar si es null/vacío
  //   if (unidadNormalizada.isEmpty) unidadNormalizada = 'unidad'; // Doble check

  //   // Obtener el insumo base para referencia (opcional, podría hacerse al final)
  //   // final insumoBase = await _getInsumoBase(insumoId);
  //   // if (insumoBase == null) {
  //   //    debugPrint("[ShoppingListService][WARN] No se encontró insumo base para ID $insumoId al añadir cantidad.");
  //   //    // Podrías usar una unidad por defecto o manejar el error
  //   // }
  //   // String unidadFinal = unidadNormalizada ?? insumoBase?.unidad ?? 'unidad';

  //   // Crear mapa de unidades para este insumo si no existe
  //   totals.putIfAbsent(insumoId, () => {});
  //   // Añadir cantidad a la unidad específica
  //   totals[insumoId]![unidadNormalizada] =
  //       (totals[insumoId]![unidadNormalizada] ?? 0) + quantity;

  //   // debugPrint("[ShoppingListService] (+ ${quantity.toStringAsFixed(2)} $unidadNormalizada) -> Insumo ID: $insumoId (Total: ${totals[insumoId]![unidadNormalizada]?.toStringAsFixed(2)})");
  // }

  // Procesa un PlatoEvento, aplicando personalizaciones y descomponiendo
  // Future<void> _processPlatoEvento(
  //   ShoppingListTotals totals,
  //   PlatoEvento platoEvento,
  // ) async {
  //   final platoBase = await _getPlatoBase(platoEvento.platoId);
  //   if (platoBase == null) {
  //     debugPrint(
  //       "[ShoppingListService][WARN] Plato base ID ${platoEvento.platoId} no encontrado, omitiendo.",
  //     );
  //     return;
  //   }
  //   if (platoBase.porcionesMinimas <= 0) {
  //     debugPrint(
  //       "[ShoppingListService][WARN] Plato base ID ${platoBase.id} tiene porcionesMinimas <= 0, omitiendo para evitar división por cero.",
  //     );
  //     return;
  //   }

  //   // Cantidad de este plato solicitada en el evento
  //   final double cantidadPlatoEvento = platoEvento.cantidad.toDouble();
  //   if (cantidadPlatoEvento <= 0) return;

  //   debugPrint(
  //     "[ShoppingListService] Procesando PlatoEvento: ${platoBase.nombre} x ${platoEvento.cantidad} (Base: ${platoBase.porcionesMinimas} porciones)",
  //   );

  //   // --- Calcular Ratio del Plato ---
  //   // Este ratio se aplicará a las cantidades de los componentes directos del plato.
  //   final double ratioPlato = cantidadPlatoEvento / platoBase.porcionesMinimas;
  //   debugPrint(
  //     "    Ratio Plato (Rp): $cantidadPlatoEvento / ${platoBase.porcionesMinimas} = $ratioPlato",
  //   );

  //   final Set<String> insumosRemovidos = Set.from(
  //     platoEvento.insumosRemovidos ?? [],
  //   );
  //   final Set<String> intermediosRemovidos = Set.from(
  //     platoEvento.intermediosRemovidos ?? [],
  //   );

  //   // --- Procesar Insumos Requeridos del Plato Base ---
  //   final List<InsumoRequerido> insumosBaseReq = await _getInsumosRequeridos(
  //     platoBase.id!,
  //   );
  //   for (final irBase in insumosBaseReq) {
  //     if (!insumosRemovidos.contains(irBase.insumoId)) {
  //       final insumoBaseDef = await _getInsumoBase(irBase.insumoId);
  //       // Aplicar Ratio del Plato
  //       final cantidadNecesaria = irBase.cantidad * ratioPlato;
  //       await _addInsumoQuantity(
  //         totals,
  //         irBase.insumoId,
  //         insumoBaseDef?.unidad,
  //         cantidadNecesaria,
  //       );
  //       debugPrint(
  //         "      Insumo Req: ${insumoBaseDef?.nombre ?? irBase.insumoId} -> Cant: ${irBase.cantidad} * Rp $ratioPlato = $cantidadNecesaria",
  //       );
  //     } else {
  //       debugPrint("      Insumo Req base ${irBase.insumoId} REMOVIDO.");
  //     }
  //   }

  //   // --- Procesar Insumos Extra del PlatoEvento ---
  //   // Se asume que la cantidad en ItemExtra es POR PORCIÓN del PlatoEvento (o por unidad de plato base).
  //   // Si la cantidad del ItemExtra es TOTAL para las N unidades del platoEvento, no multiplicar por ratioPlato aquí.
  //   // **Asumiremos que es POR PORCIÓN DEL PLATO BASE para consistencia con los requeridos base.**
  //   for (final itemExtra in platoEvento.insumosExtra ?? []) {
  //     final insumoBaseDef = await _getInsumoBase(itemExtra.id);
  //     // La cantidad del extra se multiplica por el ratio del plato
  //     final cantidadNecesariaExtra = itemExtra.cantidad * cantidadPlatoEvento;
  //     await _addInsumoQuantity(
  //       totals,
  //       itemExtra.id,
  //       insumoBaseDef?.unidad,
  //       cantidadNecesariaExtra,
  //     );
  //     debugPrint(
  //       "      Insumo Extra: ${insumoBaseDef?.nombre ?? itemExtra.id} -> Cant: ${itemExtra.cantidad} * Rp $ratioPlato = $cantidadNecesariaExtra",
  //     );
  //   }

  //   // --- Procesar Intermedios Requeridos del Plato Base ---
  //   final List<IntermedioRequerido> intermediosBaseReq =
  //       await _getIntermediosRequeridos(platoBase.id!);
  //   for (final irBase in intermediosBaseReq) {
  //     if (!intermediosRemovidos.contains(irBase.intermedioId)) {
  //       // La cantidad del intermedio requerido se multiplica por el Ratio del Plato
  //       final cantidadIntermedioNecesaria = irBase.cantidad * ratioPlato;
  //       await _processIntermedio(
  //         totals,
  //         irBase.intermedioId,
  //         cantidadIntermedioNecesaria,
  //       );
  //       // El debugPrint del intermedio se hará dentro de _processIntermedio
  //     } else {
  //       debugPrint(
  //         "      Intermedio Req base ${irBase.intermedioId} REMOVIDO.",
  //       );
  //     }
  //   }

  //   // --- Procesar Intermedios Extra del PlatoEvento ---
  //   // Similar a insumos extra, asumimos que itemExtra.cantidad es por porción del plato base.
  //   for (final itemExtra in platoEvento.intermediosExtra ?? []) {
  //     final cantidadIntermedioExtraNecesaria =
  //         itemExtra.cantidad * cantidadPlatoEvento;
  //     await _processIntermedio(
  //       totals,
  //       itemExtra.id,
  //       cantidadIntermedioExtraNecesaria,
  //     );
  //   }
  // }

  // // Procesa un Intermedio, obteniendo sus InsumosUtilizados
  // Future<void> _processIntermedio(
  //   ShoppingListTotals totals,
  //   String intermedioId,
  //   double cantidadTotalNecesariaIntermedio,
  // ) async {
  //   // cantidadTotalNecesariaIntermedio es la cantidad de este intermedio que se requiere
  //   // por el componente padre (sea un PlatoEvento, IntermedioEvento, u otro Intermedio)
  //   if (intermedioId.isEmpty || cantidadTotalNecesariaIntermedio <= 0) return;

  //   final intermedioBase = await _getIntermedioBase(intermedioId);
  //   if (intermedioBase == null) {
  //     debugPrint(
  //       "[ShoppingListService][WARN] Intermedio base ID $intermedioId no encontrado, omitiendo.",
  //     );
  //     return;
  //   }
  //   if (intermedioBase.cantidadEstandar <= 0) {
  //     debugPrint(
  //       "[ShoppingListService][WARN] Intermedio base ID ${intermedioBase.id} tiene cantidadEstandar <= 0, omitiendo para evitar división por cero.",
  //     );
  //     return;
  //   }

  //   debugPrint(
  //     "    Procesando Intermedio: ${intermedioBase.nombre} - Se necesitan: $cantidadTotalNecesariaIntermedio ${intermedioBase.unidad} (Base: ${intermedioBase.cantidadEstandar} ${intermedioBase.unidad})",
  //   );

  //   // --- Calcular Ratio del Intermedio ---
  //   // Este ratio se aplicará a las cantidades de los InsumosUtilizados de este intermedio.
  //   final double ratioIntermedio =
  //       cantidadTotalNecesariaIntermedio / intermedioBase.cantidadEstandar;
  //   debugPrint(
  //     "      Ratio Intermedio (Ri): $cantidadTotalNecesariaIntermedio / ${intermedioBase.cantidadEstandar} = $ratioIntermedio",
  //   );

  //   final List<InsumoUtilizado> insumosUtilizados = await _getInsumosUtilizados(
  //     intermedioId,
  //   );
  //   for (final iu in insumosUtilizados) {
  //     final insumoBaseDef = await _getInsumoBase(iu.insumoId);
  //     // Aplicar Ratio del Intermedio
  //     final cantidadNecesaria = iu.cantidad * ratioIntermedio;
  //     await _addInsumoQuantity(
  //       totals,
  //       iu.insumoId,
  //       insumoBaseDef?.unidad,
  //       cantidadNecesaria,
  //     );
  //     debugPrint(
  //       "        Insumo Utilizado: ${insumoBaseDef?.nombre ?? iu.insumoId} -> Cant: ${iu.cantidad} * Ri $ratioIntermedio = $cantidadNecesaria",
  //     );

  //     // Si este iu.insumoId fuera OTRO intermedio (anidamiento), llamarías a _processIntermedio de nuevo:
  //     // await _processIntermedio(totals, iu.insumoId, cantidadNecesaria);
  //     // PERO, `InsumoUtilizado` parece enlazar directamente a `Insumo`, no a otro Intermedio.
  //     // Si permites Intermedios dentro de Intermedios, la estructura del modelo `InsumoUtilizado` necesitaría
  //     // un campo tipo 'tipoComponente' (insumo o intermedio) y 'componenteId'.
  //   }
  // }

  // --- Métodos para obtener datos base (con caché simple) ---
  Future<Plato?> _getPlatoBase(String platoId) async {
    // ... (igual que antes)
    if (_platoCache.containsKey(platoId)) return _platoCache[platoId];
    try {
      final p = await platoRepo.obtener(platoId);
      _platoCache[platoId] = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  Future<Intermedio?> _getIntermedioBase(String intermedioId) async {
    // ... (igual que antes, usando obtener(id))
    if (_intermedioCache.containsKey(intermedioId))
      return _intermedioCache[intermedioId];
    try {
      final i = await intermedioRepo.obtener(intermedioId);
      _intermedioCache[intermedioId] = i;
      return i;
    } catch (_) {
      return null;
    }
  }

  Future<Insumo?> _getInsumoBase(String insumoId) async {
    if (_insumoCache.containsKey(insumoId)) return _insumoCache[insumoId];
    try {
      // Usar obtenerVarios si obtener(id) no existe en InsumoRepository
      // O añadir obtener(id) a InsumoRepository
      final insumos = await insumoRepo.obtenerVarios([
        insumoId,
      ]); // Asume obtenerVarios existe
      final insumo = insumos.isNotEmpty ? insumos.first : null;
      if (insumo != null) _insumoCache[insumoId] = insumo;
      return insumo;
    } catch (_) {
      return null;
    }
  }

  Future<List<InsumoRequerido>> _getInsumosRequeridos(String platoId) async {
    // ... (igual que antes)
    if (_insumoRequeridoCache.containsKey(platoId))
      return _insumoRequeridoCache[platoId]!;
    final lista = await insumoRequeridoRepo.obtenerPorPlato(platoId);
    _insumoRequeridoCache[platoId] = lista;
    return lista;
  }

  Future<List<IntermedioRequerido>> _getIntermediosRequeridos(
    String platoId,
  ) async {
    // ... (igual que antes)
    if (_intermedioRequeridoCache.containsKey(platoId))
      return _intermedioRequeridoCache[platoId]!;
    final lista = await intermedioRequeridoRepo.obtenerPorPlato(platoId);
    _intermedioRequeridoCache[platoId] = lista;
    return lista;
  }

  Future<List<InsumoUtilizado>> _getInsumosUtilizados(
    String intermedioId,
  ) async {
    // ... (igual que antes)
    if (_insumoUtilizadoCache.containsKey(intermedioId))
      return _insumoUtilizadoCache[intermedioId]!;
    final lista = await insumoUtilizadoRepo.obtenerPorIntermedio(intermedioId);
    _insumoUtilizadoCache[intermedioId] = lista;
    return lista;
  }

  // Convierte el mapa de totales por unidad a una lista plana de ShoppingListItem
  // Future<List<ShoppingListItem>> _mapTotalsToShoppingListItems(
  //   ShoppingListTotals totals,
  // ) async {
  //   if (totals.isEmpty) return [];

  //   final List<ShoppingListItem> flatList = [];
  //   final allInsumoIds = totals.keys.toList();

  //   // Obtener todos los objetos Insumo necesarios de una vez
  //   final insumos = await insumoRepo.obtenerVarios(allInsumoIds);
  //   final mapaInsumos = {
  //     for (var i in insumos)
  //       if (i.id != null) i.id!: i,
  //   };

  //   totals.forEach((insumoId, unidadesMap) {
  //     final insumoBase = mapaInsumos[insumoId];
  //     if (insumoBase != null) {
  //       unidadesMap.forEach((unidad, cantidad) {
  //         if (cantidad > 0) {
  //           // Solo añadir si la cantidad es positiva
  //           double costoDelItem = 0;
  //           if (insumoBase.precioUnitario > 0) {
  //             // Solo si hay precio
  //             costoDelItem = cantidad * insumoBase.precioUnitario;
  //           } else {
  //             debugPrint(
  //               "[ShoppingListService][WARN] Insumo ${insumoBase.nombre} no tiene precioUnitario, costo será 0.",
  //             );
  //           }
  //           flatList.add(
  //             ShoppingListItem(
  //               insumo: insumoBase,
  //               unidad: unidad, // La unidad normalizada
  //               cantidad: cantidad,
  //               costoItem: costoDelItem,
  //             ),
  //           );
  //         }
  //       });
  //     } else {
  //       debugPrint(
  //         "[ShoppingListService][WARN] No se encontró Insumo ID $insumoId al mapear resultado final.",
  //       );
  //       // Opcional: añadir un item 'fantasma' para indicar el problema
  //       // unidadesMap.forEach((unidad, cantidad) {
  //       //    if (cantidad > 0) flatList.add(ShoppingListItem(insumo: Insumo(id: insumoId, nombre: 'Insumo Faltante ($insumoId)', ...defaults...), unidad: unidad, cantidad: cantidad));
  //       // });
  //     }
  //   });
  //   return flatList;
  // }

  // Agrupa una lista plana de ShoppingListItem por proveedor
  Future<GroupedShoppingListResult> _groupShoppingListByProvider(
    List<ShoppingListItem> flatList,
  ) async {
    if (flatList.isEmpty) return {};

    // 1. Cargar todos los proveedores para mapeo (podría optimizarse si son muchos)
    final todosProveedores = await proveedorRepo.obtenerTodos();
    final mapaProveedores = {
      for (var p in todosProveedores)
        if (p.id != null) p.id!: p,
    };

    // 2. Agrupar usando collection.groupListsBy
    final groupedByProviderId = flatList.groupListsBy(
      (item) => item.insumo.proveedorId,
    );

    // 3. Crear mapa final con objeto Proveedor? como clave
    final GroupedShoppingListResult finalGroupedList = {};
    groupedByProviderId.forEach((proveedorId, items) {
      final proveedor =
          (proveedorId.isNotEmpty) ? mapaProveedores[proveedorId] : null;
      // Ordenar items dentro de cada grupo por nombre de insumo (opcional)
      items.sort((a, b) => a.insumo.nombre.compareTo(b.insumo.nombre));
      finalGroupedList[proveedor] = items;
    });

    // 4. Ordenar los grupos (opcional): proveedores por nombre, null al final
    final sortedKeys =
        finalGroupedList.keys.toList()..sort((a, b) {
          if (a == null && b == null) return 0;
          if (a == null) return 1; // null (sin proveedor) al final
          if (b == null) return -1;
          return a.nombre.compareTo(
            b.nombre,
          ); // Ordenar por nombre de proveedor
        });

    return {for (var k in sortedKeys) k: finalGroupedList[k]!};
  }

  // --- Método Principal (Adaptado) ---
  // Ahora devuelve la estructura detallada intermedia, el agrupamiento y filtrado se hacen después.
  Future<DetailedShoppingListTotals> generateDetailedTotals(
    List<String> eventoIds,
  ) async {
    debugPrint(
      "[ShoppingListService] Iniciando generación DETALLADA para ${eventoIds.length} eventos.",
    );
    _clearCaches();
    final DetailedShoppingListTotals detailedTotals =
        {}; // <--- Nuevo tipo de acumulador

    for (final eventoId in eventoIds) {
      debugPrint(
        "[ShoppingListService] Procesando evento detallado: $eventoId",
      );
      try {
        // Necesitamos el objeto Evento para saber si es facturable
        final Evento evento = await eventoRepo.obtener(
          eventoId,
        ); // Asegúrate que eventoRepo esté disponible
        await _processSingleEventIntoDetailedTotals(
          detailedTotals,
          evento,
        ); // <--- Pasa el evento completo
      } catch (e, st) {
        debugPrint(
          "[ShoppingListService][ERROR] Falló procesamiento detallado $eventoId: $e\n$st",
        );
      }
    }
    debugPrint(
      "[ShoppingListService] Totales detallados calculados: ${detailedTotals.length} insumos únicos.",
    );
    return detailedTotals;
  }

  // --- Procesar UN Evento (Recibe Evento completo) ---
  Future<void> _processSingleEventIntoDetailedTotals(
    DetailedShoppingListTotals totals,
    Evento evento,
  ) async {
    // <--- Recibe Evento
    final eventoId = evento.id!; // Asumir que tiene ID
    final bool esFacturable = evento.facturable; // Obtener el flag

    // 1. Cargar relaciones (igual que antes)
    final List<PlatoEvento> platosEvento = await platoEventoRepo
        .obtenerPorEvento(eventoId);
    final List<IntermedioEvento> intermediosEvento = await intermedioEventoRepo
        .obtenerPorEvento(eventoId);
    final List<InsumoEvento> insumosEvento = await insumoEventoRepo
        .obtenerPorEvento(eventoId);

    // 2. Procesar Insumos Directos (Pasar esFacturable)
    for (final insumoEv in insumosEvento) {
      await _addDetailedInsumoQuantity(
        totals,
        insumoEv.insumoId,
        insumoEv.unidad,
        insumoEv.cantidad,
        esFacturable,
      ); // <--- Pasa esFacturable
    }

    // 3. Procesar Intermedios Directos (Pasar esFacturable)
    for (final intermedioEv in intermediosEvento) {
      await _processIntermedioDetailed(
        totals,
        intermedioEv.intermedioId,
        intermedioEv.cantidad.toDouble(),
        esFacturable,
      ); // <--- Pasa esFacturable
    }

    // 4. Procesar Platos (Pasar esFacturable)
    for (final platoEv in platosEvento) {
      await _processPlatoEventoDetailed(
        totals,
        platoEv,
        esFacturable,
      ); // <--- Pasa esFacturable
    }
  }

  // --- Añadir Cantidad Detallada ---
  Future<void> _addDetailedInsumoQuantity(
    DetailedShoppingListTotals totals,
    String insumoId,
    String? unidad,
    double quantity,
    bool esFacturable,
  ) async {
    if (insumoId.isEmpty || quantity <= 0) return;
    String unidadNormalizada = unidad?.trim().toLowerCase() ?? 'unidad';
    if (unidadNormalizada.isEmpty) unidadNormalizada = 'unidad';

    // Asegurar mapa para insumoId
    totals.putIfAbsent(insumoId, () => {});
    // Asegurar QuantityBreakdown para la unidad
    final breakdown = totals[insumoId]!.putIfAbsent(
      unidadNormalizada,
      () => QuantityBreakdown(),
    );

    // Sumar a la categoría correspondiente
    if (esFacturable) {
      breakdown.facturable += quantity;
    } else {
      breakdown.noFacturable += quantity;
    }
    // debugPrint(...); // Log opcional
  }

  Future<void> _processPlatoEventoDetailed(
    DetailedShoppingListTotals totals,
    PlatoEvento platoEvento,
    bool esFacturable,
  ) async {
    // ... (Obtener platoBase, ratioPlato, etc., igual que antes) ...
    final platoBase = await _getPlatoBase(platoEvento.platoId);
    if (platoBase == null || platoBase.porcionesMinimas <= 0) return;
    final double cantidadPlatoEvento = platoEvento.cantidad.toDouble();
    if (cantidadPlatoEvento <= 0) return;
    final double ratioPlato = cantidadPlatoEvento / platoBase.porcionesMinimas;
    final Set<String> insumosRemovidos = Set.from(
      platoEvento.insumosRemovidos ?? [],
    );
    final Set<String> intermediosRemovidos = Set.from(
      platoEvento.intermediosRemovidos ?? [],
    );

    debugPrint(
      "[ShoppingListService] Procesando Plato (Facturable: $esFacturable): ${platoBase.nombre} x ${platoEvento.cantidad}",
    );

    // Insumos Requeridos Base
    final insumosBaseReq = await _getInsumosRequeridos(platoBase.id!);
    for (final irBase in insumosBaseReq) {
      if (!insumosRemovidos.contains(irBase.insumoId)) {
        final insumoBase = await _getInsumoBase(irBase.insumoId);
        await _addDetailedInsumoQuantity(
          totals,
          irBase.insumoId,
          insumoBase?.unidad,
          irBase.cantidad * ratioPlato,
          esFacturable,
        ); // <-- Pasar esFacturable
      }
    }
    // Insumos Extra
    for (final itemExtra in platoEvento.insumosExtra ?? []) {
      final insumoBase = await _getInsumoBase(itemExtra.id);
      await _addDetailedInsumoQuantity(
        totals,
        itemExtra.id,
        insumoBase?.unidad,
        itemExtra.cantidad * ratioPlato,
        esFacturable,
      ); // <-- Pasar esFacturable
    }
    // Intermedios Requeridos Base
    final intermediosBaseReq = await _getIntermediosRequeridos(platoBase.id!);
    for (final irBase in intermediosBaseReq) {
      if (!intermediosRemovidos.contains(irBase.intermedioId)) {
        await _processIntermedioDetailed(
          totals,
          irBase.intermedioId,
          irBase.cantidad * ratioPlato,
          esFacturable,
        ); // <-- Pasar esFacturable
      }
    }
    // Intermedios Extra
    for (final itemExtra in platoEvento.intermediosExtra ?? []) {
      await _processIntermedioDetailed(
        totals,
        itemExtra.id,
        itemExtra.cantidad * ratioPlato,
        esFacturable,
      ); // <-- Pasar esFacturable
    }
  }

  Future<void> _processIntermedioDetailed(
    DetailedShoppingListTotals totals,
    String intermedioId,
    double cantidadTotalNecesariaIntermedio,
    bool esFacturable,
  ) async {
    // ... (Obtener intermedioBase, ratioIntermedio, etc., igual que antes) ...
    if (intermedioId.isEmpty || cantidadTotalNecesariaIntermedio <= 0) return;
    final intermedioBase = await _getIntermedioBase(intermedioId);
    if (intermedioBase == null || intermedioBase.cantidadEstandar <= 0) return;
    final double ratioIntermedio =
        cantidadTotalNecesariaIntermedio / intermedioBase.cantidadEstandar;
    debugPrint(
      "    Procesando Intermedio (Facturable: $esFacturable): ${intermedioBase.nombre} - Necesario: $cantidadTotalNecesariaIntermedio, Ratio: $ratioIntermedio",
    );

    final insumosUtilizados = await _getInsumosUtilizados(intermedioId);
    for (final iu in insumosUtilizados) {
      final insumoBase = await _getInsumoBase(iu.insumoId);
      await _addDetailedInsumoQuantity(
        totals,
        iu.insumoId,
        insumoBase?.unidad,
        iu.cantidad * ratioIntermedio,
        esFacturable,
      ); // <-- Pasar esFacturable
    }
  }

  // --- Modificar Mapeo Final y Agrupación ---
  // Ahora mapeamos desde DetailedShoppingListTotals

  // Crea la lista plana, pero ahora puede tener items separados por facturable/no facturable si quieres
  Future<List<ShoppingListItem>> _mapDetailedTotalsToShoppingListItems(
    DetailedShoppingListTotals detailedTotals, {
    bool separateByFacturable = false, // Flag para decidir si separar
  }) async {
    if (detailedTotals.isEmpty) return [];
    final List<ShoppingListItem> flatList = [];
    final allInsumoIds = detailedTotals.keys.toList();
    final insumos = await insumoRepo.obtenerVarios(allInsumoIds);
    final mapaInsumos = {
      for (var i in insumos)
        if (i.id != null) i.id!: i,
    };

    detailedTotals.forEach((insumoId, unidadesMap) {
      final insumoBase = mapaInsumos[insumoId];
      if (insumoBase != null) {
        unidadesMap.forEach((unidad, breakdown) {
          // Calcular costo base (asumiendo unidad consistente con precio)
          double precioUnit =
              insumoBase.precioUnitario > 0 ? insumoBase.precioUnitario : 0;

          if (separateByFacturable) {
            // Crear dos items separados si hay cantidad en ambos
            if (breakdown.facturable > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: breakdown.facturable,
                  costoItem: breakdown.facturable * precioUnit,
                  esFacturable: true,
                ),
              );
            }
            if (breakdown.noFacturable > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: breakdown.noFacturable,
                  costoItem: breakdown.noFacturable * precioUnit,
                  esFacturable: false,
                ),
              );
            }
          } else {
            // Crear un solo item con la cantidad total
            final double cantidadTotal = breakdown.total;
            if (cantidadTotal > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: cantidadTotal,
                  costoItem: cantidadTotal * precioUnit,
                  esFacturable: null,
                ),
              );
            }
          }
        });
      } else {
        /* warning insumo faltante */
      }
    });
    return flatList;
  }

  // --- Nuevos Métodos Públicos Expuestos ---

  /// Genera lista de compras detallada por facturabilidad (estructura interna)
  Future<DetailedShoppingListTotals> getDetailedShoppingTotals(
    List<String> eventoIds,
  ) async {
    return await generateDetailedTotals(eventoIds);
  }

  /// Genera la lista final agrupada, combinando facturables/no facturables
  Future<GroupedShoppingListResult> getCombinedGroupedShoppingList(
    List<String> eventoIds,
  ) async {
    final detailedTotals = await generateDetailedTotals(eventoIds);
    final flatList = await _mapDetailedTotalsToShoppingListItems(
      detailedTotals,
      separateByFacturable: false,
    );
    return await _groupShoppingListByProvider(flatList);
  }

  /// Genera la lista final agrupada, separando items facturables/no facturables
  Future<GroupedShoppingListResult> getSeparatedGroupedShoppingList(
    List<String> eventoIds,
  ) async {
    final detailedTotals = await generateDetailedTotals(eventoIds);
    // Nota: Si separas, un mismo insumo/unidad puede aparecer dos veces en la lista plana
    // si tiene cantidad facturable Y no facturable. La agrupación por proveedor las juntará
    // bajo el mismo proveedor, pero seguirán siendo items separados en la lista de ese proveedor.
    // Podrías necesitar modificar ShoppingListItem para incluir el flag 'esFacturable'.
    final flatList = await _mapDetailedTotalsToShoppingListItems(
      detailedTotals,
      separateByFacturable: true,
    );
    return await _groupShoppingListByProvider(flatList);
  }
} // Fin ShoppingListServiceu
