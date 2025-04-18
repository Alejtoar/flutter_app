import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

/// Modal que permite buscar, seleccionar y agregar varios insumos con cantidad a un intermedio.
/// Muestra la unidad del insumo como hint o label en el campo de cantidad.
class ModalAgregarInsumos extends StatefulWidget {
  final List<InsumoUtilizado> insumosIniciales;
  final void Function(List<InsumoUtilizado>) onGuardar;

  const ModalAgregarInsumos({
    Key? key,
    required this.insumosIniciales,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalAgregarInsumos> createState() => _ModalAgregarInsumosState();
}

class _ModalAgregarInsumosState extends State<ModalAgregarInsumos> {
  final List<InsumoUtilizado> _insumosSeleccionados = [];
  Insumo? _insumoActual;
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _insumosSeleccionados.addAll(widget.insumosIniciales);
    // Forzar carga de insumos si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      if (insumoCtrl.insumos.isEmpty) {
        insumoCtrl.cargarInsumos();
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  void _agregarInsumo(Insumo insumo) {
    setState(() {
      _insumoActual = insumo;
      _cantidadController.text = '';
    });
  }

  void _confirmarAgregar() {
    if (_insumoActual == null) return;
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) return;
    final yaExiste = _insumosSeleccionados.any((iu) => iu.insumoId == _insumoActual!.id);
    if (yaExiste) return;
    setState(() {
      _insumosSeleccionados.add(
        InsumoUtilizado(
          insumoId: _insumoActual!.id!,
          intermedioId: '', // Se asigna al guardar el intermedio
          cantidad: cantidad,
        ),
      );
      _insumoActual = null;
      _cantidadController.clear();
    });
  }

  void _eliminarInsumo(InsumoUtilizado iu) {
    setState(() {
      _insumosSeleccionados.removeWhere((x) => x.insumoId == iu.insumoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InsumoController>(
      builder: (context, insumoCtrl, _) {
          final insumos = insumoCtrl.insumosFiltrados;
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Agregar Insumos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Buscar insumo'),
                    onChanged: (value) {
                      insumoCtrl.buscarInsumos(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_insumoActual == null) ...[
                    SizedBox(
                      height: 180,
                      child: insumoCtrl.loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: insumos.length,
                              itemBuilder: (context, idx) {
                                final insumo = insumos[idx];
                                final yaAgregado = _insumosSeleccionados.any((iu) => iu.insumoId == insumo.id);
                                return ListTile(
                                  title: Text(insumo.nombre),
                                  subtitle: Text('Unidad: ${insumo.unidad}'),
                                  trailing: yaAgregado
                                      ? const Icon(Icons.check, color: Colors.green)
                                      : null,
                                  onTap: yaAgregado ? null : () => _agregarInsumo(insumo),
                                );
                              },
                            ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: Text(_insumoActual!.nombre)),
                        Text('Unidad: ${_insumoActual!.unidad}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                    TextField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        hintText: _insumoActual!.unidad,
                        suffixText: _insumoActual!.unidad,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _confirmarAgregar,
                          child: const Text('Agregar'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => setState(() => _insumoActual = null),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(thickness: 1),
                  Text('Insumos agregados:', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: _insumosSeleccionados.length,
                      itemBuilder: (context, idx) {
                        final iu = _insumosSeleccionados[idx];
                        // Solución nativa para buscar el insumo por id, null si no existe
                        Insumo? insumo;
                        try {
                          insumo = insumoCtrl.insumos.firstWhere((x) => x.id == iu.insumoId);
                        } catch (_) {
                          insumo = null;
                        }
                        return ListTile(
                          title: Text(insumo?.nombre ?? iu.insumoId),
                          subtitle: Text('Cantidad: ${iu.cantidad} ${insumo?.unidad ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _eliminarInsumo(iu),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          widget.onGuardar(_insumosSeleccionados);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
  }
}
