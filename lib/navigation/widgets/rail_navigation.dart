//rail_navigation.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';

import 'package:golo_app/navigation/models/main_menu.dart';
import 'package:golo_app/navigation/models/menu_item.dart';

class RailNavigation extends StatefulWidget {
  final bool isExpanded;
  const RailNavigation({Key? key, required this.isExpanded}) : super(key: key);

  @override
  State<RailNavigation> createState() => _RailNavigationState();
}

class _RailNavigationState extends State<RailNavigation> {
  int? selectedMainIndex;
  int? selectedSubIndex;
  bool inSubMenu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStateWithRoute();
  }

  void _syncStateWithRoute() {
    final route = ModalRoute.of(context)?.settings.name;
    final mainMenu = MainMenu.items;
    selectedMainIndex = null;
    selectedSubIndex = null;
    inSubMenu = false;
    for (int i = 0; i < mainMenu.length; i++) {
      final item = mainMenu[i];
      if (item.route != null && item.route == route) {
        selectedMainIndex = i;
        inSubMenu = false;
        break;
      }
      if (item.subItems != null) {
        for (int j = 0; j < item.subItems!.length; j++) {
          final sub = item.subItems![j];
          if (sub.route != null && sub.route == route) {
            selectedMainIndex = i;
            selectedSubIndex = j;
            inSubMenu = true;
            break;
          }
        }
      }
      if (selectedMainIndex != null) break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;
    final mainMenu = MainMenu.items;

    List<MenuItem> currentMenuItems;
    if (inSubMenu && selectedMainIndex != null) {
      currentMenuItems = mainMenu[selectedMainIndex!].subItems ?? [];
    } else {
      currentMenuItems = mainMenu;
    }

    return NavigationRail(
      selectedIndex:
          inSubMenu ? ((selectedSubIndex ?? 0) + 1) : (selectedMainIndex ?? 0),
      extended: widget.isExpanded,
      destinations: [
        if (inSubMenu)
          NavigationRailDestination(
            icon: const Icon(Icons.arrow_back),
            selectedIcon: const Icon(Icons.arrow_back),
            label: const Text('Atrás'),
          ),
        ...currentMenuItems.map(
          (item) => NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: Text(item.label),
          ),
        ),
      ],
      onDestinationSelected:
          isSmallScreen
              ? null
              : (index) {
                if (inSubMenu) {
                  if (index == 0) {
                    // Atrás
                    setState(() {
                      inSubMenu = false;
                      selectedSubIndex = null;
                    });
                  } else {
                    setState(() {
                      selectedSubIndex = index - 1;
                    });
                    _navigateToSubMenu(
                      context,
                      mainMenu[selectedMainIndex!],
                      index - 1,
                    );
                    // Ya no volvemos automáticamente al menú principal, solo si el usuario presiona 'Atrás'.
                  }
                } else {
                  setState(() {
                    selectedMainIndex = index;
                    selectedSubIndex = null;
                  });
                  if ((mainMenu[index].subItems?.isNotEmpty ?? false)) {
                    setState(() {
                      inSubMenu = true;
                    });
                  } else {
                    _navigateToMainMenu(context, index);
                  }
                }
              },
    );
  }

  void _navigateToMainMenu(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (r) => false,
        );
        break;
      case 1:
        // Eventos (por defecto a buscador)
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.eventosBuscador,
          (r) => false,
        );
        break;
      case 2:
        // Planificación (no implementado)
        break;
      case 3:
        // Catálogos (abre submenú)
        break;
      case 4:
        // Reportes (no implementado)
        break;
      case 5:
        // Admin (no implementado)
        break;
    }
  }

  void _navigateToSubMenu(
    BuildContext context,
    MenuItem mainItem,
    int subIndex,
  ) {
    final subItem =
        mainItem.subItems![subIndex]; // Obtener el MenuItem completo
    // final subLabel = subItem.label;
    final subRoute = subItem.route;

    if (subRoute == '/logout') {
      // Manejar cierre de sesión
      _handleLogout(context);
      return;
    }

    switch (mainItem.label) {
      case 'Catálogos':
        if (subRoute != null) {
          Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
        }
        break;
      case 'Eventos':
        if (subRoute != null) {
          Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
        }
        break;
      case 'Admin': // Si 'Cerrar Sesión' está aquí
        if (subRoute != null && subRoute != '/logout') {
          // Si tiene otra ruta como /admin/config
          Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
        }
        // Si no hay otra acción para otros subitems de admin, puedes dejarlo.
        break;
      // Agrega lógica para otros menús con submenús si es necesario
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navega a la pantalla de login.
    // Asegúrate que LoginPage no esté dentro de MainScaffold.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}
