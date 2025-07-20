import 'dart:async';

import 'package:flutter/material.dart';
import 'package:golo_app/navigation/models/menu_item.dart';

/// Tipo de callback para la navegación a sub-ítems
typedef SubItemNavCallback = void Function(String route);

/// Widget que representa un ítem en la barra lateral de navegación.
/// 
/// Muestra un elemento de menú con soporte para sub-ítems desplegables,
/// estados de selección y efectos visuales al pasar el ratón.
class HoverRailItem extends StatefulWidget {
  /// Elemento del menú a mostrar
  final MenuItem menuItem;
  
  /// Indica si este ítem está actualmente seleccionado
  final bool isSelected;
  
  /// Indica si el panel lateral está expandido
  final bool isExpanded;
  
  /// Callback que se ejecuta cuando se selecciona el ítem
  final VoidCallback onSelect;
  
  /// Callback que se ejecuta cuando se selecciona un sub-ítem
  final SubItemNavCallback onSubItemSelect;

  /// Crea una instancia de HoverRailItem
  const HoverRailItem({
    Key? key,
    required this.menuItem,
    required this.isSelected,
    required this.isExpanded,
    required this.onSelect,
    required this.onSubItemSelect,
  }) : super(key: key);

  @override
  State<HoverRailItem> createState() => _HoverRailItemState();
}

class _HoverRailItemState extends State<HoverRailItem> {
  /// Controlador para gestionar la visualización del menú flotante
  final _overlayController = OverlayPortalController();
  
  /// Vínculo que conecta la posición del botón con el menú flotante
  final _layerLink = LayerLink();

  /// Timer para gestionar el cierre automático del menú
  Timer? _hideTimer;

  /// Cancela el temporizador de cierre del menú si está activo
  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  /// Inicia un temporizador para cerrar el menú después de un breve retraso
  /// 
  /// Este método se utiliza para implementar un retraso antes de ocultar
  /// el menú cuando el cursor sale del área del ítem o del menú desplegable.
  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _overlayController.hide();
      }
    });
  }

  @override
  void dispose() {
    _cancelHideTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.primaryColor;
    final unselectedColor = theme.iconTheme.color;
    final selectedBgColor = selectedColor.withValues(alpha: 0.12);

    final bool hasSubItems = widget.menuItem.subItems?.isNotEmpty ?? false;
    final buttonChild = InkWell(
      onTap: widget.onSelect,
      child: Container(
        height: 56.0,
        width: widget.isExpanded ? 256 : 72,
        decoration: BoxDecoration(
          color: widget.isSelected ? selectedBgColor : Colors.transparent,
        ),
        child: Center(
          child:
              widget.isExpanded
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.isSelected
                              ? widget.menuItem.activeIcon
                              : widget.menuItem.icon,
                          color:
                              widget.isSelected
                                  ? selectedColor
                                  : unselectedColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.menuItem.label,
                            style: TextStyle(
                              color: widget.isSelected ? selectedColor : null,
                              fontWeight:
                                  widget.isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Icon(
                    widget.isSelected
                        ? widget.menuItem.activeIcon
                        : widget.menuItem.icon,
                    color: widget.isSelected ? selectedColor : unselectedColor,
                  ),
        ),
      ),
    );

    // Si no hay subitems, no necesitamos toda la lógica de hover
    if (!hasSubItems) {
      return buttonChild;
    }

    // Usamos MouseRegion para detectar cuándo el cursor entra o sale del área del botón.
    return MouseRegion(
      onEnter: (_) {
        _cancelHideTimer(); // Si volvemos a entrar al botón, cancelar el cierre
        _overlayController.show();
      },
      onExit: (_) {
        _startHideTimer(); // Al salir del botón, iniciar el conteo para cerrar
      },
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (BuildContext context) {
          return Positioned.fill(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(widget.isExpanded ? 256.0 : 72.0, 0.0),
              child: Align(
                alignment: Alignment.centerLeft, // Alineamos a la izquierda
                child: CompositedTransformFollower(
                  // Follower ahora dentro de Align
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(widget.isExpanded ? 256.0 : 72.0, 0.0),
                  child: MouseRegion(
                    onEnter: (_) => _cancelHideTimer(),
                    onExit: (_) => _startHideTimer(),
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        // Limitamos el tamaño máximo
                        constraints: BoxConstraints(
                          maxWidth: 250, // Ancho máximo del menú
                          maxHeight: 400, // Altura máxima del menú
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children:
                              widget.menuItem.subItems!.map((subItem) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minLeadingWidth: 24,
                                  title: Text(subItem.label),
                                  leading: Icon(subItem.icon),
                                  hoverColor: theme.hoverColor,
                                  onTap: () {
                                    _overlayController.hide();
                                    if (subItem.route != null) {
                                      widget.onSubItemSelect(subItem.route!);
                                    }
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: CompositedTransformTarget(link: _layerLink, child: buttonChild),
      ),
    );
  }
}
