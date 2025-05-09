// features/eventos/shopping_list/screens/shopping_list_display_screen.dart (NUEVO ARCHIVO)

import 'package:flutter/material.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/services/excel_export_service.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:provider/provider.dart'; // Para los typedefs

class ShoppingListDisplayScreen extends StatefulWidget {
  final GroupedShoppingListResult groupedShoppingList;
  final List<String>? eventoIds;

  const ShoppingListDisplayScreen({
    Key? key,
    required this.groupedShoppingList,
    this.eventoIds,
  }) : super(key: key);

  @override
  State<ShoppingListDisplayScreen> createState() =>
      _ShoppingListDisplayScreenState();
}

class _ShoppingListDisplayScreenState extends State<ShoppingListDisplayScreen> {
  late TextEditingController
  _titleController; // Controlador para el título editable

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _initializeTitleAndSuffix();
  }

  Future<void> _initializeTitleAndSuffix() async {
    String initialTitle = 'Lista de Compras';

    final ids = widget.eventoIds;

    if (ids != null && ids.isNotEmpty) {
      if (ids.length == 1) {
        final eventoId = ids.first;
        try {
          final eventoRepo = context.read<EventoRepository>();
          final evento = await eventoRepo.obtener(eventoId);
          initialTitle = 'Lista de Compras - Evento ${evento.codigo}';
        } catch (e) {
          debugPrint("Error obteniendo código para evento $eventoId: $e");
          initialTitle = 'Lista de Compras - Evento ID: $eventoId';
        }
      } else {
        initialTitle = 'Lista de Compras - Varios Eventos';
      }
    }

    if (mounted) {
      setState(() {
        _titleController.text = initialTitle;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEmpty = widget.groupedShoppingList.isEmpty;
    double costoTotalGeneralCalculado = 0.0;
    if (!isEmpty) {
      widget.groupedShoppingList.forEach((proveedor, items) {
        for (var item in items) {
          costoTotalGeneralCalculado += item.costoItem;
        }
      });
      debugPrint(
        "[ShoppingListDisplayScreen] Costo Total General Calculado: $costoTotalGeneralCalculado",
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Título ahora es un TextField para permitir edición
        title:
            isEmpty // Si no hay items, no mostrar TextField de título
                ? const Text('Lista de Compras')
                : TextField(
                  controller: _titleController,
                  style:
                      theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleLarge,
                  decoration: const InputDecoration(
                    hintText: 'Título de la Lista',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  // Podrías añadir un onChanged si quieres guardar el título automáticamente
                  // onChanged: (newTitle) { /* Lógica para guardar el título si es necesario */ }
                ),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Exportar/Compartir Lista',
              onPressed: () => _showExportOptions(context),
            ),
        ],
      ),
      body:
          isEmpty
              ? const Center(/* ... mensaje vacío ... */)
              : ListView.builder(
                itemCount: widget.groupedShoppingList.length,
                itemBuilder: (context, index) {
                  // ... (renderizado de la lista como antes) ...
                  final proveedor = widget.groupedShoppingList.keys.elementAt(
                    index,
                  );
                  final items = widget.groupedShoppingList[proveedor]!;
                  final proveedorNombre =
                      proveedor?.nombre ?? "Sin Proveedor Asignado";
                  final proveedorCodigo = proveedor?.codigo;
                  // --- Calcular costo total para este proveedor ---
                  double costoTotalProveedor = 0.0;
                  for (var item in items) {
                    costoTotalProveedor += item.costoItem;
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // Alinear textos arriba si proveedorNombre es largo
                            children: [
                              Expanded(
                                child: Column(
                                  // Columna para nombre y código
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proveedorNombre, // Ya sea el nombre o "Sin Proveedor Asignado"
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                proveedor != null
                                                    ? theme.colorScheme.primary
                                                    : Colors.grey[700],
                                          ),
                                    ),
                                    if (proveedorCodigo !=
                                        null) // Código solo si hay proveedor
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          "Código: $proveedorCodigo",
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Espacio antes del subtotal
                              // --- MOSTRAR SUBTOTAL SIEMPRE ---
                              Text(
                                "Subtotal: \$${costoTotalProveedor.toStringAsFixed(2)}",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ), // Quizás un poco menos bold que el nombre
                              ),
                              // --- FIN MOSTRAR SUBTOTAL ---
                            ],
                          ),
                          const Divider(thickness: 1, height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(height: 1, thickness: 0.5),
                            itemBuilder: (ctx, itemIndex) {
                              final item = items[itemIndex];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 4,
                                ),
                                title: Text(item.insumo.nombre),
                                subtitle: Text(
                                  "Costo: \$${item.costoItem.toStringAsFixed(2)}",
                                ),
                                trailing: Text(
                                  "${item.cantidad.toStringAsFixed(item.cantidad.truncateToDouble() == item.cantidad ? 0 : 2)} ${item.unidad}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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
      bottomNavigationBar:
          isEmpty
              ? null
              : BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Costo Total Estimado: ",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "\$${costoTotalGeneralCalculado.toStringAsFixed(2)}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // --- Lógica de Exportación (Usa el título del _titleController) ---

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Excel - Todo en 1 Archivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _llamarServicioExcel(separateFiles: false); // Llama al helper
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.folder_zip_outlined,
                ), // Icono diferente
                title: const Text('Excel - 1 Archivo por Proveedor'),
                onTap: () {
                  Navigator.pop(ctx);
                  _llamarServicioExcel(separateFiles: true); // Llama al helper
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.save_alt_outlined,
                ), // Icono de Guardar
                title: const Text('Guardar como Excel (.xlsx)'),
                onTap: () {
                  Navigator.pop(ctx);
                  // Llama a la función de guardado, no de compartir
                  _llamarServicioExcelYGuardar(
                    separateFilesByProvider: false,
                    separateByFacturable: false,
                  );
                },
              ),
            ],
          ),
    );
  }

  Future<void> _llamarServicioExcelYGuardar({
    required bool separateFilesByProvider,
    required bool separateByFacturable,
  }) async {
    if (widget.groupedShoppingList.isEmpty) {
      /* ... */
      return;
    }
    final String baseFileName =
        _titleController.text.isNotEmpty
            ? _titleController.text
            : "Lista_Compras";
    _showSnackBar("Preparando archivo Excel...", isError: false);

    try {
      final excelService = context.read<ExcelExportService>();
      // Llama al nuevo método del servicio
      await excelService.exportSingleExcelWithMultipleSheets(
        context: context,
        data: widget.groupedShoppingList,
        baseFileName: baseFileName,
        separateFacturableInResumen: separateByFacturable,
        separateFacturableInProviderSheets: separateFilesByProvider,
      );
      // El feedback de éxito/error ahora lo da el servicio o el file picker
    } catch (e) {
      debugPrint(
        "Error al llamar a ExcelExportService.exportShoppingListAndSave: $e",
      );
      if (mounted) {
        _showSnackBar(
          "Ocurrió un error inesperado durante la exportación a Excel.",
          isError: true,
        );
      }
    }
  }

  // NUEVO Helper para llamar al servicio de Excel
  Future<void> _llamarServicioExcel({required bool separateFiles}) async {
    if (widget.groupedShoppingList.isEmpty) {
      _showSnackBar(
        "La lista está vacía, no hay nada que exportar.",
        isError: true,
      );
      return;
    }
    // Obtener título actual para nombre de archivo base
    final String baseFileName =
        _titleController.text.isNotEmpty
            ? _titleController.text
            : "Lista_Compras";

    // Mostrar indicador (opcional, la exportación puede ser rápida)
    _showSnackBar("Generando archivo(s) Excel...", isError: false);

    try {
      final excelService = context.read<ExcelExportService>();
      final success = await excelService.shareShoppingList(
        context: context,
        data: widget.groupedShoppingList,
        baseFileName: baseFileName,
        separateFilesByProvider: separateFiles,
      );

      if (success) {
        debugPrint("Llamada a compartir Excel realizada.");
        // El SnackBar de éxito o error lo maneja internamente el servicio o la llamada a Share
      } else {
        _showSnackBar(
          "No se pudo generar o compartir el archivo Excel.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error al llamar a ExcelExportService: $e");
      _showSnackBar(
        "Ocurrió un error inesperado durante la exportación.",
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
