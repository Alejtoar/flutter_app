import 'package:flutter/material.dart';
import 'menu_item.dart';

class EventSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.list_alt,
      activeIcon: Icons.list_alt,
      label: 'Todos los Eventos',
    ),
    MenuItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: 'Nuevo Evento',
    ),
    MenuItem(
      icon: Icons.calendar_today,
      activeIcon: Icons.calendar_today,
      label: 'Calendario',
    ),
    MenuItem(
      icon: Icons.filter_alt,
      activeIcon: Icons.filter_alt,
      label: 'Por Estado',
    ),
    MenuItem(
      icon: Icons.search,
      activeIcon: Icons.search,
      label: 'Buscar',
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
    // ... items de reportes
  ];
}

class AdminSubMenu {
  static final items = <MenuItem>[
    // ... items de admin
  ];
}