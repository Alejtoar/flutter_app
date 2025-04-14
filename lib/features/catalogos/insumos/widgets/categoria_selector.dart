import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';

class CategoriaSelector extends StatefulWidget {
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;

  const CategoriaSelector({
    required this.onChanged,
    this.initialSelection = const [],
    Key? key,
  }) : super(key: key);

  @override
  _CategoriaSelectorState createState() => _CategoriaSelectorState();
}

class _CategoriaSelectorState extends State<CategoriaSelector> {
  late List<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.initialSelection);
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      widget.onChanged(_selectedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Insumo.categoriasInsumos.entries.map((entry) {
        final categoria = entry.key;
        final icon = entry.value['icon'] as IconData;
        final color = entry.value['color'] as Color;

        return FilterChip(
          selected: _selectedCategories.contains(categoria),
          onSelected: (_) => _toggleCategory(categoria),
          label: Text(categoria),
          avatar: Icon(icon, color: color),
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
          showCheckmark: true,
        );
      }).toList(),
    );
  }
}