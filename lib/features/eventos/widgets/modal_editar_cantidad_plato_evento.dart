import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';

/// Modal para editar la cantidad de un plato en un evento.
class ModalEditarCantidadPlatoEvento extends StatefulWidget {
  final PlatoEvento platoEvento;
  final Plato plato;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadPlatoEvento({
    Key? key,
    required this.platoEvento,
    required this.plato,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadPlatoEvento> createState() => _ModalEditarCantidadPlatoEventoState();
}

class _ModalEditarCantidadPlatoEventoState extends State<ModalEditarCantidadPlatoEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.platoEvento.cantidad.toString());
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
              widget.plato.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
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
