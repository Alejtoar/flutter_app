import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/intermedio_evento.dart';

/// Modal para editar la cantidad de un intermedio en un evento.
class ModalEditarCantidadIntermedioEvento extends StatefulWidget {
  final IntermedioEvento intermedioEvento;
  final Intermedio intermedio;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadIntermedioEvento({
    Key? key,
    required this.intermedioEvento,
    required this.intermedio,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadIntermedioEvento> createState() => _ModalEditarCantidadIntermedioEventoState();
}

class _ModalEditarCantidadIntermedioEventoState extends State<ModalEditarCantidadIntermedioEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.intermedioEvento.cantidad.toString());
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
