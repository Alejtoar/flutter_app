import 'package:flutter/material.dart';
import 'menu_item.dart';

class EventSubMenu {
  static final items = <MenuItem>[
    MenuItem(
      icon: Icons.list_alt,
      activeIcon: Icons.list_alt,
      label: 'Buscar eventos',
      route:
          '/eventos/buscar', // Usa AppRoutes.eventosBuscador si está definido
    ),
    MenuItem(
      icon: Icons.calendar_today,
      activeIcon: Icons.calendar_today,
      label: 'Calendario',
      route: '/eventos/calendario',
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
      route: '/catalogos/platos', // Usa AppRoutes.platos si está definido
    ),
    MenuItem(
      icon: Icons.calculate,
      activeIcon: Icons.calculate,
      label: 'Intermedios',
      route: '/catalogos/intermedios',
    ),
    MenuItem(
      icon: Icons.format_list_bulleted,
      activeIcon: Icons.format_list_bulleted,
      label: 'Insumos',
      route: '/catalogos/insumos',
    ),
    MenuItem(
      icon: Icons.directions_car,
      activeIcon: Icons.directions_car,
      label: 'Proveedores',
      route: '/catalogos/proveedores',
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
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Configuración',
      // route: '/admin/configuracion' // Define la ruta si tienes esta pantalla
    ),
    MenuItem(
      // Nuevo ítem para cerrar sesión
      icon: Icons.logout,
      activeIcon: Icons.logout,
      label: 'Cerrar Sesión',
      route: '/logout', // Ruta especial o sin ruta si se maneja por acción
    ),
  ];
}
