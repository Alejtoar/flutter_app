// lib/navigation/widgets/rail_navigation.dart (Reemplazado por versión personalizada)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golo_app/navigation/models/main_menu.dart';
// Importar el nuevo widget de item
import 'package:golo_app/navigation/widgets/hover_rail_item.dart';

class RailNavigation extends StatelessWidget {
  final bool isExpanded;
  const RailNavigation({Key? key, required this.isExpanded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    final mainMenu = MainMenu.items;
    final String currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final router = GoRouter.of(context);

    // Calcular índice seleccionado (igual que antes)
    int selectedIndex = 0;
    for (int i = 0; i < mainMenu.length; i++) {
      final item = mainMenu[i];
      if (item.route == currentRoute ||
          (item.subItems?.any((sub) => sub.route == currentRoute) ??
              false)) {
        selectedIndex = i;
        break;
      }
    }

    // Usar una Surface o Material para el fondo del Rail
    return Material(
      elevation: 2.0, // Simular la elevación del NavigationRail
      child: Container(
        width: isExpanded ? 256 : 72, // Anchos estándar
        color: Theme.of(context).canvasColor, // Color de fondo
        child: Column(
          children: List.generate(mainMenu.length, (index) {
            final item = mainMenu[index];
            return HoverRailItem(
              menuItem: item,
              isSelected: selectedIndex == index,
              isExpanded: isExpanded,
              onSubItemSelect: (route) {
                // Pasar la función de navegación del controlador
                router.go(route);
              },
              onSelect: () {
                // --- LÓGICA DEL CLIC PRINCIPAL ---
                // Si tiene una ruta directa (como "Inicio"), navega
                if (item.route != null) {
                  router.go(item.route!);
                }
                // Si tiene sub-items, el clic principal puede no hacer nada,
                // o navegar al primer sub-item.
                else if (item.subItems != null && item.subItems!.isNotEmpty) {
                  final firstSubItem = item.subItems!.first;
                  if (firstSubItem.route != null) {
                    router.go(firstSubItem.route!);
                  }
                }
              },
            );
          }),
        ),
      ),
    );
  }
}
