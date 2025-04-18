import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

/// Widget que muestra una tabla/lista de insumos utilizados para un intermedio.
/// Permite editar/eliminar cada insumo y muestra cantidad y unidad.
class ListaInsumosUtilizados extends StatelessWidget {
  final List<InsumoUtilizado> insumosUtilizados;
  final void Function(InsumoUtilizado) onEditar;
  final void Function(InsumoUtilizado) onEliminar;

  const ListaInsumosUtilizados({
    Key? key,
    required this.insumosUtilizados,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insumosUtilizados.isEmpty) {
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
          rows: insumosUtilizados.map((iu) {
            String nombre = iu.insumoId;
            String? unidad;
            try {
              final insumo = insumoCtrl.insumos.firstWhere((x) => x.id == iu.insumoId);
              nombre = insumo.nombre;
              unidad = insumo.unidad;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${iu.cantidad}${unidad != null ? ' $unidad' : ''}')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(iu),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(iu),
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
