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
        return ListView.builder(
          itemCount: insumos.length,
          itemBuilder: (context, idx) {
            final iu = insumos[idx];
            String nombre = iu.insumoId;
            String? unidad;
            try {
              final insumo = insumoCtrl.insumos.firstWhere((x) => x.id == iu.insumoId);
              nombre = insumo.nombre;
              unidad = insumo.unidad;
            } catch (_) {}
            return ListTile(
              title: Text(nombre),
              subtitle: Text('Cantidad: ${iu.cantidad}${unidad != null ? ' $unidad' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => onEditar(iu)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => onEliminar(iu)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
