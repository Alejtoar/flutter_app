//insumos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumo_edit_screen.dart';
import 'package:golo_app/features/catalogos/insumos/widgets/insumo_card.dart';
import 'package:golo_app/features/common/empty_data_widget.dart';
import 'package:golo_app/features/common/selector_categorias.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/selector_proveedores.dart';
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
              Expanded(child: _insumosList(context, controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _insumosList(BuildContext mainContext, InsumoController controller) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.insumos.isEmpty) {
      // return const Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Icon(Icons.inventory_2, size: 50, color: Colors.grey),
      //       SizedBox(height: 16),
      //       Text(
      //         'No hay insumos registrados\nPresiona + para agregar uno nuevo',
      //         textAlign: TextAlign.center,
      //         style: TextStyle(color: Colors.grey),
      //       ),
      //     ],
      //   ),
      // );
      return const EmptyDataWidget(
        message: 'No hay insumos registrados.',
        callToAction: 'Presiona + para agregar uno nuevo.',
        icon: Icons.inventory_2_outlined, // o Icons.inventory_2
      );
    }
    if (controller.insumosFiltrados.isEmpty && controller.insumos.isNotEmpty) {
      return const EmptyDataWidget(
        message:
            'No se encontraron insumos que coincidan con tu búsqueda o filtros.',
        icon: Icons.search_off_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.cargarInsumos();
        // También es buena idea limpiar filtros aquí o que cargarInsumos lo haga
        _searchController.clear();
        setState(() {
          _categoriasFiltro = [];
          _proveedorFiltro = null;
        });
        controller.buscarInsumos('', categorias: [], proveedorId: null);
      },
      child: ListView.builder(
        itemCount: controller.insumosFiltrados.length,
        itemBuilder:
            (itemContext, index) => InsumoCard(
              insumo: controller.insumosFiltrados[index],
              onEdit:
                  () => _navigateToAddEditInsumo(
                    mainContext,
                    controller.insumosFiltrados[index],
                  ),
              onDelete:
                  () => _confirmDeleteInsumo(
                    mainContext,
                    controller.insumosFiltrados[index].id!,
                  ),
            ),
      ),
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

  Future<void> _confirmDeleteInsumo(BuildContext context, String id) async {
    // Diálogo de confirmación en la UI
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de eliminar este insumo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Eliminar solo si confirmó
    final controller = context.read<InsumoController>();
    final success = await controller.eliminarInsumo(id: id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Insumo eliminado correctamente'
              : 'Error al eliminar el insumo',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
