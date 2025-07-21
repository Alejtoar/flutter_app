import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golo_app/features/dashboards/widgets/quick_action_button.dart';
import 'package:golo_app/navigation/app_router.dart';


class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Text('Acciones Rápidas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  QuickActionButton(label: 'Nuevo Evento', icon: Icons.add, onTap: () {
                     context.go(AppRouter.eventosBuscador); // O a la pantalla de edición directamente
                  }),
                  QuickActionButton(label: 'Ver Insumos', icon: Icons.inventory_2_outlined, onTap: () {
                     context.go(AppRouter.insumos);
                  }),
                  QuickActionButton(label: 'Ver Platos', icon: Icons.restaurant_menu_outlined, onTap: () {
                      context.go(AppRouter.platos);
                  }),
                   QuickActionButton(label: 'Calendario', icon: Icons.calendar_month_outlined, onTap: () {
                      context.go(AppRouter.eventosCalendario); // Si creas la ruta
                   }),
                ],
              ),
            ),
          ),
       ],
    );
  }
}