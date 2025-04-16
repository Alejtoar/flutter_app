//selector_categorias.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';

class SelectorCategorias extends StatelessWidget {
  final List<String> seleccionadas;
  final ValueChanged<List<String>> onChanged;
  final bool multiple;
  final bool compacto;
  final bool mostrarContador;

  const SelectorCategorias({
    super.key,
    required this.seleccionadas,
    required this.onChanged,
    this.multiple = true,
    this.compacto = false,
    this.mostrarContador = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return _buildSelectorCompacto(context);
    }
    return _buildSelectorCompleto(context);
  }

  Widget _buildSelectorCompleto(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Insumo.nombresCategorias.map((categoria) {
        final seleccionada = seleccionadas.contains(categoria);
        return FilterChip(
          label: Text(categoria),
          selected: seleccionada,
          onSelected: (selected) {
            final nuevas = List<String>.from(seleccionadas);
            if (selected) {
              if (multiple) {
                nuevas.add(categoria);
              } else {
                nuevas.clear();
                nuevas.add(categoria);
              }
            } else {
              nuevas.remove(categoria);
            }
            onChanged(nuevas);
          },
          avatar: Icon(Insumo.iconoCategoria(categoria)),
          backgroundColor: Colors.grey[200],
          selectedColor: Insumo.colorCategoria(categoria).withOpacity(0.2),
          labelStyle: TextStyle(
            color: seleccionada
                ? Insumo.colorCategoria(categoria)
                : Colors.black,
          ),
        );
      }).toList(),
    );
  }

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
        categories: Insumo.nombresCategorias,
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
    return CheckboxListTile(
      value: _tempSelected.contains(category),
      title: Text(category),
      onChanged: (value) => _handleCategoryToggle(category, value),
      secondary: Icon(Insumo.iconoCategoria(category)),
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