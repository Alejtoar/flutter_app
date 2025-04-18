import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class IntermedioDetalleScreen extends StatefulWidget {
  final Intermedio intermedio;
  const IntermedioDetalleScreen({Key? key, required this.intermedio})
    : super(key: key);

  @override
  State<IntermedioDetalleScreen> createState() =>
      _IntermedioDetalleScreenState();
}

class _IntermedioDetalleScreenState extends State<IntermedioDetalleScreen> {
  List<InsumoUtilizado> _insumos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      if (insumoCtrl.insumos.isEmpty) {
        await insumoCtrl.cargarInsumos();
      }
      await _loadInsumos();
    });
  }

  Future<void> _loadInsumos() async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    await intermedioCtrl.cargarInsumosUtilizadosPorIntermedio(
      widget.intermedio.id!,
    );
    setState(() {
      _insumos = List.from(intermedioCtrl.insumosUtilizados);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insumoCtrl = Provider.of<InsumoController>(context);
    final categoria =
        widget.intermedio.categorias.isNotEmpty
            ? widget.intermedio.categorias.first
            : '';
    final categoriaInfo = Intermedio.categoriasDisponibles[categoria];
    final categoriaLabel = categoriaInfo?['label'] ?? categoria;
    final categoriaColor = categoriaInfo?['color'] as Color? ?? Colors.grey;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Intermedio')),
      body:
          _loading
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
                            widget.intermedio.nombre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(categoriaLabel),
                          backgroundColor: categoriaColor.withOpacity(0.15),
                          labelStyle: TextStyle(color: categoriaColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.intermedio.codigo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Cantidad: ${widget.intermedio.cantidadEstandar} ${widget.intermedio.unidad}'),
                        const SizedBox(width: 12),
                        Text(
                          'Reducción: ${widget.intermedio.reduccionPorcentaje}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Tiempo preparación: ${widget.intermedio.tiempoPreparacionMinutos} min',
                        ),
                      ],
                    ),
                    if (widget.intermedio.receta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receta:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.intermedio.receta),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Insumos utilizados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _insumos.isEmpty
                        ? const Text('No hay insumos registrados')
                        : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _insumos.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final iu = _insumos[idx];
                            String? unidad;
                            String nombre = iu.insumoId;
                            try {
                              final insumo = insumoCtrl.insumos.firstWhere(
                                (x) => x.id == iu.insumoId,
                              );
                              unidad = insumo.unidad;
                              nombre = insumo.nombre;
                            } catch (_) {}
                            return ListTile(
                              title: Text(nombre),
                              subtitle: Text(
                                'Cantidad: ${iu.cantidad}${unidad != null ? ' $unidad' : ''}',
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }
}
