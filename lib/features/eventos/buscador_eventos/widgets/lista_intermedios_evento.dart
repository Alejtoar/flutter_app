import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import '../../../../models/intermedio_evento.dart';

class ListaIntermediosEvento extends StatelessWidget {
  final List<IntermedioEvento> intermediosEvento;
  final void Function(IntermedioEvento) onEditar;
  final void Function(IntermedioEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaIntermediosEvento({
    Key? key,
    required this.intermediosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (intermediosEvento.isEmpty) {
      return const Center(child: Text('No hay intermedios agregados'));
    }
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        return DataTable(
          columns: const [
            DataColumn(label: Text('Intermedio')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: intermediosEvento.map((ie) {
            String nombre = ie.intermedioId;
            String? unidad;
            try {
              final intermedio = intermedioCtrl.intermedios.firstWhere((x) => x.id == ie.intermedioId);
              nombre = intermedio.nombre;
              unidad = intermedio.unidad;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${ie.cantidad} ${unidad != null ? ' $unidad' : ''}')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(ie),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(ie),
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
