import 'package:flutter/material.dart';
import '../../../models/plato.dart';

class PlatoCard extends StatelessWidget {
  final Plato plato;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PlatoCard({
    Key? key,
    required this.plato,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plato.nombre,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (!plato.activo)
                    Chip(
                      label: Text('Inactivo'),
                      backgroundColor: Colors.grey[300],
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                plato.descripcion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Costo: \$${plato.costoTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Precio: \$${plato.precioVenta.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: onTap,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              if (plato.categorias.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: plato.categorias.map((categoria) => Chip(
                    label: Text(categoria),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
