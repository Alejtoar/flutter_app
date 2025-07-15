import 'package:flutter/material.dart';

// Callback que construye el widget para un item.
// Recibe el item, si está seleccionado, y un callback para el tap.
typedef GenericListItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isSelected, VoidCallback onTap);

// Callback para cuando la selección cambia.
typedef OnSelectionChanged<T> = void Function(Set<String> selectedIds);

class GenericListView<T> extends StatefulWidget {
  final List<T> items;
  // Función para obtener el ID único de cada item (necesario para la selección)
  final String Function(T item) idGetter;
  // Función que construye el widget de cada fila
  final GenericListItemBuilder<T> itemBuilder;
  // Callback para cuando cambia la selección múltiple
  final OnSelectionChanged<T> onSelectionChanged;
  // Callback para cuando se activa/desactiva el modo de selección
  final ValueChanged<bool> onSelectionModeChanged;

  const GenericListView({
    Key? key,
    required this.items,
    required this.idGetter,
    required this.itemBuilder,
    required this.onSelectionChanged,
    required this.onSelectionModeChanged,
  }) : super(key: key);

  @override
  State<GenericListView<T>> createState() => _GenericListViewState<T>();
}

class _GenericListViewState<T> extends State<GenericListView<T>> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      
      // Si ya no hay items seleccionados, salir del modo selección
      if (_selectedIds.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
        widget.onSelectionModeChanged(false); // Notificar a la pantalla padre
      }
      // Si se selecciona el primer item, entrar en modo selección
      else if (_selectedIds.isNotEmpty && !_isSelectionMode) {
        _isSelectionMode = true;
        widget.onSelectionModeChanged(true); // Notificar a la pantalla padre
      }
      
      widget.onSelectionChanged(_selectedIds); // Notificar los IDs seleccionados
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final id = widget.idGetter(item);
        final isSelected = _selectedIds.contains(id);

        // Envolver el item del builder en un InkWell para gestionar taps y long press
        return InkWell(
          onLongPress: () {
            // Activar modo selección y seleccionar este item
            if (!_isSelectionMode) {
               _toggleSelection(id);
            }
          },
          onTap: () {
            // Si estamos en modo selección, el tap selecciona/deselecciona.
            // Si no, podría ejecutar una acción por defecto (ver detalle).
            if (_isSelectionMode) {
              _toggleSelection(id);
            } else {
              // Aquí podrías tener un callback onDefaultTap si quieres
              // widget.onDefaultTap(item);
              // Por ahora, el tap normal no hace nada si no estamos en selección
            }
          },
          child: Container(
             // Cambiar color de fondo si está seleccionado
             color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : null,
             child: widget.itemBuilder(context, item, isSelected, () => _toggleSelection(id)),
          ),
        );
      },
    );
  }
}