import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/viewmodels/plato_viewmodel.dart';
import 'package:golo_app/ui/screens/platos/plato_form.dart';
import 'package:golo_app/ui/screens/platos/plato_detail.dart';
import 'package:golo_app/ui/screens/platos/platos_list.dart';

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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PlatoForm(),
    );

    if (result == true) {
      await _cargarPlatos();
    }
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
    final platos = viewModel.platos
        .where((p) =>
            p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: PlatosList(
              platos: platos,
              onPlatoSelected: _onPlatoSelected,
              onPlatoDeleted: (plato) => _confirmDelete(context, plato),
            ),
          ),
          if (_platoSeleccionado != null) ...[
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: PlatoDetail(
                plato: _platoSeleccionado!,
                intermedios: _platoSeleccionado!.intermedios,
                costos: {
                  'costoTotal': _platoSeleccionado!.costoTotal,
                  'precioVenta': _platoSeleccionado!.precioVenta,
                  'costoDirecto': _platoSeleccionado!.costoTotal * 0.7, // 70% directo
                  'costoIndirecto': _platoSeleccionado!.costoTotal * 0.2, // 20% indirecto
                  'costoAdicional': _platoSeleccionado!.costoTotal * 0.1, // 10% adicional
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlatoForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
