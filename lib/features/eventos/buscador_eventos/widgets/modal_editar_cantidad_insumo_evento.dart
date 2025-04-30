import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/insumo_evento.dart';

/// Modal para editar la cantidad de un insumo en un evento.
class ModalEditarCantidadInsumoEvento extends StatefulWidget {
  final InsumoEvento insumoEvento;
  final Insumo insumo;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadInsumoEvento({
    Key? key,
    required this.insumoEvento,
    required this.insumo,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadInsumoEvento> createState() => _ModalEditarCantidadInsumoEventoState();
}

class _ModalEditarCantidadInsumoEventoState extends State<ModalEditarCantidadInsumoEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.insumoEvento.cantidad.toString());
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.insumo.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffixText: widget.insumo.unidad,
              ),
            ),
            const SizedBox(height: 24),
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
                    final nuevaCantidad = double.tryParse(_cantidadController.text);
                    if (nuevaCantidad == null || nuevaCantidad <= 0) return;
                    widget.onGuardar(nuevaCantidad);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
