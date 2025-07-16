import 'package:flutter/material.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedor_edit_screen.dart';
import 'package:golo_app/models/proveedor.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = context.read<ProveedorController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargarProveedores();
    });
    _searchController.addListener(() {
      controller.buscarProveedoresPorNombre(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  

  Future<void> _editar(Proveedor? proveedor) async {
    // Navegar a la pantalla de edición
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProveedorEditScreen(proveedor: proveedor),
      ),
    );
    // Si se guardaron cambios (la pantalla de edición devuelve true), recargar la lista
    if (result == true && mounted) {
      context.read<ProveedorController>().cargarProveedores();
    }
  }

  Future<void> _eliminar(Proveedor proveedor) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar al proveedor "${proveedor.nombre}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<ProveedorController>();
    final success = await controller.eliminarProveedor(proveedor.id!);

    if (mounted) {
      if (success) {
        showAppSnackBar(context, 'Proveedor "${proveedor.nombre}" eliminado correctamente.');
      } else {
        // Mostrar el error específico que el controller pueda haber guardado
        showAppSnackBar(context, 'Error al eliminar el proveedor.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold se construye siempre
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _editar(null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proveedores por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // La búsqueda se actualiza por el listener
                  },
                ),
              ),
            ),
          ),
          // Lista de proveedores
          Expanded(
            child: Consumer<ProveedorController>(
              builder: (context, controller, _) {
                if (controller.loading && controller.proveedores.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.proveedores.isEmpty) {
                  return EmptyDataWidget(
                    message: _searchController.text.isEmpty
                        ? 'No tienes proveedores registrados.'
                        : 'No se encontraron proveedores con ese nombre.',
                    callToAction: _searchController.text.isEmpty
                        ? 'Presiona + para añadir tu primer proveedor.'
                        : '',
                    icon: _searchController.text.isEmpty
                        ? Icons.store_mall_directory_outlined
                        : Icons.search_off_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.cargarProveedores,
                  child: GenericListView<Proveedor>(
                    items: controller.proveedores,
                    idGetter: (proveedor) => proveedor.id!,
                    // Deshabilitar selección múltiple
                    onSelectionModeChanged: (isSelectionMode) {},
                    onSelectionChanged: (selectedIds) {},
                    itemBuilder: (context, proveedor, isSelected, onSelect) {
                      return GenericListItemCard(
                        isSelected: false,
                        showCheckbox: false, // Ocultar el checkbox
                        onSelect: () { /* Opcional: Navegar a una pantalla de detalle si la tuvieras */ },
                        title: Text('${proveedor.nombre} (${proveedor.codigo})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (proveedor.correo.isNotEmpty) Text(proveedor.correo),
                            if (proveedor.telefono.isNotEmpty) Text(proveedor.telefono),
                            if (proveedor.tiposInsumos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: proveedor.tiposInsumos.map((cat) {
                                    return Chip(
                                      label: Text(cat),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: const TextStyle(fontSize: 11),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                            onPressed: () => _editar(proveedor),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                            tooltip: 'Eliminar',
                            onPressed: () => _eliminar(proveedor),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
