import 'package:flutter/material.dart';

import 'package:golo_app/models/plato.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';


import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class PlatoDetalleScreen extends StatefulWidget {
  final Plato plato;
  const PlatoDetalleScreen({Key? key, required this.plato}) : super(key: key);

  @override
  State<PlatoDetalleScreen> createState() => _PlatoDetalleScreenState();
}

class _PlatoDetalleScreenState extends State<PlatoDetalleScreen> {
  bool _loading = true;
  List insumos = [];
  List intermedios = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      final intermedioCtrl = Provider.of<IntermedioController>(context, listen: false);
      final platoCtrl = Provider.of<PlatoController>(context, listen: false);
      if (insumoCtrl.insumos.isEmpty) {
        await insumoCtrl.cargarInsumos();
      }
      if (intermedioCtrl.intermedios.isEmpty) {
        await intermedioCtrl.cargarIntermedios();
      }
      await platoCtrl.cargarRelacionesPorPlato(widget.plato.id!);
      setState(() {
        insumos = List.from(platoCtrl.insumosRequeridos);
        intermedios = List.from(platoCtrl.intermediosRequeridos);
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final categorias = widget.plato.categorias;
    final categoriaLabels = categorias.map((cat) => Plato.categoriasDisponibles[cat]?['nombre'] ?? cat).join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Plato')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.plato.nombre,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Chip(
                        label: Text(categoriaLabels),
                        backgroundColor: Colors.blueGrey.withOpacity(0.15),
                        labelStyle: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.plato.codigo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),

                  if (widget.plato.receta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Receta:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.plato.receta),
                        ],
                      ),
                    ),
                  if (widget.plato.descripcion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.plato.descripcion),
                        ],
                      ),
                    ),

                  if (insumos.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Insumos requeridos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: insumos.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final iu = insumos[idx];
                        String nombre = iu.insumoId;
                        String? unidad;
                        try {
                          final insumo = Provider.of<InsumoController>(context, listen: false).insumos.firstWhere((x) => x.id == iu.insumoId);
                          nombre = insumo.nombre;
                          unidad = insumo.unidad;
                        } catch (_) {}
                        return ListTile(
                          title: Text(nombre),
                          subtitle: Text('Cantidad:  ${iu.cantidad}${unidad != null ? ' $unidad' : ''}'),
                        );
                      },
                    ),
                  ],
                  if (intermedios.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Intermedios requeridos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: intermedios.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final ir = intermedios[idx];
                        String nombre = ir.intermedioId;
                        String? unidad;
                        try {
                          final intermedio = Provider.of<IntermedioController>(context, listen: false).intermedios.firstWhere((x) => x.id == ir.intermedioId);
                          nombre = intermedio.nombre;
                          unidad = intermedio.unidad;
                        } catch (_) {}
                        return ListTile(
                          title: Text(nombre),
                          subtitle: Text('Cantidad:  ${ir.cantidad}${unidad != null ? ' $unidad' : ''}'),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
