//selector_categorias.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/plato.dart';

class SelectorCategorias extends StatelessWidget {
  final List<String> categorias;
  final List<String> seleccionadas;
  final ValueChanged<List<String>> onChanged;
  final bool multiple;
  final bool mostrarContador;

  const SelectorCategorias({
    super.key,
    required this.seleccionadas,
    required this.onChanged,
    this.categorias = const [],
    this.multiple = true,
    this.mostrarContador = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSelectorCompacto(context);
  }

  List<String> get _categorias => categorias.isNotEmpty ? categorias : Insumo.nombresCategorias;

  Widget _buildSelectorCompacto(BuildContext context) {
    return Column(
      children: [
        if (mostrarContador && seleccionadas.isNotEmpty)
          Text(
            '${seleccionadas.length} categorías seleccionadas',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        _buildPopupSelector(context),
      ],
    );
  }

  Widget _buildPopupSelector(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [_buildPopupContent(context)],
      child: _buildChip(),
    );
  }

  PopupMenuItem<String> _buildPopupContent(BuildContext context) {
    return PopupMenuItem(
      height: 0,
      padding: EdgeInsets.zero,
      child: _CategorySelector(
        categories: _categorias,
        selected: seleccionadas,
        multiple: multiple,
        onSelectionChanged: onChanged,
      ),
    );
  }

  Widget _buildChip() {
    return Chip(
      avatar: Icon(Icons.category),
      label: Text(
        seleccionadas.isEmpty
            ? 'Seleccionar categorías'
            : 'Categorías (${seleccionadas.length})',
      ),
    );
  }
}

class _CategorySelector extends StatefulWidget {
  final List<String> categories;
  final List<String> selected;
  final bool multiple;
  final Function(List<String>) onSelectionChanged;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.multiple,
    required this.onSelectionChanged,
  });

  @override
  _CategorySelectorState createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.categories.map(_buildCategoryItem).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    // Detecta si son categorías de Intermedio o Plato
    final isIntermedio = widget.categories.isNotEmpty && widget.categories.every((cat) => Intermedio.categoriasDisponibles.containsKey(cat));
    final isPlato = widget.categories.isNotEmpty && widget.categories.every((cat) => Plato.categoriasDisponibles.containsKey(cat));
    final icon = isIntermedio
        ? (Intermedio.categoriasDisponibles[category]?['icon'] as IconData? ?? Icons.category)
        : isPlato
          ? (Plato.categoriasDisponibles[category]?['icon'] as IconData? ?? Icons.category)
          : Insumo.iconoCategoria(category);
    return CheckboxListTile(
      value: _tempSelected.contains(category),
      title: Text(category),
      onChanged: (value) => _handleCategoryToggle(category, value),
      secondary: Icon(icon),
    );
  }

  void _handleCategoryToggle(String category, bool? value) {
    setState(() {
      if (value == true) {
        if (!widget.multiple && _tempSelected.isNotEmpty) {
          _tempSelected.clear();
        }
        if (!_tempSelected.contains(category)) {
          _tempSelected.add(category);
        }
      } else {
        _tempSelected.remove(category);
      }
    });
    widget.onSelectionChanged(List.from(_tempSelected));
  }
}