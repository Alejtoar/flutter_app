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
        onTap: onTap,
      ),
    );
  }
}
