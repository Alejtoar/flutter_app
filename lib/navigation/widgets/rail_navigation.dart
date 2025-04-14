import 'package:flutter/material.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/navigation/models/menu_item.dart';
import 'package:provider/provider.dart';



class RailNavigation extends StatelessWidget {
  final bool isExpanded;

  const RailNavigation({
    Key? key,
    required this.isExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NavigationController>(context);
    final currentItems = controller.currentMenuItems;

    return NavigationRail(
      selectedIndex: _calculateSelectedIndex(controller),
      onDestinationSelected: (index) => _handleSelection(index, controller),
      extended: isExpanded,
      destinations: _buildDestinations(controller, currentItems),
    );
  }

  int _calculateSelectedIndex(NavigationController controller) {
    final items = controller.currentMenuItems;
    if (controller.isSubMenuOpen) {
      // Ensure index is valid (0 is back button, 1+ are subitems)
      return (controller.currentIndex + 1).clamp(0, items.length);
    } else {
      return controller.mainMenuIndex.clamp(0, items.length - 1);
    }
  }

  void _handleSelection(int index, NavigationController controller) {
    final items = controller.currentMenuItems;
    if (index < 0 || index >= _buildDestinations(controller, items).length) {
      return; // Ignore invalid selections
    }
    
    if (controller.isSubMenuOpen) {
      index == 0 ? controller.backToMain() : controller.navigateToSub(index - 1);
    } else {
      controller.navigateToMain(index);
    }
  }

  List<NavigationRailDestination> _buildDestinations(
      NavigationController controller, List<MenuItem> items) {
    return [
      if (controller.isSubMenuOpen) _buildBackDestination(),
      ...items.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.activeIcon),
        label: Text(item.label),
      )),
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