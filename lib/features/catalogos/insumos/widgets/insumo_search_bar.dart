import 'dart:async';

import 'package:flutter/material.dart';

class InsumoSearchBar extends StatefulWidget {  // Cambiado a StatefulWidget
  final ValueChanged<String> onSearchChanged;
  final Duration debounceDuration;

  const InsumoSearchBar({
    Key? key,
    required this.onSearchChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _InsumoSearchBarState createState() => _InsumoSearchBarState();
}

class _InsumoSearchBarState extends State<InsumoSearchBar> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancelar timer si existe
    _debounceTimer?.cancel();
    
    // Iniciar nuevo timer
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          labelText: 'Buscar insumos',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _debounceTimer?.cancel();
              widget.onSearchChanged('');
              // Necesitarás un controlador para limpiar el TextField
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}