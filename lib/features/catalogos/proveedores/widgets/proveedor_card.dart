import 'package:flutter/material.dart';
import 'package:golo_app/models/proveedor.dart';

class ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ProveedorCard({super.key, required this.proveedor, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text('${proveedor.nombre} (${proveedor.codigo})'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (proveedor.correo.isNotEmpty)
              Text('Correo: ${proveedor.correo}'),
            if (proveedor.telefono.isNotEmpty)
              Text('Teléfono: ${proveedor.telefono}'),
            if (proveedor.tiposInsumos.isNotEmpty)
              Wrap(
                spacing: 4,
                children: proveedor.tiposInsumos.map((cat) {
                  final icono = Proveedor.categoriasInsumos[cat]?['icon'] as IconData?;
                  final color = Proveedor.categoriasInsumos[cat]?['color'] as Color?;
                  return Chip(
                    avatar: icono != null ? Icon(icono, color: color, size: 18) : null,
                    label: Text(cat),
                    backgroundColor: color?.withOpacity(0.2) ?? Colors.grey[200],
                  );
                }).toList(),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
