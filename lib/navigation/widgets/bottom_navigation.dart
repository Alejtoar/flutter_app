import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:golo_app/navigation/models/main_menu.dart';


class BottomNavigation extends StatelessWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainMenu = MainMenu.items;

    // Escuchar cambios en NavigationController para reconstruir la barra
    final router = GoRouter.of(context);
    final currentRoute = router.routerDelegate.currentConfiguration.fullPath;
    final selectedIndex = _calculateSelectedIndex(currentRoute);

    return BottomNavigationBar(
      items:
          mainMenu
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
      currentIndex: selectedIndex,
      onTap:
          (index) => _handleMainItemTap(
            context,
            index,
          ), // Pasar el controller
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.disabledColor,
      type: BottomNavigationBarType.fixed,
    );
  }

  // Ahora esta función es puramente de cálculo, sin estado.
  int _calculateSelectedIndex(String route) {
    // Buscar la ruta en los sub-items para determinar el índice principal
    for (int i = 0; i < MainMenu.items.length; i++) {
      final item = MainMenu.items[i];
      if (item.route == route) return i;
      if (item.subItems != null) {
        if (item.subItems!.any((sub) => sub.route == route)) {
          return i;
        }
      }
    }
    return 0; // Por defecto a Inicio
  }

  void _handleMainItemTap(BuildContext context, int index) {
      final item = MainMenu.items[index];

      // Si el item tiene una ruta directa, navegar.
      if (item.route != null) {
        context.go(item.route!);
        return;
      }

      // Si tiene sub-items, mostrar el BottomSheet
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final subItem in item.subItems!)
                  ListTile(
                    leading: Icon(subItem.icon),
                    title: Text(subItem.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (subItem.route != null) {
                         context.go(subItem.route!);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      }
  }
}
