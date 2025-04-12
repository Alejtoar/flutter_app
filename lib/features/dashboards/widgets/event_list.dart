import 'package:flutter/material.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Próximos Eventos', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Reemplazar con datos reales
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.event),
                title: Text('Evento ${index + 1}'),
                subtitle: const Text('Cliente X - 15/06/2023'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navegar a detalle del evento
                },
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a lista completa de eventos
              },
              child: const Text('Ver todos los eventos'),
            ),
          ],
        ),
      ),
    );
  }
}