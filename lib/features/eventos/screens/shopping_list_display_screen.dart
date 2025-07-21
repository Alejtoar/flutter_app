// features/eventos/shopping_list/screens/shopping_list_display_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/services/excel_export_service_sync.dart'; // Importar el nuevo servicio
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart'; // Importar snackbar global
//import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ShoppingListDisplayScreen extends StatefulWidget {
  final GroupedShoppingListResult groupedShoppingList;
  final List<String>? eventoIds;
  final bool separateByFacturable;

  const ShoppingListDisplayScreen({
    Key? key,
    required this.groupedShoppingList,
    this.eventoIds,
    this.separateByFacturable = false, // Por defecto, mostrar combinado
  }) : super(key: key);

  @override
  State<ShoppingListDisplayScreen> createState() => _ShoppingListDisplayScreenState();
}

class _ShoppingListDisplayScreenState extends State<ShoppingListDisplayScreen> {
  late TextEditingController _titleController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _initializeTitle();
  }

  Future<void> _initializeTitle() async {
    String initialTitle = 'Lista de Compras';
    final ids = widget.eventoIds;

    if (ids != null && ids.isNotEmpty) {
      if (ids.length == 1) {
        try {
          final eventoRepo = context.read<EventoRepository>();
          final evento = await eventoRepo.obtener(ids.first, uid: _uid);
          initialTitle = 'Lista de Compras - Evento ${evento.codigo}';
        } catch (e) {
          initialTitle = 'Lista de Compras - Evento ID: ${ids.first}';
        }
      } else {
        initialTitle = 'Lista de Compras - ${ids.length} Eventos';
      }
    }
    if (mounted) setState(() => _titleController.text = initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }



  Future<void> _exportarExcel() async {
    if (widget.groupedShoppingList.isEmpty) {
      showAppSnackBar(context, "La lista está vacía.", isError: true);
      return;
    }
    final String baseFileName = _titleController.text.isNotEmpty ? _titleController.text : "Lista_Compras";
    
    try {
      final excelService = context.read<ExcelExportServiceSync>();
      // Llamar al servicio y pasarle el flag que ya tiene esta pantalla
      await excelService.exportAndSaveShoppingList(
         context: context,
         data: widget.groupedShoppingList,
         baseFileName: baseFileName,
         // El formato del Excel será el mismo que el de la vista
         separateByFacturable: widget.separateByFacturable,
      );
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Ocurrió un error inesperado al exportar.", isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEmpty = widget.groupedShoppingList.isEmpty;
    double costoTotalGeneral = 0.0;
    if (!isEmpty) {
      // El cálculo del total sigue siendo el mismo
      widget.groupedShoppingList.forEach((proveedor, items) {
        for (var item in items) {
          costoTotalGeneral += item.costoItem;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: isEmpty
            ? const Text('Lista de Compras')
            : TextField(
                controller: _titleController,
                style: theme.appBarTheme.titleTextStyle,
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              ),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.save_alt_outlined), // Icono de guardar/exportar
              tooltip: 'Guardar como Excel',
              onPressed: _exportarExcel,
            ),
        ],
      ),
      body: isEmpty
          ? const Center(child: Text('No se generaron insumos para la lista de compras.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Espacio para el BottomAppBar
              itemCount: widget.groupedShoppingList.length,
              itemBuilder: (context, index) {
                final proveedor = widget.groupedShoppingList.keys.elementAt(index);
                final items = widget.groupedShoppingList[proveedor]!;
                final proveedorNombre = proveedor?.nombre ?? "Sin Proveedor Asignado";
                double costoTotalProveedor = items.fold(0.0, (sum, item) => sum + item.costoItem);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ENCABEZADO PROVEEDOR ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Expanded(child: Text(proveedorNombre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: proveedor != null ? theme.colorScheme.primary : Colors.grey[700]))),
                             const SizedBox(width: 8),
                             Text("Subtotal: \$${costoTotalProveedor.toStringAsFixed(2)}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        if (proveedor?.codigo != null) Padding(padding: const EdgeInsets.only(top: 2.0), child: Text("Código: ${proveedor!.codigo}", style: theme.textTheme.bodySmall)),
                        const Divider(thickness: 1, height: 16),

                        // --- LISTA DE ITEMS ---
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (ctx, itemIndex) {
                            final item = items[itemIndex];

                            // Determinar el color de fondo para la fila
                            Color? tileColor;
                            if (widget.separateByFacturable && item.esFacturable != null) {
                                if (!item.esFacturable!) {
                                   tileColor = Colors.grey[200]; // Fondo gris para NO facturables
                                }
                                // Opcional: podrías poner un color verde claro para los facturables
                                // else { tileColor = Colors.green[50]; }
                            }

                            return ListTile(
                              tileColor: tileColor, // Aplicar color de fondo
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                              title: Text(item.insumo.nombre),
                              subtitle: Text("Costo Item: \$${item.costoItem.toStringAsFixed(2)}"),
                              trailing: Text(
                                "${item.cantidad.toStringAsFixed(item.cantidad.truncateToDouble() == item.cantidad ? 0 : 2)} ${item.unidad}",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: isEmpty ? null : BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Costo Total Estimado: ", style: theme.textTheme.titleMedium),
              Text("\$${costoTotalGeneral.toStringAsFixed(2)}", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}