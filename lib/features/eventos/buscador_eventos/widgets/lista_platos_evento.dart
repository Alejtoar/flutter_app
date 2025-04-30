import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import '../../../../models/plato_evento.dart';

class ListaPlatosEvento extends StatelessWidget {
  final List<PlatoEvento> platosEvento;
  final void Function(PlatoEvento) onEditar;
  final void Function(PlatoEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaPlatosEvento({
    Key? key,
    required this.platosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (platosEvento.isEmpty) {
      return const Center(child: Text('No hay platos agregados'));
    }
    return Builder(
      builder: (context) {
        final platoCtrl = Provider.of<PlatoController>(context, listen: true);
        return DataTable(
          columns: const [
            DataColumn(label: Text('Plato')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: platosEvento.map((pe) {
            String nombre = pe.platoId;
            try {
              final plato = platoCtrl.platos.firstWhere((x) => x.id == pe.platoId);
              nombre = plato.nombre;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${pe.cantidad} Platos')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(pe),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(pe),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
