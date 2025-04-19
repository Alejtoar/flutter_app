import 'package:flutter/material.dart';

class BusquedaBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const BusquedaBar({Key? key, required this.controller, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Buscar plato',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
