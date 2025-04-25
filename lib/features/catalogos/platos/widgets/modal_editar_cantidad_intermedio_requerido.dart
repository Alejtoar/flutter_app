import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/intermedio_requerido.dart';

/// Modal para editar la cantidad de un intermedio requerido en un plato.
class ModalEditarCantidadIntermedioRequerido extends StatefulWidget {
  final IntermedioRequerido intermedioRequerido;
  final Intermedio intermedio;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadIntermedioRequerido({
    Key? key,
    required this.intermedioRequerido,
    required this.intermedio,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadIntermedioRequerido> createState() => _ModalEditarCantidadIntermedioRequeridoState();
}

class _ModalEditarCantidadIntermedioRequeridoState extends State<ModalEditarCantidadIntermedioRequerido> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController();
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
              widget.intermedio.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: widget.intermedioRequerido.cantidad.toString(),
                suffixText: widget.intermedio.unidad,
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
