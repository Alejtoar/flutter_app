import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';

class ListaIntermedios extends StatelessWidget {
  final List<Intermedio> intermedios;
  final ValueChanged<Intermedio> onEditar;
  final ValueChanged<Intermedio> onEliminar;
  final ValueChanged<Intermedio> onVerDetalle;
  const ListaIntermedios({
    required this.intermedios,
    required this.onEditar,
    required this.onEliminar,
    required this.onVerDetalle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: intermedios.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final intermedio = intermedios[index];
        return Card(
          child: ListTile(
            leading: Icon(
              (intermedio.categorias.isNotEmpty
                  ? (Intermedio.categoriasDisponibles[intermedio.categorias.first]?['icon'] ?? Icons.category)
                  : Icons.category),
              color: (intermedio.categorias.isNotEmpty
                  ? (Intermedio.categoriasDisponibles[intermedio.categorias.first]?['color'] ?? Colors.grey)
                  : Colors.grey),
            ),
            title: Text(intermedio.nombre),
            subtitle: Text('Categoría: ${intermedio.categorias.join(', ')}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalle',
                  onPressed: () => onVerDetalle(intermedio),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => onEditar(intermedio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar',
                  onPressed: () => onEliminar(intermedio),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
