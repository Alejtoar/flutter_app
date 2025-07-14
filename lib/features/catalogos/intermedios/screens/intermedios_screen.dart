// intermedios_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/busqueda_bar.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/lista_intermedios.dart';


import 'package:golo_app/features/catalogos/intermedios/screens/intermedio_edit_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedio_detalle_screen.dart';

class IntermediosScreen extends StatefulWidget {
  const IntermediosScreen({super.key});

  @override
  State<IntermediosScreen> createState() => _IntermediosScreenState();
}

class _IntermediosScreenState extends State<IntermediosScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar intermedios desde Firebase al iniciar
    Future.microtask(() => Provider.of<IntermedioController>(context, listen: false).cargarIntermedios());
    
  }
  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltro = [];


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermedios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const IntermedioEditScreen(),
                ),
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
              categorias: Intermedio.categoriasDisponibles.keys.toList(),
              seleccionadas: _categoriasFiltro,
              
              onChanged: (cats) => setState(() => _categoriasFiltro = cats),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<IntermedioController>(
                builder: (context, controller, _) {
                  if (controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final intermedios = controller.intermedios;
                  if (intermedios.isEmpty) {
                    return const EmptyDataWidget(
                      message: 'No hay intermedios registrados.',
                      callToAction: 'Presiona + para crear uno nuevo.',
                      icon: Icons.blender_outlined, // O algún ícono relevante
                    );
                  }
                  // Filtrar intermedios por búsqueda y categorías
                  final filtered = intermedios.where((i) {
                    final matchesText = _searchController.text.isEmpty ||
                      i.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                      i.codigo.toLowerCase().contains(_searchController.text.toLowerCase());
                    final matchesCats = _categoriasFiltro.isEmpty ||
                      i.categorias.any((cat) => _categoriasFiltro.contains(cat));
                    return matchesText && matchesCats;
                  }).toList();
                  if (filtered.isEmpty) {
                    return const EmptyDataWidget(
                        message: 'No se encontraron intermedios que coincidan con tu búsqueda o filtros.',
                        icon: Icons.search_off_outlined,
                        );
                  }
                  return ListaIntermedios(
                    intermedios: filtered,
                    onEditar: (intermedio) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IntermedioEditScreen(intermedio: intermedio),
                        ),
                      );
                    },
                    onEliminar: (intermedio) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: Text('¿Seguro que deseas eliminar el intermedio "${intermedio.nombre}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      final controller = Provider.of<IntermedioController>(context, listen: false);
                      await controller.eliminarIntermedio(intermedio.id!);
                      if (controller.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(controller.error!)),
                        );
                      }
                    },
                    onVerDetalle: (intermedio) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IntermedioDetalleScreen(intermedio: intermedio),
                        ),
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
