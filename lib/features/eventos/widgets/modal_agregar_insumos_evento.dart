import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/features/common/widgets/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

class ModalAgregarInsumosEvento extends StatelessWidget {
  final List<InsumoEvento> insumosIniciales;
  final void Function(List<InsumoEvento>) onGuardar;

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
        return ModalAgregarRequeridos<InsumoEvento>(
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
          unidadGetter: (item) {
            if (item is Insumo) return item.unidad;
            if (item is InsumoEvento) {
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
            return InsumoEvento(
              id: null,
              eventoId: '', // Se asigna al guardar el plato
              insumoId: insumo.id!,
              cantidad: cantidad,
              unidad: insumo.unidad,
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar insumo',
          nombreMostrar: (r) =>
            insumoCtrl.insumos.firstWhere((i) => i.id == r.insumoId, orElse: () => Insumo(id: r.insumoId, codigo: '', nombre: r.insumoId, categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true)).nombre,
          subtitleBuilder: (r) {
            final insumo = insumoCtrl.insumos.firstWhere((i) => i.id == r.insumoId, orElse: () => Insumo(id: r.insumoId, codigo: '', nombre: r.insumoId, categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true));
            final unidad = insumo.unidad;
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}
