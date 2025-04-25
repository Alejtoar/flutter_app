import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:golo_app/navigation/models/main_menu.dart';


class BottomNavigation extends StatelessWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainMenu = MainMenu.items;
    final route = ModalRoute.of(context)?.settings.name;
    int selectedIndex = _calculateSelectedIndex(route);

    return BottomNavigationBar(
      items: mainMenu
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(),
      currentIndex: selectedIndex,
      onTap: (index) => _handleMainItemTap(context, index),
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.disabledColor,
      type: BottomNavigationBarType.fixed,
    );
  }

  int _calculateSelectedIndex(String? route) {
    switch (route) {
      case AppRoutes.dashboard:
        return 0;
      case AppRoutes.eventosBuscador:
        return 1;
      case AppRoutes.platos:
      case AppRoutes.intermedios:
      case AppRoutes.insumos:
      case AppRoutes.proveedores:
        return 3; // Catálogos
      default:
        return 0;
    }
  }

  void _handleMainItemTap(BuildContext context, int index) {
    final mainMenu = MainMenu.items;
    final item = mainMenu[index];
    if (item.subItems != null && item.subItems!.isNotEmpty) {
      // Mostrar selector de submenú
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final subItem in item.subItems!)
                  ListTile(
                    leading: Icon(subItem.icon),
                    title: Text(subItem.label),
                    onTap: () {
                      Navigator.pop(ctx); // Cierra el bottom sheet
                      _navigateToSubMenu(context, item.label, subItem.label);
                    },
                  ),
              ],
            ),
          );
        },
      );
    } else {
      // Ítem sin submenú
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (r) => false);
          break;
        case 1:
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.eventosBuscador, (r) => false);
          break;
        // Puedes agregar más casos si implementas más menús principales sin submenú
      }
    }
  }

  void _navigateToSubMenu(BuildContext context, String mainLabel, String subLabel) {
    if (mainLabel == 'Catálogos') {
      switch (subLabel) {
        case 'Platos':
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.platos, (r) => false);
          break;
        case 'Intermedios':
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.intermedios, (r) => false);
          break;
        case 'Insumos':
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.insumos, (r) => false);
          break;
        case 'Proveedores':
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.proveedores, (r) => false);
          break;
      }
    }
    if (mainLabel == 'Eventos') {
      switch (subLabel) {
        case 'Buscar eventos':
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.eventosBuscador, (r) => false);
          break;
        // case 'Calendario':
        //   // Agrega aquí la ruta cuando esté lista
        //   break;
      }
    }
    // Puedes agregar más lógica para otros menús principales con submenú
  }
}