import 'package:flutter/material.dart';

class BusquedaBarEventos extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const BusquedaBarEventos({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      ),
      onChanged: onChanged,
    );
  }
}
