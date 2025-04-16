//rail_navigation.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';

class RailNavigation extends StatelessWidget {
  final bool isExpanded;

  const RailNavigation({Key? key, required this.isExpanded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NavigationController>(context);

    return NavigationRail(
      selectedIndex: _calculateSelectedIndex(controller),
      onDestinationSelected: (index) => _handleSelection(index, controller),
      extended: isExpanded,
      destinations: _buildDestinations(controller),
    );
  }

  void _handleSelection(int index, NavigationController controller) {
    if (controller.isSubMenuOpen) {
      if (index == 0) {
        // El primer ítem es el botón "Atrás"
        controller.backToMain();
      } else {
        controller.navigateToSub(index - 1); // Ajustar índice para subitems
      }
    } else {
      controller.navigateToMain(index);
    }
  }

  int _calculateSelectedIndex(NavigationController controller) {
  if (controller.isSubMenuOpen) {
    // Ajusta el índice sumando 1 (para saltar el botón "Atrás") 
    // y aplica clamp al rango correcto
    final adjustedIndex = controller.subMenuIndex + 1;
    return adjustedIndex.clamp(0, controller.currentSubMenuItems.length);
  }
  return controller.mainMenuIndex.clamp(0, controller.mainMenuItems.length - 1);
}

  List<NavigationRailDestination> _buildDestinations(
    NavigationController controller,
  ) {
    final items =
        controller.isSubMenuOpen
            ? controller.currentSubMenuItems
            : controller.mainMenuItems;

    return [
      if (controller.isSubMenuOpen) _buildBackDestination(),
      ...items.map(
        (item) => NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: Text(item.label),
        ),
      ),
    ];
  }

  NavigationRailDestination _buildBackDestination() {
    return const NavigationRailDestination(
      icon: Icon(Icons.arrow_back),
      selectedIcon: Icon(Icons.arrow_back),
      label: Text('Atrás'),
      padding: EdgeInsets.only(top: 16),
    );
  }
}
