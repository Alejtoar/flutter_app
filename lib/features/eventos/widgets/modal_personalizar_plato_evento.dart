// modal_personalizar_plato_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/insumo_requerido.dart'; // Relación Plato -> Insumo
import 'package:golo_app/models/intermedio_requerido.dart'; // Relación Plato -> Intermedio
import 'package:golo_app/models/item_extra.dart'; // Modelo para items extra
import 'package:golo_app/models/insumo.dart'; // Modelo base Insumo
import 'package:golo_app/models/intermedio.dart'; // Modelo base Intermedio
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
// Importar los modales para buscar/agregar extras si los tienes separados
// o implementar la lógica de búsqueda aquí.

class ModalPersonalizarPlatoEvento extends StatefulWidget {
  final PlatoEvento platoEventoOriginal; // El PlatoEvento actual a modificar
  final Plato platoBase; // El Plato original del catálogo
  // Las relaciones originales del Plato base
  final List<InsumoRequerido> insumosBaseRequeridos;
  final List<IntermedioRequerido> intermediosBaseRequeridos;

  const ModalPersonalizarPlatoEvento({
    Key? key,
    required this.platoEventoOriginal,
    required this.platoBase,
    required this.insumosBaseRequeridos,
    required this.intermediosBaseRequeridos,
  }) : super(key: key);

  @override
  State<ModalPersonalizarPlatoEvento> createState() =>
      _ModalPersonalizarPlatoEventoState();
}

