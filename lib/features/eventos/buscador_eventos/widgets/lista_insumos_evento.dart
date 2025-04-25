import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import '../../../../models/insumo_evento.dart';

class ListaInsumosEvento extends StatelessWidget {
  final List<InsumoEvento> insumosEvento;
  final void Function(InsumoEvento) onEditar;
  final void Function(InsumoEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaInsumosEvento({
    Key? key,
    required this.insumosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insumosEvento.isEmpty) {
      return const Center(child: Text('No hay insumos agregados'));
    }
    return Builder(
      builder: (context) {
        final insumoCtrl = Provider.of<InsumoController>(context, listen: true);
        return DataTable(
          columns: const [
            DataColumn(label: Text('Insumo')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: insumosEvento.map((ie) {
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
