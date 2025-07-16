import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/widgets/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';

class ModalAgregarPlatosEvento extends StatelessWidget {
  final List<PlatoEvento> platosIniciales;
  final void Function(List<PlatoEvento>) onGuardar;

  const ModalAgregarPlatosEvento({
    Key? key,
    required this.platosIniciales,
    required this.onGuardar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatoController>(
      builder: (context, platoCtrl, _) {
        if (platoCtrl.platos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ModalAgregarRequeridos<PlatoEvento>(
          titulo: 'Agregar Platos al Evento',
          requeridosIniciales: platosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return platoCtrl.platos
                .where(
                  (p) => p.nombre.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final plato = item as Plato;
            return ListTile(
              title: Text(plato.nombre),
              subtitle: Text(plato.descripcion),
              trailing:
                  yaAgregado
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            return 'Platos';
          },
          crearRequerido: (item, cantidad) {
            final plato = item as Plato;
            return PlatoEvento(
              id: null,
              eventoId: '', // Se asigna al guardar el plato
              platoId: plato.id!,
              cantidad: cantidad.toInt(),
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar plato',
          nombreMostrar:
              (r) =>
                  platoCtrl.platos
                      .firstWhere(
                        (p) => p.id == r.platoId,
                        orElse:
                            () => Plato(
                              id: r.platoId,
                              codigo: '',
                              nombre: r.platoId,
                              categorias: [],
                              receta: '',
                              fechaCreacion: DateTime.now(),
                              fechaActualizacion: DateTime.now(),
                              activo: true,
                              porcionesMinimas: 1,
                            ),
                      )
                      .nombre,
          subtitleBuilder: (r) {
            //final plato = platoCtrl.platos.firstWhere((p) => p.id == r.platoId, orElse: () => Plato(id: r.platoId, codigo: '', nombre: r.platoId, categorias: [], receta: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true, porcionesMinimas:1));
            final unidad = 'Platos';
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}
