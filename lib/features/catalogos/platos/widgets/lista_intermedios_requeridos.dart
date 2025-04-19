import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class ListaIntermediosRequeridos extends StatelessWidget {
  final List<IntermedioRequerido> intermedios;
  final void Function(IntermedioRequerido) onEditar;
  final void Function(IntermedioRequerido) onEliminar;

  const ListaIntermediosRequeridos({Key? key, required this.intermedios, required this.onEditar, required this.onEliminar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (intermedios.isEmpty) {
      return const Center(child: Text('No hay intermedios agregados'));
    }
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        return ListView.builder(
          itemCount: intermedios.length,
          itemBuilder: (context, idx) {
            final ir = intermedios[idx];
            String nombre = ir.intermedioId;
            String? unidad;
            try {
              final intermedio = intermedioCtrl.intermedios.firstWhere((x) => x.id == ir.intermedioId);
              nombre = intermedio.nombre;
              unidad = intermedio.unidad;
            } catch (_) {}
            return ListTile(
              title: Text(nombre),
              subtitle: Text('Cantidad: ${ir.cantidad}${unidad != null ? ' $unidad' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => onEditar(ir)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => onEliminar(ir)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