class _ModalPersonalizarPlatoEventoState
    extends State<ModalPersonalizarPlatoEvento> {
  late TextEditingController _nombrePersonalizadoController;

  // Estado local para los cambios
  late Set<String> _insumosRemovidosIds; // Usar Set para eficiencia
  late List<ItemExtra> _insumosExtra;
  late Set<String> _intermediosRemovidosIds;
  late List<ItemExtra> _intermediosExtra;

  // Para búsqueda de extras
  final TextEditingController _buscarInsumoController = TextEditingController();
  final TextEditingController _buscarIntermedioController =
      TextEditingController();
  List<Insumo> _insumosEncontrados = [];
  List<Intermedio> _intermediosEncontrados = [];

  @override
  void initState() {
    super.initState();
    // Inicializar estado local con los valores actuales del PlatoEvento
    final pe = widget.platoEventoOriginal;
    _nombrePersonalizadoController = TextEditingController(
      text: pe.nombrePersonalizado ?? '',
    );
    _insumosRemovidosIds = Set.from(pe.insumosRemovidos ?? []);
    _insumosExtra = List.from(
      pe.insumosExtra ?? [],
    ); // Asegurar nueva lista mutable
    _intermediosRemovidosIds = Set.from(pe.intermediosRemovidos ?? []);
    _intermediosExtra = List.from(
      pe.intermediosExtra ?? [],
    ); // Asegurar nueva lista mutable
  }

  @override
  void dispose() {
    _nombrePersonalizadoController.dispose();
    _buscarInsumoController.dispose();
    _buscarIntermedioController.dispose();
    super.dispose();
  }

  // --- Lógica para manejar Removidos ---
  void _toggleRemoverInsumo(String insumoId) {
    setState(() {
      if (_insumosRemovidosIds.contains(insumoId)) {
        _insumosRemovidosIds.remove(insumoId);
        debugPrint("Insumo base $insumoId RE-AÑADIDO");
      } else {
        _insumosRemovidosIds.add(insumoId);
        debugPrint("Insumo base $insumoId MARCADO COMO REMOVIDO");
      }
    });
  }

  void _toggleRemoverIntermedio(String intermedioId) {
    setState(() {
      if (_intermediosRemovidosIds.contains(intermedioId)) {
        _intermediosRemovidosIds.remove(intermedioId);
        debugPrint("Intermedio base $intermedioId RE-AÑADIDO");
      } else {
        _intermediosRemovidosIds.add(intermedioId);
        debugPrint("Intermedio base $intermedioId MARCADO COMO REMOVIDO");
      }
    });
  }

  // --- Lógica para buscar y agregar Extras ---
  void _buscarInsumosExtras(String query) {
    if (query.length < 2) {
      setState(() => _insumosEncontrados = []);
      return;
    }
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    // Filtrar y excluir los que ya son base o ya están como extra
    final idsBase =
        widget.insumosBaseRequeridos.map((ir) => ir.insumoId).toSet();
    final idsExtra = _insumosExtra.map((ie) => ie.id).toSet();
    setState(() {
      _insumosEncontrados =
          insumoCtrl.insumos
              .where(
                (insumo) =>
                    insumo.nombre.toLowerCase().contains(query.toLowerCase()) &&
                    !idsBase.contains(insumo.id) &&
                    !idsExtra.contains(insumo.id),
              )
              .toList();
    });
  }

  void _buscarIntermediosExtras(String query) {
    if (query.length < 2) {
      setState(() => _intermediosEncontrados = []);
      return;
    }
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    final idsBase =
        widget.intermediosBaseRequeridos.map((ir) => ir.intermedioId).toSet();
    final idsExtra = _intermediosExtra.map((ie) => ie.id).toSet();
    setState(() {
      _intermediosEncontrados =
          intermedioCtrl.intermedios
              .where(
                (intermedio) =>
                    intermedio.nombre.toLowerCase().contains(
                      query.toLowerCase(),
                    ) &&
                    !idsBase.contains(intermedio.id) &&
                    !idsExtra.contains(intermedio.id),
              )
              .toList();
    });
  }

  Future<void> _agregarInsumoExtra(Insumo insumo) async {
    // Pedir cantidad (puedes usar un AlertDialog simple o un TextField temporal)
    final cantidad = await _pedirCantidadNumerica(
      context,
      'Cantidad de ${insumo.nombre} (${insumo.unidad})',
    );
    if (cantidad != null && cantidad > 0) {
      setState(() {
        _insumosExtra.add(ItemExtra(id: insumo.id!, cantidad: cantidad));
        _buscarInsumoController.clear(); // Limpiar búsqueda
        _insumosEncontrados = []; // Limpiar resultados
        debugPrint(
          "Insumo extra AÑADIDO: ${insumo.nombre}, Cantidad: $cantidad",
        );
      });
    }
  }

  Future<void> _agregarIntermedioExtra(Intermedio intermedio) async {
    final cantidad = await _pedirCantidadNumerica(
      context,
      'Cantidad de ${intermedio.nombre} (${intermedio.unidad})',
    );
    if (cantidad != null && cantidad > 0) {
      setState(() {
        _intermediosExtra.add(
          ItemExtra(id: intermedio.id!, cantidad: cantidad),
        );
        _buscarIntermedioController.clear();
        _intermediosEncontrados = [];
        debugPrint(
          "Intermedio extra AÑADIDO: ${intermedio.nombre}, Cantidad: $cantidad",
        );
      });
    }
  }

  // Helper para pedir cantidad
  Future<num?> _pedirCantidadNumerica(
    BuildContext context,
    String title,
  ) async {
    final controller = TextEditingController();
    return showDialog<num>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = num.tryParse(controller.text);
                  if (val != null && val > 0) {
                    Navigator.pop(ctx, val);
                  } else {
                    // Mostrar error o simplemente no cerrar
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text("Cantidad inválida"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    );
  }

  void _eliminarInsumoExtra(String id) {
    setState(() {
      _insumosExtra.removeWhere((item) => item.id == id);
      debugPrint("Insumo extra ELIMINADO: $id");
    });
  }

  void _eliminarIntermedioExtra(String id) {
    setState(() {
      _intermediosExtra.removeWhere((item) => item.id == id);
      debugPrint("Intermedio extra ELIMINADO: $id");
    });
  }

  // --- Guardar Cambios ---
  void _guardarPersonalizacion() {
    final nombreFinal = _nombrePersonalizadoController.text.trim();

    // Construir el objeto PlatoEvento actualizado
    final platoEventoActualizado = widget.platoEventoOriginal.copyWith(
      // Usar ValueGetter para manejar null explícitamente si es necesario
      nombrePersonalizado:
          () =>
              nombreFinal.isEmpty
                  ? null
                  : nombreFinal, // Guardar null si está vacío
      insumosRemovidos:
          () => _insumosRemovidosIds.toList(), // Convertir Set a List
      insumosExtra: () => List.from(_insumosExtra), // Pasar copia de la lista
      intermediosRemovidos: () => _intermediosRemovidosIds.toList(),
      intermediosExtra: () => List.from(_intermediosExtra),
    );

    debugPrint(
      "Guardando personalización. PlatoEvento actualizado: $platoEventoActualizado",
    );
    // Devolver el objeto actualizado a la pantalla anterior
    Navigator.of(context).pop(platoEventoActualizado);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obtener nombres de insumos/intermedios base para mostrar
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );

    // Crear mapas para buscar nombres rápidamente
    final mapaNombresInsumos = {
      for (var ins in insumoCtrl.insumos) ins.id: ins.nombre,
    };
    final mapaNombresIntermedios = {
      for (var inter in intermedioCtrl.intermedios) inter.id: inter.nombre,
    };

    return Dialog(
      insetPadding: const EdgeInsets.all(20), // Más espacio alrededor
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // Para permitir scroll si el contenido es largo
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalizar: ${widget.platoBase.nombre}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // --- Nombre Personalizado ---
              TextField(
                controller: _nombrePersonalizadoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre para este evento (Opcional)',
                  hintText: 'Ej: Lomo Saltado (Sin Cebolla)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // --- Sección Insumos ---
              Text('Insumos del Plato', style: theme.textTheme.titleMedium),
              const Divider(),

              // Lista de Insumos Base
              if (widget.insumosBaseRequeridos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Este plato no tiene insumos base definidos."),
                )
              else
                ...widget.insumosBaseRequeridos.map((ir) {
                  final isRemoved = _insumosRemovidosIds.contains(ir.insumoId);
                  return CheckboxListTile(
                    title: Text(
                      mapaNombresInsumos[ir.insumoId] ?? ir.insumoId,
                    ), // Mostrar nombre o ID
                    // subtitle: Text('Cantidad base: ${ir.cantidad} [Unidad]'), // Añadir si tienes unidad/cantidad base
                    value: !isRemoved,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _toggleRemoverInsumo(ir.insumoId);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor:
                        isRemoved
                            ? Colors.grey
                            : theme
                                .primaryColor, // Color gris si está removido (checkbox desmarcado)
                  );
                }).toList(),

              const SizedBox(height: 10),
              // Buscador y Lista de Insumos Extra
              _buildExtraSection(
                context: context,
                title: "Insumos Extra",
                buscarController: _buscarInsumoController,
                onBuscarChanged: _buscarInsumosExtras,
                itemsEncontrados: _insumosEncontrados,
                itemsExtra: _insumosExtra,
                nombreGetter: (item) => (item as Insumo).nombre,
                unidadGetter: (item) => (item as Insumo).unidad,
                onAgregarExtra: (item) => _agregarInsumoExtra(item as Insumo),
                onEliminarExtra: _eliminarInsumoExtra,
                mapaNombres: mapaNombresInsumos,
              ),

              const SizedBox(height: 20),

              // --- Sección Intermedios ---
              Text('Intermedios del Plato', style: theme.textTheme.titleMedium),
              const Divider(),

              // Lista de Intermedios Base
              if (widget.intermediosBaseRequeridos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Este plato no tiene intermedios base definidos.",
                  ),
                )
              else
                ...widget.intermediosBaseRequeridos.map((ir) {
                  final isRemoved = _intermediosRemovidosIds.contains(
                    ir.intermedioId,
                  );
                  return CheckboxListTile(
                    title: Text(
                      mapaNombresIntermedios[ir.intermedioId] ??
                          ir.intermedioId,
                    ),
                    value: !isRemoved,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _toggleRemoverIntermedio(ir.intermedioId);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: isRemoved ? Colors.grey : theme.primaryColor,
                  );
                }).toList(),

              const SizedBox(height: 10),
              // Buscador y Lista de Intermedios Extra
              _buildExtraSection(
                context: context,
                title: "Intermedios Extra",
                buscarController: _buscarIntermedioController,
                onBuscarChanged: _buscarIntermediosExtras,
                itemsEncontrados: _intermediosEncontrados,
                itemsExtra: _intermediosExtra,
                nombreGetter: (item) => (item as Intermedio).nombre,
                unidadGetter: (item) => (item as Intermedio).unidad,
                onAgregarExtra:
                    (item) => _agregarIntermedioExtra(item as Intermedio),
                onEliminarExtra: _eliminarIntermedioExtra,
                mapaNombres: mapaNombresIntermedios,
              ),

              const SizedBox(height: 24),
              // --- Botones de Acción ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        () =>
                            Navigator.of(
                              context,
                            ).pop(), // Simplemente cierra sin devolver nada
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                    onPressed: _guardarPersonalizacion,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget para la sección de Extras (Buscador + Lista) ---
  Widget _buildExtraSection({
    required BuildContext context,
    required String title,
    required TextEditingController buscarController,
    required ValueChanged<String> onBuscarChanged,
    required List<dynamic> itemsEncontrados, // Lista de Insumo o Intermedio
    required List<ItemExtra> itemsExtra, // Lista de ItemExtra añadidos
    required String Function(dynamic) nombreGetter,
    required String Function(dynamic) unidadGetter,
    required Function(dynamic) onAgregarExtra, // Recibe Insumo o Intermedio
    required Function(String) onEliminarExtra, // Recibe ID del ItemExtra
    required Map<String?, String>
    mapaNombres, // Para mostrar nombres en lista extra
  }) {
    final theme = Theme.of(context);
    final bool hayResultados = itemsEncontrados.isNotEmpty;
    final bool busquedaActiva = buscarController.text.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        // Lista de Extras ya añadidos (sin cambios)
        if (itemsExtra.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsExtra.length,
            itemBuilder: (ctx, index) {
              final item = itemsExtra[index];
              return ListTile(
                title: Text(mapaNombres[item.id] ?? item.id),
                subtitle: Text('Cantidad: ${item.cantidad}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar Extra',
                  onPressed: () => onEliminarExtra(item.id),
                ),
                dense: true,
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "No hay $title añadidos.",
              style: const TextStyle(color: Colors.grey),
            ),
          ),

        const SizedBox(height: 8),
        // Buscador de Extras (sin cambios)
        TextField(
          controller: buscarController,
          onChanged: onBuscarChanged,
          decoration: InputDecoration(
            hintText: 'Buscar ${title.toLowerCase()} para añadir...',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
          ),
        ),
        const SizedBox(height: 4), // Pequeño espacio antes de los resultados
        // --- AQUÍ VA EL IF y el SizedBox con la altura ---
        hayResultados
            ? SizedBox(
              // *** AJUSTA ESTA ALTURA ***
              height: 150, // Prueba con 150 o 200, o lo que necesites
              // Añadir un borde para visualizar el área si ayuda a depurar
              // decoration: BoxDecoration(
              //   border: Border.all(color: Colors.blue),
              // ),
              child: ListView.builder(
                itemCount: itemsEncontrados.length,
                itemBuilder: (ctx, index) {
                  final item = itemsEncontrados[index];
                  return ListTile(
                    title: Text(nombreGetter(item)),
                    subtitle: Text(unidadGetter(item)),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      tooltip: 'Añadir como Extra',
                      onPressed: () => onAgregarExtra(item),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  );
                },
              ),
            )
            : (busquedaActiva
                ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "No se encontraron ${title.toLowerCase()} con ese nombre.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
                : const SizedBox.shrink()),
      ],
    );
  }
} // Fin _ModalPersonalizarPlatoEventoState
