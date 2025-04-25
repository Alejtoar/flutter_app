import 'package:flutter/material.dart';

class MenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? route;
  final List<MenuItem>? subItems;

  const MenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.route,
    this.subItems,
  });
}