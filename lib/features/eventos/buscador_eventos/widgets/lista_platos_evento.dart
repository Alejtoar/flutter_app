import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_agregar_platos_evento.dart';
import 'package:golo_app/models/plato.dart';
import '../../../common/item_contenedor_evento.dart';

class ListaPlatosEvento extends StatelessWidget {
  final List<Plato> platos;
  final void Function(Plato) onEditar;
  final void Function(Plato) onEliminar;
  final void Function(List<Plato>)? onAgregar;

  const ListaPlatosEvento({
    Key? key,
    required this.platos,
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
            const Text('Platos del evento', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar plato',
              onPressed: () async {
                final nuevosPlatos = await showDialog<List<Plato>>(
                  context: context,
                  builder: (_) => ModalAgregarPlatosEvento(
                    platosIniciales: platos,
                    onGuardar: (seleccionados) => Navigator.of(context).pop(seleccionados),
                  ),
                );
                if (nuevosPlatos != null && onAgregar != null) {
                  onAgregar!(nuevosPlatos);
                }
              },
            ),
          ],
        ),
        if (platos.isEmpty)
          const Text('No hay platos agregados')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: platos.length,
            itemBuilder: (context, idx) {
              final p = platos[idx];
              return ItemContenedorEvento(
                nombre: p.toString(), // TODO: mostrar nombre real
                onEditar: () => onEditar(p),
                onEliminar: () => onEliminar(p),
              );
            },
          ),
      ],
    );
  }
}
