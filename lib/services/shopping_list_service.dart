// services/shopping_list_service.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

// Modelos de datos
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
import 'package:golo_app/models/proveedor.dart';

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
import 'package:golo_app/repositories/proveedor_repository.dart';

/// Estructura de datos para acumular cantidades por unidad de medida.
/// 
/// Mapea un ID de insumo a un mapa de unidades y sus cantidades correspondientes.
typedef ShoppingListTotals = Map<String, Map<String, double>>;

/// Representa un ítem individual en la lista de compras final.
///
/// Contiene toda la información necesaria para mostrar y procesar un ítem
/// en la lista de compras, incluyendo su cantidad, unidad de medida y costo.
/// Representa un ítem individual en la lista de compras final.
///
/// Contiene toda la información necesaria para mostrar y procesar un ítem
/// en la lista de compras, incluyendo su cantidad, unidad de medida y costo.
class ShoppingListItem {
  /// El insumo asociado a este ítem de la lista de compras.
  final Insumo insumo;
  
  /// La unidad de medida en la que se expresa la cantidad.
  final String unidad;
  
  /// La cantidad necesaria del insumo.
  final double cantidad;
  
  /// El costo total calculado para esta cantidad del insumo.
  final double costoItem;
  
  /// Indica si el ítem es facturable (true), no facturable (false), o combinado (null).
  final bool? esFacturable;

  /// Crea una nueva instancia de [ShoppingListItem].
  const ShoppingListItem({
    required this.insumo,
    required this.unidad,
    required this.cantidad,
    required this.costoItem,
    this.esFacturable,
  });

  @override
  String toString() =>
      '${insumo.nombre} - ${cantidad.toStringAsFixed(2)} $unidad (Costo: \$${costoItem.toStringAsFixed(2)})';
}

/// Resultado de agrupar ítems de la lista de compras por proveedor.
///
/// La clave es un [Proveedor] o `null` para ítems sin proveedor asignado.
/// El valor es la lista de [ShoppingListItem] asociados a ese proveedor.
typedef GroupedShoppingListResult = Map<Proveedor?, List<ShoppingListItem>>;

/// Desglose de cantidades por tipo de facturabilidad.
///
/// Mantiene un registro separado de cantidades facturables y no facturables
/// para un mismo ítem, permitiendo un cálculo detallado de costos.
class QuantityBreakdown {
  /// Cantidad facturable del ítem.
  double facturable = 0.0;
  
  /// Cantidad no facturable del ítem.
  double noFacturable = 0.0;

  /// Obtiene la cantidad total (facturable + no facturable).
  double get total => facturable + noFacturable;
}

/// Estructura de datos detallada para la lista de compras.
///
/// Organiza los ítems por ID de insumo y unidad de medida, manteniendo
/// un desglose de cantidades facturables y no facturables.
/// 
/// Estructura: `Map<insumoId, Map<unidad, QuantityBreakdown>>`
typedef DetailedShoppingListTotals = Map<String, Map<String, QuantityBreakdown>>;

/// Servicio para la generación y gestión de listas de compras.
///
/// Este servicio se encarga de procesar eventos, platos, intermedios e insumos
/// para generar listas de compras detalladas, con soporte para agrupación por
/// proveedor y separación por facturabilidad.
///
/// Utiliza un sistema de caché para optimizar las consultas repetitivas a la base de datos.
class ShoppingListService {
  // Repositorios inyectados para acceder a los datos
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

  /// Crea una nueva instancia del servicio de lista de compras.
  ///
  /// Requiere todos los repositorios necesarios para acceder a los datos.
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
  
  /// Cache de platos por ID para evitar consultas repetitivas
  Map<String, Plato> _platoCache = {};
  
  /// Cache de intermedios por ID para evitar consultas repetitivas
  Map<String, Intermedio> _intermedioCache = {};
  
  /// Cache de insumos por ID para evitar consultas repetitivas
  Map<String, Insumo> _insumoCache = {};
  
  /// Cache de insumos requeridos por ID de plato
  Map<String, List<InsumoRequerido>> _insumoRequeridoCache = {};
  
  /// Cache de intermedios requeridos por ID de plato
  Map<String, List<IntermedioRequerido>> _intermedioRequeridoCache = {};
  
  /// Cache de insumos utilizados por ID de intermedio
  Map<String, List<InsumoUtilizado>> _insumoUtilizadoCache = {};





