import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/plato_viewmodel.dart';
import '../../../models/plato.dart';
import 'platos_list.dart';
import 'plato_detail.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({Key? key}) : super(key: key);

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  Plato? _platoSeleccionado;
  String _searchQuery = '';
  String _categoriaSeleccionada = 'Todas';

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatoViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Column(
            children: [
              _buildHeader(context, viewModel),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPlatosList(viewModel),
                    ),
                    if (_platoSeleccionado != null) ...[                      
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 3,
                        child: _buildPlatoDetail(viewModel),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // TODO: Implementar creación de plato
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PlatoViewModel viewModel) {
    final categorias = ['Todas', ...viewModel.categorias];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar platos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _categoriaSeleccionada,
              items: categorias
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _categoriaSeleccionada = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatosList(PlatoViewModel viewModel) {
    final platos = viewModel.platos.where((plato) {
      final matchesSearch = plato.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          plato.codigo.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategoria =
          _categoriaSeleccionada == 'Todas' || plato.categoria == _categoriaSeleccionada;
      return matchesSearch && matchesCategoria;
    }).toList();

    return PlatosList(
      platos: platos,
      onPlatoSelected: (plato) {
        setState(() {
          _platoSeleccionado = plato;
        });
      },
      onPlatoEdit: (plato) {
        // TODO: Implementar edición de plato
      },
      onPlatoDelete: (platoId) {
        // TODO: Implementar eliminación de plato
      },
    );
  }

  Widget _buildPlatoDetail(PlatoViewModel viewModel) {
    if (_platoSeleccionado == null) return const SizedBox.shrink();

    final costos = viewModel.getCostoProduccion(_platoSeleccionado!.id!);
    return PlatoDetail(
      plato: _platoSeleccionado!,
      intermedios: viewModel.getIntermediosRequeridos(_platoSeleccionado!.id!),
      costos: costos,
    );
  }
}
