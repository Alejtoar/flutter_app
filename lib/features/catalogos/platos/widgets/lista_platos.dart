import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';

class ListaPlatos extends StatelessWidget {
  final List<Plato> platos;
  final ValueChanged<Plato> onVerDetalle;
  final ValueChanged<Plato> onEditar;
  final ValueChanged<Plato> onEliminar;
  const ListaPlatos({
    Key? key,
    required this.platos,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: platos.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final plato = platos[index];
        final icons = plato.categorias.map((cat) => Plato.categoriasDisponibles[cat]?['icon'] as IconData?).whereType<IconData>().toList();
        return Card(
          child: ListTile(
            leading: icons.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: icons.map((icon) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(icon, size: 20),
                    )).toList(),
                  )
                : null,
            title: Text(plato.nombre),
            subtitle: Text('Categorías: ' + plato.categorias.map((cat) => Plato.categoriasDisponibles[cat]?['nombre'] ?? cat).join(', ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalle',
                  onPressed: () => onVerDetalle(plato),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => onEditar(plato),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar',
                  onPressed: () => onEliminar(plato),
                ),
              ],
            ),
            onTap: () => onVerDetalle(plato),
          ),
        );
      },
    );
  }
}
