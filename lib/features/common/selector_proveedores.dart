import 'package:flutter/material.dart';
import 'package:golo_app/models/proveedor.dart';

/// Widget reutilizable para seleccionar un proveedor de una lista.
/// Si se usa en un formulario, puede integrarse con un FormField.
class SelectorProveedores extends StatelessWidget {
  final List<Proveedor> proveedores;
  final Proveedor? proveedorSeleccionado;
  final ValueChanged<Proveedor?> onChanged;
  final String? label;
  final bool isExpanded;
  final bool enabled;

  const SelectorProveedores({
    super.key,
    required this.proveedores,
    required this.proveedorSeleccionado,
    required this.onChanged,
    this.label,
    this.isExpanded = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Proveedor>(
      value: proveedorSeleccionado,
      isExpanded: isExpanded,
      // enabled: enabled,
      decoration: InputDecoration(
        labelText: label ?? 'Proveedor',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: proveedores.map((proveedor) {
        return DropdownMenuItem<Proveedor>(
          value: proveedor,
          child: Text(proveedor.nombre),
        );
      }).toList(),
      onChanged: onChanged,
      // validator: (value) {
      //   // Solo valida si está en un Form
      //   if (!enabled) return null;
      //   if (value == null) {
      //     return 'Selecciona un proveedor';
      //   }
      //   return null;
      // },
    );
  }
}
