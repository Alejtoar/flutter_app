import 'package:flutter/material.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color; // Añadir color para personalización

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.grey, // Color por defecto
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 36, color: color),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }
}