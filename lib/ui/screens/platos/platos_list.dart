import 'package:flutter/material.dart';
import '../../../models/plato.dart';

class PlatosList extends StatelessWidget {
  final List<Plato> platos;
  final Function(Plato) onPlatoSelected;
  final Function(Plato)? onPlatoEdit;
  final Function(String)? onPlatoDelete;

  const PlatosList({
    Key? key,
    required this.platos,
    required this.onPlatoSelected,
    this.onPlatoEdit,
    this.onPlatoDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: platos.length,
      itemBuilder: (context, index) {
        final plato = platos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                plato.nombre.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            title: Text(plato.nombre),
            subtitle: Text(
              'Código: ${plato.codigo} - Categoría: ${plato.categoria}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${plato.precioVenta.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onPlatoEdit != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onPlatoEdit!(plato),
                  ),
                ],
                if (onPlatoDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onPlatoDelete!(plato.id!),
                  ),
                ],
              ],
            ),
            onTap: () => onPlatoSelected(plato),
          ),
        );
      },
    );
  }
}
