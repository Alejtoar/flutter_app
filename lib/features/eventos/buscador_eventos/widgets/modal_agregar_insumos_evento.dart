import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

class ModalAgregarInsumosEvento extends StatelessWidget {
  final List<Insumo> insumosIniciales;
  final void Function(List<Insumo>) onGuardar;

  const ModalAgregarInsumosEvento({Key? key, required this.insumosIniciales, required this.onGuardar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InsumoController>(
      builder: (context, insumoCtrl, _) {
        if (insumoCtrl.insumos.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        return ModalAgregarRequeridos<Insumo>(
          titulo: 'Agregar Insumos al Evento',
          requeridosIniciales: insumosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return insumoCtrl.insumos.where((i) => i.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final insumo = item as Insumo;
            return ListTile(
              title: Text(insumo.nombre),
              subtitle: Text(insumo.unidad),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (i) => i.unidad,
          crearRequerido: (item, _) => item as Insumo,
          labelCantidad: '',
          labelBuscar: 'Buscar insumo',
          nombreMostrar: (i) => (i).nombre,
          unidadLabel: null,
        );
      },
    );
  }
}
