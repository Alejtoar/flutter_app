// platos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:provider/provider.dart';
import '../controllers/plato_controller.dart';
import '../widgets/busqueda_bar.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'plato_edit_screen.dart';
import 'plato_detalle_screen.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({Key? key}) : super(key: key);

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];

  // Estado para selección múltiple
  bool _isSelectionMode = false;
  Set<String> _selectedPlatoIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        // <--- El "guard" o verificación
        context.read<PlatoController>().cargarPlatos();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
              categorias: Plato.categoriasDisponibles.keys.toList(),
              seleccionadas: _categoriasFiltro,
              onChanged: (cats) => setState(() => _categoriasFiltro = cats),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<PlatoController>(
                builder: (context, controller, _) {
                  if (controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final platos = controller.platos;
                  if (platos.isEmpty) {
                    return const EmptyDataWidget(
                      message: 'Aún no has creado ningún plato.',
                      callToAction:
                          'Presiona + para agregar tu primer plato al menú.',
                      icon: Icons.restaurant_menu_outlined,
                    );
                  }
                  // Filtrado por texto y categorías
                  final filtered =
                      platos.where((p) {
                        final matchesText =
                            _searchController.text.isEmpty ||
                            p.nombre.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            );
                        final matchesCats =
                            _categoriasFiltro.isEmpty ||
                            p.categorias.any(
                              (cat) => _categoriasFiltro.contains(cat),
                            );
                        return matchesText && matchesCats;
                      }).toList();
                  if (filtered.isEmpty) {
                    return const EmptyDataWidget(
                      message:
                          'No se encontraron platos que coincidan con tu búsqueda o filtros.',
                      icon: Icons.search_off_outlined,
                    );
                  }
                  // Usa ListaPlatos para mostrar los platos con opciones de ver, editar y eliminar
                  return GenericListView<Plato>(
                    items: filtered,
                    idGetter: (plato) => plato.id!,
                    onSelectionModeChanged: (isSelectionMode) {
                      setState(() => _isSelectionMode = isSelectionMode);
                    },
                    onSelectionChanged: (selectedIds) {
                      setState(() => _selectedPlatoIds = selectedIds);
                    },
                    itemBuilder: (context, plato, isSelected, onSelect) {
                      return GenericListItemCard(
                        isSelected: isSelected,
                        onSelect: onSelect,
                        title: Text(plato.nombre),
                        subtitle: Text(
                          'Categorías: ${plato.nombresCategorias}',
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              plato.iconosCategorias
                                  .map(
                                    (icon) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0,
                                      ),
                                      child: Icon(icon, size: 20),
                                    ),
                                  )
                                  .toList(),
                        ),
                        actions:
                            _isSelectionMode
                                ? []
                                : [
                                  // No mostrar acciones individuales en modo selección
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'Ver detalle',
                                    onPressed: () => _verDetalle(plato),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () => _editar(plato),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminar(plato),
                                  ),
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

  AppBar _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        title: Text('${_selectedPlatoIds.length} seleccionados'),
        leading: IconButton(
          // Botón para cancelar selección
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedPlatoIds.clear();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Eliminar Seleccionados',
            onPressed: _eliminarPlatosSeleccionados,
          ),
          // Puedes añadir más acciones aquí
        ],
      );
    } else {
      // AppBar normal
      return AppBar(
        title: const Text('Platos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _editar(null), // Llamar con null para crear
          ),
        ],
      );
    }
  }

  // Helpers para navegación (para mantener el build limpio)
  void _verDetalle(Plato plato) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlatoDetalleScreen(plato: plato)));
  }

  void _editar(Plato? plato) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlatoEditScreen(plato: plato)));
  }

  void _eliminar(Plato plato) async {
    // 1. Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Plato'),
            content: Text(
              '¿Estás seguro de que deseas eliminar el plato "${plato.nombre}"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    // 2. Si el usuario no confirmó, no hacer nada
    if (confirm != true || !mounted) return;

    // 3. Llamar al controlador para eliminar
    final controller = context.read<PlatoController>();
    try {
      await controller.eliminarPlato(plato.id!);
      if (mounted)
        showAppSnackBar(
          context,
          'Plato "${plato.nombre}" eliminado con éxito.',
        );
    } catch (e) {
      if (mounted)
        showAppSnackBar(
          context,
          'Error al eliminar: ${e.toString()}',
          isError: true,
        );
    }
    // El controller se encarga de llamar a notifyListeners, por lo que la lista se actualizará.
  }

  // Para eliminar MÚLTIPLES platos seleccionados
  void _eliminarPlatosSeleccionados() async {
    final idsAEliminar = Set<String>.from(
      _selectedPlatoIds,
    ); // Copia para evitar modificar durante iteración
    final cantidad = idsAEliminar.length;
    if (cantidad == 0) return;

    // 1. Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Eliminar $cantidad Platos'),
            content: Text(
              '¿Estás seguro de que deseas eliminar los $cantidad platos seleccionados? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    // 2. Si el usuario no confirmó, no hacer nada
    if (confirm != true || !mounted) return;

    // 3. Llamar al controlador para eliminar CADA plato
    final controller = context.read<PlatoController>();
    // Mostrar un indicador de carga si son muchos
    showDialog(
      context: context,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    final idsExitosos = await controller.eliminarPlatosEnLote(idsAEliminar);
    if (mounted) Navigator.pop(context);

    final cantidadExitosa = idsExitosos.length;
    final cantidadFallida = cantidad - cantidadExitosa;

    if (mounted) {
      if (cantidadFallida > 0 && controller.error != null) {
        // Si hubo algún error, mostrarlo
        showAppSnackBar(context, controller.error!, isError: true);
      } else if (cantidadExitosa > 0) {
        // Si todo salió bien (o al menos algo se borró sin error explícito)
        showAppSnackBar(
          context,
          '$cantidadExitosa de $cantidad platos han sido eliminados.',
        );
      }

      // Actualizar la lista de IDs seleccionados para quitar los que sí se borraron
      final nuevosIdsSeleccionados = _selectedPlatoIds.difference(idsExitosos);

      setState(() {
        _selectedPlatoIds = nuevosIdsSeleccionados;
        // Salir del modo selección solo si TODOS los items fueron eliminados
        if (_selectedPlatoIds.isEmpty) {
          _isSelectionMode = false;
        }
      });
    }
  }
}
