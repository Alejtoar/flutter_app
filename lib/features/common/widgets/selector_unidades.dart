import 'package:flutter/material.dart';

/// SelectorUnidades: Dropdown reutilizable para seleccionar unidad de medida.
class SelectorUnidades extends StatelessWidget {
  final String? unidadSeleccionada;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool enabled;

  // Lista de unidades permitidas (extraída del modelo Insumo)
  static const List<String> unidadesPermitidas = [
    'unidad', 'kg', 'gramo', 'litro', 'ml', 'pieza', 'paquete', 'caja', 'botella', 'docena', 'tableta', 'sobre', 'frasco', 'bulto', 'bandeja', 'otro'
  ];

  const SelectorUnidades({
    Key? key,
    required this.unidadSeleccionada,
    required this.onChanged,
    this.label = 'Unidad',
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: unidadesPermitidas.contains(unidadSeleccionada) ? unidadSeleccionada : null,
      items: unidadesPermitidas
          .map((u) => DropdownMenuItem(
                value: u,
                child: Text(u),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) => (value == null || value.isEmpty) ? 'Seleccione una unidad' : null,
    );
  }
}
