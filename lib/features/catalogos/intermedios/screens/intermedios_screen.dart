// intermedios_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart'; // Importar lista genérica
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart'; // Importar card genérica
import 'package:golo_app/features/common/utils/snackbar_helper.dart'; // Importar SnackBar
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/busqueda_bar.dart'; // Tu BusquedaBar
// Pantallas de navegación
import 'package:golo_app/features/catalogos/intermedios/screens/intermedio_edit_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedio_detalle_screen.dart';

class IntermediosScreen extends StatefulWidget {
  const IntermediosScreen({super.key});

  @override
  State<IntermediosScreen> createState() => _IntermediosScreenState();
}

class _IntermediosScreenState extends State<IntermediosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<IntermedioController>().cargarIntermedios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NAVEGACIÓN Y ACCIONES INDIVIDUALES ---
  void _verDetalle(Intermedio intermedio) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IntermedioDetalleScreen(intermedio: intermedio)),
    );
  }

  void _editar(Intermedio? intermedio) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IntermedioEditScreen(intermedio: intermedio)),
    ).then((result) {
      // Recargar si la pantalla de edición devolvió 'true'
      if (result == true && mounted) {
        context.read<IntermedioController>().cargarIntermedios();
      }
    });
  }

  void _eliminar(Intermedio intermedio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Seguro que deseas eliminar el intermedio "${intermedio.nombre}"?'),
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
    if (confirm != true || !mounted) return;

    final controller = context.read<IntermedioController>();
    // Llama al método del controller para un solo item
    await controller.eliminarIntermedio(intermedio.id!);

    if (mounted) {
      if (controller.error != null) {
        showAppSnackBar(context, controller.error!, isError: true);
      } else {
        showAppSnackBar(context, 'Intermedio "${intermedio.nombre}" eliminado.');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermedios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear Intermedio',
            onPressed: () => _editar(null), // Llamar con null para crear
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            BusquedaBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SelectorCategorias(
              categorias: Intermedio.categoriasDisponibles.keys.toList(),
              seleccionadas: _categoriasFiltro,
              onChanged: (cats) => setState(() => _categoriasFiltro = cats),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<IntermedioController>(
                builder: (context, controller, _) {
                  if (controller.loading && controller.intermedios.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.intermedios.isEmpty) {
                    return const EmptyDataWidget(
                      message: 'No hay intermedios registrados.',
                      callToAction: 'Presiona + para crear uno nuevo.',
                      icon: Icons.blender_outlined,
                    );
                  }
                  
                  final filtered = controller.intermedios.where((i) {
                    final matchesText = _searchController.text.isEmpty ||
                      i.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                      i.codigo.toLowerCase().contains(_searchController.text.toLowerCase());
                    final matchesCats = _categoriasFiltro.isEmpty ||
                      i.categorias.any((cat) => _categoriasFiltro.contains(cat));
                    return matchesText && matchesCats;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyDataWidget(
                        message: 'No se encontraron intermedios que coincidan con la búsqueda.',
                        icon: Icons.search_off_outlined,
                    );
                  }
                  
                  // --- USANDO EL WIDGET GENÉRICO ---
                  return GenericListView<Intermedio>(
                    items: filtered,
                    idGetter: (intermedio) => intermedio.id!,
                    // --- DESHABILITAR SELECCIÓN MÚLTIPLE ---
                    // Simplemente no hacemos nada en los callbacks de selección.
                    onSelectionModeChanged: (isSelectionMode) {
                       // No hacer nada para que _isSelectionMode nunca cambie.
                       // El long press no tendrá efecto.
                    },
                    onSelectionChanged: (selectedIds) {
                       // No hacer nada.
                    },
                    // ------------------------------------
                    itemBuilder: (context, intermedio, isSelected, onSelect) {
                      // isSelected siempre será false. onSelect no hará nada útil.
                      // Usamos GenericListItemCard para unificar la apariencia.
                      return GenericListItemCard(
                        isSelected: false, // Siempre false
                        onSelect: () => _verDetalle(intermedio), 
                        showCheckbox: false,
                        leading: Icon(
                          (intermedio.categorias.isNotEmpty
                              ? (Intermedio.categoriasDisponibles[intermedio.categorias.first]?['icon'] ?? Icons.category)
                              : Icons.category),
                          color: (intermedio.categorias.isNotEmpty
                              ? (Intermedio.categoriasDisponibles[intermedio.categorias.first]?['color'] ?? Colors.grey)
                              : Colors.grey),
                        ),
                        title: Text(intermedio.nombre),
                        subtitle: Text('Categoría: ${intermedio.categorias.join(', ')}'),
                        actions: [ // Mostrar siempre las acciones individuales
                          IconButton(icon: const Icon(Icons.visibility), tooltip: 'Ver detalle', onPressed: () => _verDetalle(intermedio)),
                          IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar', onPressed: () => _editar(intermedio)),
                          IconButton(icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error), tooltip: 'Eliminar', onPressed: () => _eliminar(intermedio)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
