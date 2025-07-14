import 'package:flutter/material.dart';

class ItemContenedorEvento extends StatelessWidget {
  final String nombre;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final Widget? leading;
  final Widget? trailing;

  const ItemContenedorEvento({
    Key? key,
    required this.nombre,
    required this.onEditar,
    required this.onEliminar,
    this.leading,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: leading,
        title: Text(nombre),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEditar,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onEliminar,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
