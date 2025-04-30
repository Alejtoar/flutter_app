import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

class ListaInsumosRequeridos extends StatelessWidget {
  final List<InsumoRequerido> insumos;
  final void Function(InsumoRequerido) onEditar;
  final void Function(InsumoRequerido) onEliminar;

  const ListaInsumosRequeridos({Key? key, required this.insumos, required this.onEditar, required this.onEliminar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insumos.isEmpty) {
      return const Center(child: Text('No hay insumos agregados'));
    }
    return Consumer<InsumoController>(
      builder: (context, insumoCtrl, _) {
        return DataTable(
          columns: const [
            DataColumn(label: Text('Insumo')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: insumos.map((ie) {
            String nombre = ie.insumoId;
            String? unidad;
            try {
              final insumo = insumoCtrl.insumos.firstWhere((x) => x.id == ie.insumoId);
              nombre = insumo.nombre;
              unidad = insumo.unidad;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${ie.cantidad}${unidad != null ? ' $unidad' : ''}')),
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
