import 'package:flutter/material.dart';

class BusquedaBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const BusquedaBar({
    required this.controller,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Buscar intermedio',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
