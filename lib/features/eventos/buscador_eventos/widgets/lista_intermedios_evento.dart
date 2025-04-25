import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_agregar_intermedios_evento.dart';
import '../../../common/item_contenedor_evento.dart';
import '../../../../models/intermedio.dart';

class ListaIntermediosEvento extends StatelessWidget {
  final List<Intermedio> intermedios;
  final void Function(Intermedio) onEditar;
  final void Function(Intermedio) onEliminar;
  final void Function(List<Intermedio>)? onAgregar;

  const ListaIntermediosEvento({
    Key? key,
    required this.intermedios,
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
            const Text('Intermedios del evento', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar intermedio',
              onPressed: () async {
                final nuevosIntermedios = await showDialog<List<Intermedio>>(
                  context: context,
                  builder: (_) => ModalAgregarIntermediosEvento(
                    intermediosIniciales: intermedios,
                    onGuardar: (seleccionados) => Navigator.of(context).pop(seleccionados),
                  ),
                );
                if (nuevosIntermedios != null && onAgregar != null) {
                  onAgregar!(nuevosIntermedios);
                }
              },
            ),
          ],
        ),
        if (intermedios.isEmpty)
          const Text('No hay intermedios agregados.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: intermedios.length,
            itemBuilder: (context, index) {
              final intermedio = intermedios[index];
              return ItemContenedorEvento(
                nombre: intermedio.nombre,
                onEditar: () => onEditar(intermedio),
                onEliminar: () => onEliminar(intermedio),
              );
            },
          ),
      ],
    );
  }
}
