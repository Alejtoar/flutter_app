import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class ListaIntermediosRequeridos extends StatelessWidget {
  final List<IntermedioRequerido> intermedios;
  final void Function(IntermedioRequerido) onEditar;
  final void Function(IntermedioRequerido) onEliminar;

  const ListaIntermediosRequeridos({
    Key? key,
    required this.intermedios,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (intermedios.isEmpty) {
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
          rows: intermedios.map((ie) {
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
