import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:golo_app/navigation/models/main_menu.dart';
import 'package:golo_app/navigation/models/menu_item.dart';

class RailNavigation extends StatelessWidget { // <-- AHORA ES STATELESS
  final bool isExpanded;
  const RailNavigation({Key? key, required this.isExpanded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainMenu = MainMenu.items;
    final String currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;


    // 1. Determinar el menú principal activo basándose en la ruta actual
    MenuItem? activeMainItem;
    for (final item in mainMenu) {
        if (item.route == currentRoute ||
            (item.subItems?.any((sub) => sub.route == currentRoute) ?? false)) {
            activeMainItem = item;
            break;
        }
    }

    // 2. Decidir si estamos en un submenú
    final bool inSubMenu = activeMainItem != null &&
                           (activeMainItem.subItems?.isNotEmpty ?? false) &&
                           activeMainItem.route != currentRoute;


    // 3. Determinar qué lista de items mostrar
    final List<MenuItem> currentMenuItems = inSubMenu
        ? activeMainItem.subItems!
        : mainMenu;

    // 4. Calcular el índice seleccionado
    int selectedIndex = 0;
    if (inSubMenu) {
       // El índice 0 es el botón "Atrás", sumamos 1
       final subIndex = currentMenuItems.indexWhere((item) => item.route == currentRoute);
       selectedIndex = subIndex != -1 ? subIndex + 1 : 0;
    } else {
       // El índice es la posición del item principal activo
       final mainIndex = mainMenu.indexOf(activeMainItem ?? mainMenu.first);
       selectedIndex = mainIndex != -1 ? mainIndex : 0;
    }

    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: isExpanded,
      destinations: [
        if (inSubMenu)
          const NavigationRailDestination(
            icon: Icon(Icons.arrow_back),
            selectedIcon: Icon(Icons.arrow_back),
            label: Text('Atrás'),
          ),
        ...currentMenuItems.map(
          (item) => NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: Text(item.label),
          ),
        ),
      ],
      onDestinationSelected: (index) {
          if (inSubMenu) {
            if (index == 0) { 
              GoRouter.of(context).go(activeMainItem?.route ?? AppRoutes.dashboard);
            } else {
              final subItem = currentMenuItems[index - 1];
              if (subItem.route != null) GoRouter.of(context).go(subItem.route!);
            }
          } else { // Estamos en el menú principal
             final mainItem = currentMenuItems[index];
             if (mainItem.subItems != null && mainItem.subItems!.isNotEmpty) {
                // Navegar al primer sub-item
                if (mainItem.subItems!.first.route != null) {
                    GoRouter.of(context).go(mainItem.subItems!.first.route!);
                }
             } else if (mainItem.route != null) {
                // Navegar a la ruta principal si no hay sub-items
                GoRouter.of(context).go(mainItem.route!);
             }
          }
      },
    );
  }
}