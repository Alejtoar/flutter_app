import 'package:flutter/material.dart';
import 'package:golo_app/navigation/models/sub_menus.dart';
import 'menu_item.dart';

class MainMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Inicio',
    ),
    MenuItem(
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      label: 'Eventos',
      subItems: EventSubMenu.items,
    ),
    MenuItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Planificación',
      subItems: PlanningSubMenu.items,
    ),
    MenuItem(
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu,
      label: 'Catálogos',
      subItems: CatalogSubMenu.items,
    ),
    MenuItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Reportes',
      subItems: ReportSubMenu.items,
    ),
    MenuItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Admin',
      subItems: AdminSubMenu.items,
    ),
  ];
}