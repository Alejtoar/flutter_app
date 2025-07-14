import 'package:flutter/material.dart';

class ListaComponentesRequeridos<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) nombreGetter;
  final String Function(T item) cantidadGetter;
  final Function(T item)? onEditar;
  final Function(T item)? onEliminar;
  final Function(T item)? onPersonalizar;
  final String emptyListText;

  const ListaComponentesRequeridos({
    Key? key,
    required this.items,
    required this.nombreGetter,
    required this.cantidadGetter,
    this.onEditar,
    this.onEliminar,
    this.onPersonalizar,
    this.emptyListText = "No hay items agregados",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
          child: Text(emptyListText, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    // Envolver el DataTable en SingleChildScrollView para hacerlo scrollable
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16, // Ajustar espaciado de columnas
        columns: const [
          DataColumn(label: Text('Componente')),
          DataColumn(label: Text('Cantidad')),
          DataColumn(label: Text('Acciones'), numeric: true), // Alinear a la derecha
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(nombreGetter(item))),
              DataCell(Text(cantidadGetter(item))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onPersonalizar != null)
                      IconButton(
                        icon: const Icon(Icons.tune),
                        iconSize: 20,
                        tooltip: 'Personalizar',
                        onPressed: () => onPersonalizar!(item),
                      ),
                    if (onEditar != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 20,
                        tooltip: 'Editar Cantidad',
                        onPressed: () => onEditar!(item),
                      ),
                    if (onEliminar != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                        tooltip: 'Eliminar',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => onEliminar!(item),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}