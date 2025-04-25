import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class ModalAgregarIntermediosEvento extends StatelessWidget {
  final List<Intermedio> intermediosIniciales;
  final void Function(List<Intermedio>) onGuardar;

  const ModalAgregarIntermediosEvento({Key? key, required this.intermediosIniciales, required this.onGuardar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        if (intermedioCtrl.intermedios.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        return ModalAgregarRequeridos<Intermedio>(
          titulo: 'Agregar Intermedios al Evento',
          requeridosIniciales: intermediosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return intermedioCtrl.intermedios.where((i) => i.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final intermedio = item as Intermedio;
            return ListTile(
              title: Text(intermedio.nombre),
              subtitle: Text(intermedio.unidad),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (i) => i.unidad,
          crearRequerido: (item, _) => item as Intermedio,
          labelCantidad: '',
          labelBuscar: 'Buscar intermedio',
          nombreMostrar: (i) => (i).nombre,
          subtitleBuilder: (i) => 'Unidad: ${i.unidad}',
          unidadLabel: null,
        );
      },
    );
  }
}
