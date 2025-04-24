import 'package:flutter/material.dart';
import 'menu_item.dart';

class EventSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.list_alt,
      activeIcon: Icons.list_alt,
      label: 'Eventos',
    ),
    MenuItem(
      icon: Icons.calendar_today,
      activeIcon: Icons.calendar_today,
      label: 'Calendario',
    ),
  ];
}

class PlanningSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.menu_book,
      activeIcon: Icons.menu_book,
      label: 'Diseñar Menú',
    ),
    MenuItem(
      icon: Icons.calculate,
      activeIcon: Icons.calculate,
      label: 'Calculadora',
    ),
    MenuItem(
      icon: Icons.format_list_bulleted,
      activeIcon: Icons.format_list_bulleted,
      label: 'Insumos Requeridos',
    ),
    MenuItem(
      icon: Icons.directions_car,
      activeIcon: Icons.directions_car,
      label: 'Logística',
    ),
  ];
}

class CatalogSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.food_bank_outlined,
      activeIcon: Icons.food_bank,
      label: 'Platos',
    ),
    MenuItem(
      icon: Icons.calculate,
      activeIcon: Icons.calculate,
      label: 'Intermedios',
    ),
    MenuItem(
      icon: Icons.format_list_bulleted,
      activeIcon: Icons.format_list_bulleted,
      label: 'Insumos',
    ),
    MenuItem(
      icon: Icons.directions_car,
      activeIcon: Icons.directions_car,
      label: 'Proveedores',
    ),
  ];
}

class ReportSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.bar_chart,
      activeIcon: Icons.bar_chart,
      label: 'Reportes Generales',
    ),
  ];
}

class AdminSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.settings,
      activeIcon: Icons.settings,
      label: 'Configuración',
    ),
  ];
}
