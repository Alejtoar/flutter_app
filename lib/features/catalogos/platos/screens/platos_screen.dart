import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/plato_controller.dart';
import '../widgets/busqueda_bar.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/features/common/selector_categorias.dart';
import 'plato_edit_screen.dart';
import '../widgets/lista_platos.dart';
import 'plato_detalle_screen.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({Key? key}) : super(key: key);

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<PlatoController>(context, listen: false).cargarPlatos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlatoEditScreen()),
              );
            },
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
                    return const Center(child: Text('No hay platos'));
                  }
                  // Filtrado por texto y categorías
                  final filtered = platos.where((p) {
                    final matchesText = _searchController.text.isEmpty ||
                      p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
                    final matchesCats = _categoriasFiltro.isEmpty ||
                      p.categorias.any((cat) => _categoriasFiltro.contains(cat));
                    return matchesText && matchesCats;
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No hay platos que coincidan con la búsqueda'));
                  }
                  // Usa ListaPlatos para mostrar los platos con opciones de ver, editar y eliminar
                  return ListaPlatos(
                    platos: filtered,
                    onVerDetalle: (plato) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlatoDetalleScreen(plato: plato),
                        ),
                      );
                    },
                    onEditar: (plato) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlatoEditScreen(plato: plato),
                        ),
                      );
                    },
                    onEliminar: (plato) async {
                      final controller = Provider.of<PlatoController>(context, listen: false);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar plato'),
                          content: Text('¿Seguro que deseas eliminar "${plato.nombre}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await controller.eliminarPlato(plato.id!);
                      }
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
