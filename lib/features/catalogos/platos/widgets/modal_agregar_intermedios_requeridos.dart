import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class ModalAgregarIntermediosRequeridos extends StatelessWidget {
  final List<IntermedioRequerido> intermediosIniciales;
  final void Function(List<IntermedioRequerido>) onGuardar;

  const ModalAgregarIntermediosRequeridos({
    Key? key,
    required this.intermediosIniciales,
    required this.onGuardar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        if (intermedioCtrl.intermedios.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ModalAgregarRequeridos<IntermedioRequerido>(
          titulo: 'Agregar Intermedios al Plato',
          requeridosIniciales: intermediosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            // Solo filtra, no cargues aquí
            return intermedioCtrl.intermedios
                .where(
                  (i) => i.nombre.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final intermedio = item as Intermedio;
            return ListTile(
              title: Text(intermedio.nombre),
              subtitle: Text('Unidad: ${intermedio.unidad}'),
              trailing:
                  yaAgregado
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            if (item is Intermedio) return item.unidad;
            if (item is IntermedioRequerido) {
              final intermedio = intermedioCtrl.intermedios.firstWhere(
                (i) => i.id == item.intermedioId,
                orElse:
                    () => Intermedio(
                      id: '',
                      codigo: '',
                      nombre: '',
                      categorias: [],
                      unidad: '',
                      cantidadEstandar: 0,
                      reduccionPorcentaje: 0,
                      receta: '',
                      tiempoPreparacionMinutos: 0,
                      fechaCreacion: DateTime.now(),
                      fechaActualizacion: DateTime.now(),
                      activo: true,
                    ),
              );
              return intermedio.unidad;
            }
            return '';
          },
          crearRequerido: (item, cantidad) {
            final intermedio = item as Intermedio;
            return IntermedioRequerido(
              id: null,
              platoId: '', // Se asigna al guardar el plato
              intermedioId: intermedio.id!,
              cantidad: cantidad,
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar intermedio',
          nombreMostrar:
              (r) =>
                  intermedioCtrl.intermedios
                      .firstWhere(
                        (i) => i.id == r.intermedioId,
                        orElse:
                            () => Intermedio(
                              id: r.intermedioId,
                              codigo: '',
                              nombre: r.intermedioId,
                              categorias: [],
                              unidad: '',
                              cantidadEstandar: 0,
                              reduccionPorcentaje: 0,
                              receta: '',
                              tiempoPreparacionMinutos: 0,
                              fechaCreacion: DateTime.now(),
                              fechaActualizacion: DateTime.now(),
                              activo: true,
                            ),
                      )
                      .nombre,
          subtitleBuilder: (r) {
            final intermedio = intermedioCtrl.intermedios.firstWhere(
              (i) => i.id == r.intermedioId,
              orElse:
                  () => Intermedio(
                    id: r.intermedioId,
                    codigo: '',
                    nombre: r.intermedioId,
                    categorias: [],
                    unidad: '',
                    cantidadEstandar: 0,
                    reduccionPorcentaje: 0,
                    receta: '',
                    tiempoPreparacionMinutos: 0,
                    fechaCreacion: DateTime.now(),
                    fechaActualizacion: DateTime.now(),
                    activo: true,
                  ),
            );
            final unidad = intermedio.unidad;
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}
