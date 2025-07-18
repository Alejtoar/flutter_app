import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/navigation/models/main_menu.dart';
import 'package:golo_app/navigation/models/menu_item.dart';
import 'package:provider/provider.dart';

class RailNavigation extends StatelessWidget { // <-- AHORA ES STATELESS
  final bool isExpanded;
  const RailNavigation({Key? key, required this.isExpanded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navCtrl = context.watch<NavigationController>();
    final mainMenu = MainMenu.items;

    // --- Lógica de Decisión (Declarativa, sin estado local) ---

    // 1. Determinar el menú principal activo basándose en la ruta actual
    MenuItem? activeMainItem;
    for (final item in mainMenu) {
        if (item.route == navCtrl.currentRoute ||
            (item.subItems?.any((sub) => sub.route == navCtrl.currentRoute) ?? false)) {
            activeMainItem = item;
            break;
        }
    }

    // 2. Decidir si estamos en un submenú
    // Para estar "en un submenú", el item principal activo debe tener subitems
    // Y no tener una ruta principal propia que coincida con la ruta actual.
    // (Ej: "Catálogos" no tiene ruta, así que si está activo, estamos en su submenú)
    final bool inSubMenu = activeMainItem != null &&
                           (activeMainItem.subItems?.isNotEmpty ?? false) &&
                           activeMainItem.route != navCtrl.currentRoute;


    // 3. Determinar qué lista de items mostrar
    final List<MenuItem> currentMenuItems = inSubMenu
        ? activeMainItem.subItems!
        : mainMenu;

    // 4. Calcular el índice seleccionado
    int selectedIndex = 0;
    if (inSubMenu) {
       // El índice 0 es el botón "Atrás", sumamos 1
       final subIndex = currentMenuItems.indexWhere((item) => item.route == navCtrl.currentRoute);
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
            if (index == 0) { // Botón "Atrás"
              // Navegar a la ruta del menú principal padre.
              // Si no tiene ruta (como "Catálogos"), no hace nada,
              // lo que obliga al usuario a elegir otro menú principal.
              // O mejor, navegamos al Dashboard como fallback.
              navCtrl.navigateTo(activeMainItem?.route ?? AppRoutes.dashboard);
            } else {
              // Navegar al sub-item seleccionado
              final subItem = currentMenuItems[index - 1];
              if (subItem.route != null) navCtrl.navigateTo(subItem.route!);
            }
          } else { // Estamos en el menú principal
             final mainItem = currentMenuItems[index];
             // Si el item tiene sub-items, la acción correcta NO es navegar,
             // sino navegar a su PRIMER sub-item.
             if (mainItem.subItems != null && mainItem.subItems!.isNotEmpty) {
                // Navegar al primer sub-item
                if (mainItem.subItems!.first.route != null) {
                    navCtrl.navigateTo(mainItem.subItems!.first.route!);
                }
             } else if (mainItem.route != null) {
                // Navegar a la ruta principal si no hay sub-items
                navCtrl.navigateTo(mainItem.route!);
             }
          }
      },
    );
  }
}