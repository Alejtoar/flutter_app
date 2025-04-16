import 'package:flutter/material.dart';

class InsumoSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  
  const InsumoSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar insumo...',
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: onChanged,
      ),
    );
  }
}