// features/eventos/shopping_list/screens/shopping_list_display_screen.dart (NUEVO ARCHIVO)

import 'package:flutter/material.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/services/shopping_list_service.dart'; // Para los typedefs

import 'package:csv/csv.dart';
import 'dart:convert'; // para utf8
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

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
    // ... (igual que antes)
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Exportar como CSV'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportarListaComoCsv(context);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _exportarListaComoCsv(BuildContext context) async {
    debugPrint("Iniciando exportación CSV...");
    List<List<dynamic>> rows = [];
    // Usar el título actual del TextField para el nombre del archivo y el subject
    final String tituloActual =
        _titleController.text.isNotEmpty
            ? _titleController.text
            : "Lista de Compras";
    // Crear un sufijo de archivo a partir del título (simplificado)
    final String archivoSufijo = tituloActual
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .substring(0, (tituloActual.length > 20 ? 20 : tituloActual.length));

    rows.add([
      "Proveedor Codigo",
      "Proveedor Nombre",
      "Insumo Codigo",
      "Insumo Nombre",
      "Cantidad",
      "Unidad",
      "Categoria Insumo",
    ]);
    widget.groupedShoppingList.forEach((proveedor, items) {
      final provCodigo = proveedor?.codigo ?? '';
      final provNombre = proveedor?.nombre ?? 'Sin Proveedor';
      for (var item in items) {
        rows.add([
          provCodigo,
          provNombre,
          item.insumo.codigo,
          item.insumo.nombre,
          item.cantidad,
          item.unidad,
          item.insumo.categorias,
        ]);
      }
    });
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/${archivoSufijo}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData, encoding: utf8);
      debugPrint("CSV guardado temporalmente en: $filePath");

      final xFile = XFile(filePath);
      final params = ShareParams(
        files: [xFile],
        text: tituloActual, // Usar título personalizado
        subject: tituloActual, // Usar título personalizado
      );
      await SharePlus.instance.share(params);

      // ... (manejar resultado)
    } catch (e, st) {
      debugPrint("Error al exportar/compartir CSV: $e\n$st");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar CSV: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
