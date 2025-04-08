import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/plato.dart';
import '../../../viewmodels/plato_viewmodel.dart';
import 'platos_list.dart';
import 'plato_detail.dart';
import 'plato_form.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({super.key});

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  Plato? _platoSeleccionado;
  String _searchQuery = '';
  String _categoriaSeleccionada = 'Todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPlatos();
    });
  }

  Future<void> _cargarPlatos() async {
    final viewModel = context.read<PlatoViewModel>();
    await viewModel.cargarPlatos(
      activo: _categoriaSeleccionada == 'Todas' ? null : true,
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onCategoriaChanged(String? value) {
    if (value != null) {
      setState(() {
        _categoriaSeleccionada = value;
      });
      _cargarPlatos();
    }
  }

  void _onPlatoSelected(Plato plato) {
    setState(() {
      _platoSeleccionado = plato;
    });
  }

  Future<void> _showPlatoForm(BuildContext context) async {
    final viewModel = context.read<PlatoViewModel>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PlatoForm(
        viewModel: viewModel,
      ),
    );

    if (result == true) {
      viewModel.cargarPlatos();
    }
  }

  void _verDetalles(Plato plato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlatoDetail(
          plato: plato,
        ),
      ),
    );
  }

  void _editarPlato(Plato plato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlatoForm(
          plato: plato,
          viewModel: context.read<PlatoViewModel>(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Plato plato) async {
    if (plato.id == null || plato.id!.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el plato ${plato.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final viewModel = context.read<PlatoViewModel>();
      await viewModel.desactivarPlato(plato.id!);
      await _cargarPlatos();
      setState(() {
        if (_platoSeleccionado?.id == plato.id) {
          _platoSeleccionado = null;
        }
      });
    }
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final viewModel = context.read<PlatoViewModel>();
    final categorias = ['Todas', ...viewModel.categorias];

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar platos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
              controller: TextEditingController(text: _searchQuery),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Categoría',
              ),
              value: _categoriaSeleccionada,
              items: categorias
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: _onCategoriaChanged,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlatoViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlatoForm(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Plato>>(
        stream: viewModel.obtenerPlatos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final platos = snapshot.data!;
          return ListView.builder(
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              return Card(
                child: ListTile(
                  title: Text(plato.nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${plato.codigo}'),
                      Text('Categorías: ${plato.nombresCategorias}'),
                      Text('Porciones mínimas: ${plato.porcionesMinimas}'),
                      Text('Estado: ${plato.activo ? 'Activo' : 'Inactivo'}'),
                    ],
                  ),
                  trailing: Icon(plato.activo ? Icons.check_circle : Icons.cancel),
                  onTap: () => _verDetalles(plato),
                  onLongPress: () => _editarPlato(plato),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
