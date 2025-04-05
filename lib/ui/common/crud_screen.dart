import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget base para pantallas CRUD
class CrudScreen<T, VM extends ChangeNotifier> extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext, VM) listBuilder;
  final Widget Function(BuildContext, VM) formBuilder;
  final Widget? Function(BuildContext, VM)? floatingActionButton;
  final List<Widget> Function(BuildContext, VM)? actions;

  const CrudScreen({
    Key? key,
    required this.title,
    required this.listBuilder,
    required this.formBuilder,
    this.floatingActionButton,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<VM>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: actions?.call(context, viewModel) ?? [],
          ),
          body: Column(
            children: [
              // Barra de búsqueda y filtros
              _buildSearchBar(context, viewModel),
              
              // Lista principal
              Expanded(
                child: listBuilder(context, viewModel),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton?.call(context, viewModel),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, VM viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Implementar búsqueda
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  // Mostrar filtros
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