  // --- Métodos Helper Internos ---

  /// Limpia todas las cachés internas del servicio.
  ///
  /// Este método debe llamarse cuando se necesite forzar la actualización
  /// de datos desde la base de datos, por ejemplo, después de realizar cambios
  /// que afecten a los datos en caché.
  void _clearCaches() {
    _platoCache = {};
    _intermedioCache = {};
    _insumoCache = {};
    _insumoRequeridoCache = {};
    _intermedioRequeridoCache = {};
    _insumoUtilizadoCache = {};
    debugPrint("[ShoppingListService] Cachés limpiadas.");
  }








  // --- Métodos para obtener datos base (con caché simple) ---
  
  /// Obtiene un plato por su ID, utilizando la caché si está disponible.
  ///
  /// [platoId] El ID del plato a obtener.
  /// Retorna el [Plato] correspondiente o `null` si no se encuentra.
  Future<Plato?> _getPlatoBase(String platoId) async {
    if (_platoCache.containsKey(platoId)) return _platoCache[platoId];
    try {
      final p = await platoRepo.obtener(platoId);
      _platoCache[platoId] = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene un intermedio por su ID, utilizando la caché si está disponible.
  ///
  /// [intermedioId] El ID del intermedio a obtener.
  /// Retorna el [Intermedio] correspondiente o `null` si no se encuentra.
  Future<Intermedio?> _getIntermedioBase(String intermedioId) async {
    if (_intermedioCache.containsKey(intermedioId)) {
      return _intermedioCache[intermedioId];
    }
    try {
      final i = await intermedioRepo.obtener(intermedioId);
      _intermedioCache[intermedioId] = i;
      return i;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene un insumo por su ID, utilizando la caché si está disponible.
  ///
  /// [insumoId] El ID del insumo a obtener.
  /// Retorna el [Insumo] correspondiente o `null` si no se encuentra.
  Future<Insumo?> _getInsumoBase(String insumoId) async {
    if (_insumoCache.containsKey(insumoId)) return _insumoCache[insumoId];
    try {
      // Usar obtenerVarios para optimizar la carga de múltiples insumos
      final insumos = await insumoRepo.obtenerVarios([insumoId]);
      final insumo = insumos.isNotEmpty ? insumos.first : null;
      if (insumo != null) _insumoCache[insumoId] = insumo;
      return insumo;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los insumos requeridos para un plato específico, con soporte de caché.
  ///
  /// [platoId] El ID del plato del que se requieren los insumos.
  /// Retorna una lista de [InsumoRequerido] para el plato especificado.
  Future<List<InsumoRequerido>> _getInsumosRequeridos(String platoId) async {
    if (_insumoRequeridoCache.containsKey(platoId)) {
      return _insumoRequeridoCache[platoId]!;
    }
    final lista = await insumoRequeridoRepo.obtenerPorPlato(platoId);
    _insumoRequeridoCache[platoId] = lista;
    return lista;
  }

  /// Obtiene los intermedios requeridos para un plato específico, con soporte de caché.
  ///
  /// [platoId] El ID del plato del que se requieren los intermedios.
  /// Retorna una lista de [IntermedioRequerido] para el plato especificado.
  Future<List<IntermedioRequerido>> _getIntermediosRequeridos(
    String platoId,
  ) async {
    if (_intermedioRequeridoCache.containsKey(platoId)) {
      return _intermedioRequeridoCache[platoId]!;
    }
    final lista = await intermedioRequeridoRepo.obtenerPorPlato(platoId);
    _intermedioRequeridoCache[platoId] = lista;
    return lista;
  }

  /// Obtiene los insumos utilizados en un intermedio específico, con soporte de caché.
  ///
  /// [intermedioId] El ID del intermedio del que se requieren los insumos utilizados.
  /// Retorna una lista de [InsumoUtilizado] para el intermedio especificado.
  Future<List<InsumoUtilizado>> _getInsumosUtilizados(
    String intermedioId,
  ) async {
    if (_insumoUtilizadoCache.containsKey(intermedioId)) {
      return _insumoUtilizadoCache[intermedioId]!;
    }
    final lista = await insumoUtilizadoRepo.obtenerPorIntermedio(intermedioId);
    _insumoUtilizadoCache[intermedioId] = lista;
    return lista;
  }



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

  /// Genera los totales detallados de la lista de compras para los eventos especificados.
  ///
  /// Este es el método principal que inicia el proceso de generación de la lista de compras.
  /// Procesa todos los eventos, platos, intermedios e insumos para calcular las cantidades
  /// totales necesarias, manteniendo un desglose por facturabilidad.
  ///
  /// [eventoIds] Lista de IDs de eventos a incluir en la lista de compras.
  /// Retorna un [Future] que se completa con un [DetailedShoppingListTotals] que contiene
  /// los totales detallados de todos los insumos requeridos.
  Future<DetailedShoppingListTotals> generateDetailedTotals(
    List<String> eventoIds,
  ) async {
    debugPrint(
      "[ShoppingListService] Iniciando generación DETALLADA para ${eventoIds.length} eventos.",
    );
    
    // Limpiar cachés para asegurar datos actualizados
    _clearCaches();
    
    // Estructura para acumular los totales detallados
    final DetailedShoppingListTotals detailedTotals = {};

    // Procesar cada evento individualmente
    for (final eventoId in eventoIds) {
      debugPrint(
        "[ShoppingListService] Procesando evento detallado: $eventoId",
      );
      
      try {
        // Obtener el evento completo para acceder a sus propiedades (como facturable)
        final Evento evento = await eventoRepo.obtener(eventoId);
        
        // Procesar el evento y acumular sus insumos en detailedTotals
        await _processSingleEventIntoDetailedTotals(detailedTotals, evento);
      } catch (e, st) {
        // Registrar errores pero continuar con los demás eventos
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

  /// Procesa un único evento y acumula sus insumos en la estructura de totales.
  ///
  /// Este método es llamado por [generateDetailedTotals] para cada evento que se
  /// incluirá en la lista de compras. Se encarga de procesar los insumos directos,
  /// intermedios y platos asociados al evento, manteniendo un registro de si son
  /// facturables o no según la configuración del evento.
  ///
  /// [totals] La estructura donde se acumularán los totales.
  /// [evento] El evento que se está procesando.
  Future<void> _processSingleEventIntoDetailedTotals(
    DetailedShoppingListTotals totals,
    Evento evento,
  ) async {
    if (evento.id == null) {
      debugPrint("[ShoppingListService] Intento de procesar evento sin ID");
      return;
    }
    
    final eventoId = evento.id!;
    final bool esFacturable = evento.facturable;

    // 1. Cargar todas las relaciones del evento
    final List<PlatoEvento> platosEvento = await platoEventoRepo.obtenerPorEvento(eventoId);
    final List<IntermedioEvento> intermediosEvento = await intermedioEventoRepo.obtenerPorEvento(eventoId);
    final List<InsumoEvento> insumosEvento = await insumoEventoRepo.obtenerPorEvento(eventoId);

    // 2. Procesar Insumos Directos
    for (final insumoEv in insumosEvento) {
      await _addDetailedInsumoQuantity(
        totals,
        insumoEv.insumoId,
        insumoEv.unidad,
        insumoEv.cantidad,
        esFacturable,
      );
    }

    // 3. Procesar Intermedios Directos
    for (final intermedioEv in intermediosEvento) {
      await _processIntermedioDetailed(
        totals,
        intermedioEv.intermedioId,
        intermedioEv.cantidad.toDouble(),
        esFacturable,
      );
    }

    // 4. Procesar Platos (que a su vez pueden contener insumos e intermedios)
    for (final platoEv in platosEvento) {
      await _processPlatoEventoDetailed(totals, platoEv, esFacturable);
    }
  }

  /// Añade una cantidad de insumo a los totales, manteniendo el desglose por facturabilidad.
  ///
  /// Este método se encarga de acumular las cantidades de cada insumo en la estructura
  /// de totales, normalizando las unidades de medida y separando las cantidades
  /// según sean facturables o no.
  ///
  /// [totals] La estructura donde se acumularán los totales.
  /// [insumoId] El ID del insumo a agregar.
  /// [unidad] La unidad de medida del insumo (se normalizará).
  /// [quantity] La cantidad a agregar.
  /// [esFacturable] Indica si la cantidad es facturable o no.
  Future<void> _addDetailedInsumoQuantity(
    DetailedShoppingListTotals totals,
    String insumoId,
    String? unidad,
    double quantity,
    bool esFacturable,
  ) async {
    // Validar parámetros
    if (insumoId.isEmpty || quantity <= 0) return;
    
    // Normalizar la unidad de medida
    String unidadNormalizada = unidad?.trim().toLowerCase() ?? 'unidad';
    if (unidadNormalizada.isEmpty) unidadNormalizada = 'unidad';

    // Asegurar que exista el mapa para este insumo
    totals.putIfAbsent(insumoId, () => {});
    
    // Asegurar que exista el desglose para esta unidad
    final breakdown = totals[insumoId]!.putIfAbsent(
      unidadNormalizada,
      () => QuantityBreakdown(),
    );

    // Acumular la cantidad en la categoría correspondiente (facturable o no)
    if (esFacturable) {
      breakdown.facturable += quantity;
    } else {
      breakdown.noFacturable += quantity;
    }
    
    // Opcional: Descomentar para depuración
    // debugPrint('Añadido $quantity $unidadNormalizada de insumo $insumoId (facturable: $esFacturable)');
  }

  /// Procesa un plato de un evento, incluyendo todos sus insumos e intermedios.
  ///
  /// Este método se encarga de procesar un plato asociado a un evento, calculando
  /// las cantidades necesarias de cada insumo e intermedio según la cantidad de
  /// porciones del evento y la configuración del plato.
  ///
  /// [totals] La estructura donde se acumularán los totales.
  /// [platoEvento] El plato del evento a procesar.
  /// [esFacturable] Indica si los insumos de este plato son facturables.
  Future<void> _processPlatoEventoDetailed(
    DetailedShoppingListTotals totals,
    PlatoEvento platoEvento,
    bool esFacturable,
  ) async {
    // Obtener la definición base del plato
    final platoBase = await _getPlatoBase(platoEvento.platoId);
    
    // Validar que el plato existe y tiene una configuración válida
    if (platoBase == null || platoBase.porcionesMinimas <= 0) {
      debugPrint('[ShoppingListService] Plato no encontrado o sin porciones válidas: ${platoEvento.platoId}');
      return;
    }
    
    // Calcular cantidades y ratios
    final double cantidadPlatoEvento = platoEvento.cantidad.toDouble();
    if (cantidadPlatoEvento <= 0) return;
    
    // Calcular el ratio de escalado basado en las porciones del evento vs. el estándar del plato
    final double ratioPlato = cantidadPlatoEvento / platoBase.porcionesMinimas;
    
    // Obtener listas de insumos e intermedios removidos (si los hay)
    final Set<String> insumosRemovidos = Set.from(platoEvento.insumosRemovidos ?? []);
    final Set<String> intermediosRemovidos = Set.from(platoEvento.intermediosRemovidos ?? []);

    debugPrint(
      "[ShoppingListService] Procesando Plato (Facturable: $esFacturable): ${platoBase.nombre} x ${platoEvento.cantidad}",
    );

    // 1. Procesar insumos base del plato (no removidos)
    final insumosBaseReq = await _getInsumosRequeridos(platoBase.id!);
    for (final irBase in insumosBaseReq) {
      if (!insumosRemovidos.contains(irBase.insumoId)) {
        final insumoBase = await _getInsumoBase(irBase.insumoId);
        if (insumoBase != null) {
          await _addDetailedInsumoQuantity(
            totals,
            irBase.insumoId,
            insumoBase.unidad,
            irBase.cantidad * ratioPlato,
            esFacturable,
          );
        }
      }
    }
    
    // 2. Procesar insumos extra agregados al plato
    for (final itemExtra in platoEvento.insumosExtra ?? []) {
      final insumoBase = await _getInsumoBase(itemExtra.id);
      if (insumoBase != null) {
        await _addDetailedInsumoQuantity(
          totals,
          itemExtra.id,
          insumoBase.unidad,
          itemExtra.cantidad * ratioPlato,
          esFacturable,
        );
      }
    }
    
    // 3. Procesar intermedios base del plato (no removidos)
    final intermediosBaseReq = await _getIntermediosRequeridos(platoBase.id!);
    for (final irBase in intermediosBaseReq) {
      if (!intermediosRemovidos.contains(irBase.intermedioId)) {
        await _processIntermedioDetailed(
          totals,
          irBase.intermedioId,
          irBase.cantidad * ratioPlato,
          esFacturable,
        );
      }
    }
    
    // 4. Procesar intermedios extra agregados al plato
    for (final itemExtra in platoEvento.intermediosExtra ?? []) {
      await _processIntermedioDetailed(
        totals,
        itemExtra.id,
        itemExtra.cantidad * ratioPlato,
        esFacturable,
      );
    }
  }

  /// Procesa un intermedio, incluyendo todos los insumos que lo componen.
  ///
  /// Este método se encarga de descomponer un intermedio en sus insumos constituyentes,
  /// calculando las cantidades necesarias de cada insumo en función de la cantidad
  /// total requerida del intermedio.
  ///
  /// [totals] La estructura donde se acumularán los totales.
  /// [intermedioId] El ID del intermedio a procesar.
  /// [cantidadTotalNecesariaIntermedio] La cantidad total necesaria de este intermedio.
  /// [esFacturable] Indica si los insumos de este intermedio son facturables.
  Future<void> _processIntermedioDetailed(
    DetailedShoppingListTotals totals,
    String intermedioId,
    double cantidadTotalNecesariaIntermedio,
    bool esFacturable,
  ) async {
    // Validar parámetros
    if (cantidadTotalNecesariaIntermedio <= 0) return;

    // Obtener la definición base del intermedio (con caché)
    final intermedio = await _getIntermedioBase(intermedioId);
    if (intermedio == null) {
      debugPrint(
        "[ShoppingListService][WARN] Intermedio no encontrado: $intermedioId");
      return;
    }

    debugPrint(
      "[ShoppingListService] Procesando Intermedio (Facturable: $esFacturable): ${intermedio.nombre} x $cantidadTotalNecesariaIntermedio",
    );

    // Obtener los insumos utilizados en este intermedio (con caché)
    final insumosUtilizados = await _getInsumosUtilizados(intermedioId);

    // Calcular el factor de conversión basado en la cantidad estándar del intermedio
    final double cantidadBaseIntermedio = intermedio.cantidadEstandar;
    final double factorConversion = cantidadTotalNecesariaIntermedio /
        (cantidadBaseIntermedio > 0 ? cantidadBaseIntermedio : 1);

    // Procesar cada insumo utilizado en el intermedio
    for (final insumoUsado in insumosUtilizados) {
      final insumo = await _getInsumoBase(insumoUsado.insumoId);
      if (insumo != null) {
        // Calcular la cantidad necesaria de este insumo para la cantidad total del intermedio
        final double cantidadNecesaria = insumoUsado.cantidad * factorConversion;

        // Agregar al total de insumos (con su facturabilidad)
        await _addDetailedInsumoQuantity(
          totals,
          insumoUsado.insumoId,
          insumo.unidad,
          cantidadNecesaria,
          esFacturable,
        );
      }
    }
  }

  /// Convierte los totales detallados en una lista de ítems de compra.
  ///
  /// Este método transforma la estructura interna de totales detallados en una
  /// lista plana de [ShoppingListItem], con opción de separar los ítems
  /// según sean facturables o no.
  ///
  /// [detailedTotals] Los totales detallados a convertir.
  /// [separateByFacturable] Si es `true`, genera ítems separados para cantidades
  ///                       facturables y no facturables. Si es `false`, combina
  ///                       ambas cantidades en un solo ítem.
  ///
  /// Retorna una lista de [ShoppingListItem] lista para mostrar o exportar.
  Future<List<ShoppingListItem>> _mapDetailedTotalsToShoppingListItems(
    DetailedShoppingListTotals detailedTotals, {
    bool separateByFacturable = false,
  }) async {
    if (detailedTotals.isEmpty) return [];
    
    final List<ShoppingListItem> flatList = [];
    final allInsumoIds = detailedTotals.keys.toList();
    
    // Obtener todos los insumos necesarios en una sola consulta
    final insumos = await insumoRepo.obtenerVarios(allInsumoIds);
    final mapaInsumos = {
      for (var i in insumos)
        if (i.id != null) i.id!: i,
    };

    // Procesar cada insumo en los totales detallados
    detailedTotals.forEach((insumoId, unidadesMap) {
      final insumoBase = mapaInsumos[insumoId];
      if (insumoBase != null) {
        unidadesMap.forEach((unidad, breakdown) {
          // Obtener el precio unitario del insumo (o 0 si no está definido)
          double precioUnit = insumoBase.precioUnitario > 0 
              ? insumoBase.precioUnitario 
              : 0;

          if (separateByFacturable) {
            // --- Opción 1: Separar en ítems distintos para facturable y no facturable ---
            
            // Crear ítem facturable si hay cantidad
            if (breakdown.facturable > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: breakdown.facturable,
                  costoItem: breakdown.facturable * precioUnit,
                  esFacturable: true, // Ítem marcado como facturable
                ),
              );
            }
            
            // Crear ítem no facturable si hay cantidad
            if (breakdown.noFacturable > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: breakdown.noFacturable,
                  costoItem: breakdown.noFacturable * precioUnit,
                  esFacturable: false, // Ítem marcado como no facturable
                ),
              );
            }
          } else {
            // --- Opción 2: Un solo ítem con cantidades combinadas ---
            final double cantidadTotal = breakdown.total;
            
            // Solo agregar si hay cantidad total
            if (cantidadTotal > 0) {
              flatList.add(
                ShoppingListItem(
                  insumo: insumoBase,
                  unidad: unidad,
                  cantidad: cantidadTotal,
                  costoItem: cantidadTotal * precioUnit,
                  // No establecemos esFacturable ya que está combinado
                ),
              );
            }
          }
        });
      } else {
        debugPrint(
          "[ShoppingListService][WARN] No se encontró Insumo ID $insumoId al mapear resultado final.",
        );
      }
    });
    
    return flatList;
  }

  // --- Nuevos Métodos Públicos Expuestos ---

  /// Genera los totales detallados de la lista de compras para los eventos especificados.
  ///
  /// Este método es el punto de entrada principal para obtener los totales detallados
  /// de la lista de compras. Procesa todos los eventos, platos, intermedios e insumos
  /// para calcular las cantidades totales necesarias, manteniendo un desglose por facturabilidad.
  ///
  /// [eventoIds] Lista de IDs de eventos a incluir en la lista de compras.
  /// Retorna un [Future] que se completa con un [DetailedShoppingListTotals] que contiene
  /// los totales detallados de todos los insumos requeridos.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final totals = await shoppingListService.getDetailedShoppingTotals(['evento1', 'evento2']);
  /// ```
  Future<DetailedShoppingListTotals> getDetailedShoppingTotals(
    List<String> eventoIds,
  ) async {
    if (eventoIds.isEmpty) {
      debugPrint('[ShoppingListService] Se solicitó lista de compras sin eventos');
      return {};
    }
    return generateDetailedTotals(eventoIds);
  }

  /// Genera una lista de compras agrupada por proveedor, combinando cantidades facturables y no facturables.
  ///
  /// Este método es útil cuando se necesita una vista consolidada de la lista de compras,
  /// donde las cantidades de cada insumo se combinan sin importar su facturabilidad.
  ///
  /// [eventoIds] Lista de IDs de eventos a incluir en la lista de compras.
  /// Retorna un [Future] que se completa con un [GroupedShoppingListResult] que contiene
  /// los ítems de compra agrupados por proveedor.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final resultado = await shoppingListService.getCombinedGroupedShoppingList(['evento1']);
  /// // resultado.groupedItems contendrá los ítems agrupados por proveedor
  /// ```
  Future<GroupedShoppingListResult> getCombinedGroupedShoppingList(
    List<String> eventoIds,
  ) async {
    if (eventoIds.isEmpty) {
      debugPrint('[ShoppingListService] Se solicitó lista agrupada sin eventos');
      return GroupedShoppingListResult();
    }
    
    // Obtener los totales detallados
    final detailedTotals = await generateDetailedTotals(eventoIds);
    
    // Convertir a lista plana sin separar por facturabilidad
    final flatList = await _mapDetailedTotalsToShoppingListItems(
      detailedTotals,
      separateByFacturable: false, // Combinar facturables y no facturables
    );
    
    // Agrupar y ordenar los resultados
    return _groupShoppingListByProvider(flatList);
  }

  /// Genera la lista final agrupada, separando items facturables/no facturables
  Future<GroupedShoppingListResult> getSeparatedGroupedShoppingList(
    List<String> eventoIds,
  ) async {
    if (eventoIds.isEmpty) {
      debugPrint('[ShoppingListService] Se solicitó lista agrupada sin eventos');
      return GroupedShoppingListResult();
    }
    
    // Obtener los totales detallados
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
