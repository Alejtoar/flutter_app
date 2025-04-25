import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_agregar_insumos_evento.dart';
import '../../../common/item_contenedor_evento.dart';
import '../../../../models/insumo.dart';

class ListaInsumosEvento extends StatelessWidget {
  final List<Insumo> insumos;
  final void Function(Insumo) onEditar;
  final void Function(Insumo) onEliminar;
  final void Function(List<Insumo>)? onAgregar;

  const ListaInsumosEvento({
    Key? key,
    required this.insumos,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Insumos del evento', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar insumo',
              onPressed: () async {
                final nuevosInsumos = await showDialog<List<Insumo>>(
                  context: context,
                  builder: (_) => ModalAgregarInsumosEvento(
                    insumosIniciales: insumos,
                    onGuardar: (seleccionados) => Navigator.of(context).pop(seleccionados),
                  ),
                );
                if (nuevosInsumos != null && onAgregar != null) {
                  onAgregar!(nuevosInsumos);
                }
              },
            ),
          ],
        ),
        if (insumos.isEmpty)
          const Text('No hay insumos agregados.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: insumos.length,
            itemBuilder: (context, index) {
              final insumo = insumos[index];
              return ItemContenedorEvento(
                nombre: insumo.nombre,
                onEditar: () => onEditar(insumo),
                onEliminar: () => onEliminar(insumo),
              );
            },
          ),
      ],
    );
  }
}
