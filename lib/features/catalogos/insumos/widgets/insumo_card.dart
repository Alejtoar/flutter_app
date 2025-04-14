import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';

class InsumoCard extends StatelessWidget {
  final Insumo insumo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InsumoCard({
    required this.insumo,
    required this.onEdit,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insumo.nombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${insumo.precioUnitario} / ${insumo.unidad}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: Theme.of(context).primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}