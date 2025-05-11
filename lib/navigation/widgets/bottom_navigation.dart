import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:golo_app/navigation/models/main_menu.dart';
import 'package:golo_app/navigation/models/menu_item.dart';


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

//   void _handleMainItemTap(BuildContext context, int index) {
//     final mainMenu = MainMenu.items;
//     final item = mainMenu[index];
//     if (item.subItems != null && item.subItems!.isNotEmpty) {
//       // Mostrar selector de submenú
//       showModalBottomSheet(
//         context: context,
//         builder: (ctx) {
//           return SafeArea(
//             child: ListView(
//               shrinkWrap: true,
//               children: [
//                 for (final subItem in item.subItems!)
//                   ListTile(
//                     leading: Icon(subItem.icon),
//                     title: Text(subItem.label),
//                     onTap: () {
//                       Navigator.pop(ctx); // Cierra el bottom sheet
//                       _navigateToSubMenu(context, item.label, subItem.label);
//                     },
//                   ),
//               ],
//             ),
//           );
//         },
//       );
//     } else {
//       // Ítem sin submenú
//       switch (index) {
//         case 0:
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (r) => false);
//           break;
//         case 1:
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.eventosBuscador, (r) => false);
//           break;
//         // Puedes agregar más casos si implementas más menús principales sin submenú
//       }
//     }
//   }

//   void _navigateToSubMenu(BuildContext context, String mainLabel, String subLabel) {
//     if (mainLabel == 'Catálogos') {
//       switch (subLabel) {
//         case 'Platos':
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.platos, (r) => false);
//           break;
//         case 'Intermedios':
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.intermedios, (r) => false);
//           break;
//         case 'Insumos':
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.insumos, (r) => false);
//           break;
//         case 'Proveedores':
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.proveedores, (r) => false);
//           break;
//       }
//     }
//     if (mainLabel == 'Eventos') {
//       switch (subLabel) {
//         case 'Buscar eventos':
//           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.eventosBuscador, (r) => false);
//           break;
//         // case 'Calendario':
//         //   // Agrega aquí la ruta cuando esté lista
//         //   break;
//       }
//     }
//     // Puedes agregar más lógica para otros menús principales con submenú
//   }

void _navigateToSubMenu(BuildContext context, String mainLabel, MenuItem subItem) { // Pasar MenuItem completo
    //final subLabel = subItem.label;
    final subRoute = subItem.route;

    if (subRoute == '/logout') {
      _handleLogout(context);
      return;
    }

    // Tu lógica existente, preferiblemente usando subRoute
    if (mainLabel == 'Catálogos') {
        if(subRoute != null) Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
    }
    if (mainLabel == 'Eventos') {
        if(subRoute != null) Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
    }
    if (mainLabel == 'Admin') {
         if (subRoute != null && subRoute != '/logout') {
            Navigator.pushNamedAndRemoveUntil(context, subRoute, (r) => false);
         }
    }
    // ...
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  // Actualiza el onTap del ListTile en showModalBottomSheet
  void _handleMainItemTap(BuildContext context, int index) {
      final mainMenu = MainMenu.items;
      final item = mainMenu[index];
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final subItemEntry in item.subItems!.asMap().entries) // Para tener el MenuItem
                    ListTile(
                      leading: Icon(subItemEntry.value.icon),
                      title: Text(subItemEntry.value.label),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateToSubMenu(context, item.label, subItemEntry.value); // Pasar MenuItem
                      },
                    ),
                ],
              ),
            );
          },
        );
      } else {
        // ... tu lógica existente
      }
    }
}