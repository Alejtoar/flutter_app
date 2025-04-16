import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedor_edit_screen.dart';
import 'package:golo_app/features/catalogos/proveedores/widgets/proveedor_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorController>().cargarProveedores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar(ProveedorController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar proveedores...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              controller.cargarProveedores();
            },
          ),
        ),
        onChanged: (query) {
          controller.buscarProveedoresPorNombre(query);
        },
      ),
    );
  }

  Future<void> _navigateToAddEditProveedor([Proveedor? proveedor]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProveedorEditScreen(proveedor: proveedor),
      ),
    );
    if (result == true) {
      context.read<ProveedorController>().cargarProveedores();
    }
  }

  Future<void> _confirmDeleteProveedor(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Eliminar este proveedor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final controller = context.read<ProveedorController>();
    final success = await controller.eliminarProveedor(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Proveedor eliminado correctamente'
            : 'Error al eliminar el proveedor'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProveedorController>(
      builder: (context, controller, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestión de Proveedores'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToAddEditProveedor(),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(controller),
              Expanded(
                child: controller.proveedores.isEmpty
                    ? const Center(
                        child: Text('No hay proveedores registrados'),
                      )
                    : ListView.builder(
                        itemCount: controller.proveedores.length,
                        itemBuilder: (context, index) => ProveedorCard(
                          proveedor: controller.proveedores[index],
                          onEdit: () => _navigateToAddEditProveedor(controller.proveedores[index]),
                          onDelete: () => _confirmDeleteProveedor(controller.proveedores[index].id!),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
