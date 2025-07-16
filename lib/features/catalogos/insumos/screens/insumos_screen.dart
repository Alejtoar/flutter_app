//insumos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumo_edit_screen.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/widgets/selector_proveedores.dart';
import 'package:golo_app/models/proveedor.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];
  Proveedor? _proveedorFiltro;

  @override
  void initState() {
    super.initState();
    // Cargar insumos al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<InsumoController>();
      controller.cargarInsumos();
      controller.cargarProveedores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar context directamente, se pasa explícitamente a _insumosList
    return Consumer<InsumoController>(
      builder: (context, controller, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Insumos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToAddEditInsumo(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(controller),
              Expanded(
                child: Consumer<InsumoController>(
                  builder: (context, controller, _) {
                    if (controller.loading && controller.insumos.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.insumos.isEmpty) {
                      return const EmptyDataWidget(
                        message: 'No hay insumos registrados.',
                        callToAction: 'Presiona + para agregar uno nuevo.',
                        icon: Icons.inventory_2_outlined,
                      );
                    }
                    // La lógica de filtro del InsumoController ya actualiza insumosFiltrados
                    final filtered = controller.insumosFiltrados;

                    if (filtered.isEmpty) {
                      return const EmptyDataWidget(
                        message:
                            'No se encontraron insumos que coincidan con tu búsqueda o filtros.',
                        icon: Icons.search_off_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Lógica de refresco como la tenías
                        await controller.cargarInsumos();
                        _searchController.clear();
                        setState(() {
                          _categoriasFiltro = [];
                          _proveedorFiltro = null;
                        });
                        controller.buscarInsumos(
                          '',
                          categorias: [],
                          proveedorId: null,
                        );
                      },
                      child: GenericListView<Insumo>(
                        items: filtered,
                        idGetter: (insumo) => insumo.id!,
                        // Deshabilitar selección múltiple pasando callbacks vacíos
                        onSelectionModeChanged: (isSelectionMode) {},
                        onSelectionChanged: (selectedIds) {},
                        itemBuilder: (context, insumo, isSelected, onSelect) {
                          return GenericListItemCard(
                            isSelected: false, // Siempre false
                            showCheckbox: false, // Ocultar el checkbox
                            onSelect: () {},
                            title: Text(
                              insumo.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Código: ${insumo.codigo}"),
                                Text(
                                  'Precio: \$${insumo.precioUnitario.toStringAsFixed(2)} / ${insumo.unidad}',
                                ),
                                if (insumo.categorias.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children:
                                        insumo.categorias.map((categoria) {
                                          return Chip(
                                            label: Text(categoria),
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            labelStyle: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              ],
                            ),
                            actions: [
                              // Acciones individuales siempre visibles
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed:
                                    () => _navigateToAddEditInsumo(
                                      context,
                                      insumo,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Eliminar',
                                onPressed:
                                    () => _confirmDeleteInsumo(
                                      context,
                                      insumo,
                                    ),
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
      },
    );
  }

  Widget _buildSearchBar(InsumoController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar insumos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _categoriasFiltro = []; // Resetear categorías también
                  controller.buscarInsumos('', categorias: []);
                },
              ),
            ),
            onChanged: (query) {
              controller.buscarInsumos(query, categorias: _categoriasFiltro);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: SelectorCategorias(
            seleccionadas: _categoriasFiltro,
            onChanged: (categorias) {
              setState(() => _categoriasFiltro = categorias);
              controller.buscarInsumos(
                _searchController.text,
                categorias: categorias,
                proveedorId: _proveedorFiltro?.id,
              );
            },

            mostrarContador: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: SelectorProveedores(
            proveedores: controller.proveedores,
            proveedorSeleccionado: _proveedorFiltro,
            onChanged: (Proveedor? proveedor) {
              setState(() => _proveedorFiltro = proveedor);
              // Aquí puedes llamar a filtrarPorProveedor o actualizar la búsqueda
              if (proveedor != null) {
                controller.filtrarPorProveedor(proveedor.id);
              } else {
                controller.cargarInsumos();
              }
            },
            label: 'Proveedor',
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAddEditInsumo(
    BuildContext context, [
    Insumo? insumo,
  ]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditInsumoScreen(insumo: insumo),
      ),
    );

    if (result == true) {
      // Recargar si hubo cambios
      context.read<InsumoController>().cargarInsumos();
    }
  }

  Future<void> _confirmDeleteInsumo(BuildContext context, Insumo insumo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar el insumo "${insumo.nombre}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<InsumoController>();
    // el eliminarInsumo del controller ya maneja el error y lo guarda
    final success = await controller.eliminarInsumo(id: insumo.id!);

    if (mounted) {
      if (success) {
        showAppSnackBar(context, 'Insumo "${insumo.nombre}" eliminado correctamente.');
      } else {
        // Muestra el error específico que el controller guardó
        showAppSnackBar(context, controller.error ?? 'Error desconocido al eliminar.', isError: true);
      }
    }
  }
}
