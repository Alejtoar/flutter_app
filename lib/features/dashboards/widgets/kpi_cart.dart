import 'package:flutter/material.dart';

class KPISection extends StatelessWidget {
  const KPISection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Indicadores Clave', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                KPICard(title: 'Eventos Hoy', value: '3', icon: Icons.event),
                KPICard(title: 'Por Confirmar', value: '5', icon: Icons.pending_actions),
                KPICard(title: 'Pruebas Pendientes', value: '2', icon: Icons.restaurant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  
  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 24)),
      ],
    );
  }
}