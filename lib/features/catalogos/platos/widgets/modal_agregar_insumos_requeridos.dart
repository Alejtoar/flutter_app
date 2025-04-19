import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

class ModalAgregarInsumosRequeridos extends StatelessWidget {
  final List<InsumoRequerido> insumosIniciales;
  final void Function(List<InsumoRequerido>) onGuardar;

  const ModalAgregarInsumosRequeridos({Key? key, required this.insumosIniciales, required this.onGuardar}) : super(key: key);

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
        return ModalAgregarRequeridos<InsumoRequerido>(
          titulo: 'Agregar Insumos Requeridos',
          requeridosIniciales: insumosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            // Solo filtra, no cargues aquí
            return insumoCtrl.insumos.where((i) => i.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final insumo = item as Insumo;
            return ListTile(
              title: Text(insumo.nombre),
              subtitle: Text('Unidad: ${insumo.unidad}'),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            if (item is Insumo) return item.unidad;
            if (item is InsumoRequerido) {
              final insumo = insumoCtrl.insumos.firstWhere(
                (i) => i.id == item.insumoId,
                orElse: () => Insumo(
                  id: '', codigo: '', nombre: '', categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true
                ),
              );
              return insumo.unidad;
            }
            return '';
          },
          crearRequerido: (item, cantidad) {
            final insumo = item as Insumo;
            return InsumoRequerido(
              id: null,
              platoId: '', // Se asigna al guardar el plato
              insumoId: insumo.id!,
              cantidad: cantidad,
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar insumo',
          nombreMostrar: (r) =>
            insumoCtrl.insumos.firstWhere((i) => i.id == r.insumoId, orElse: () => Insumo(id: r.insumoId, codigo: '', nombre: r.insumoId, categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true)).nombre,
          unidadLabel: null,
        );
      },
    );
  }
}
