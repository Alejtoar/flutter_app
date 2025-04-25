import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';

class ModalAgregarPlatosEvento extends StatelessWidget {
  final List<Plato> platosIniciales;
  final void Function(List<Plato>) onGuardar;

  const ModalAgregarPlatosEvento({Key? key, required this.platosIniciales, required this.onGuardar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatoController>(
      builder: (context, platoCtrl, _) {
        if (platoCtrl.platos.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        return ModalAgregarRequeridos<Plato>(
          titulo: 'Agregar Platos al Evento',
          requeridosIniciales: platosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return platoCtrl.platos.where((p) => p.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final plato = item as Plato;
            return ListTile(
              title: Text(plato.nombre),
              subtitle: Text(plato.descripcion),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (p) => '',
          crearRequerido: (item, _) => item as Plato,
          labelCantidad: '',
          labelBuscar: 'Buscar plato',
          nombreMostrar: (p) => (p).nombre,
          subtitleBuilder: (p) => p.descripcion,
          unidadLabel: null,
        );
      },
    );
  }
}
