import 'package:flutter/material.dart';
import 'package:golo_app/features/dashboards/widgets/event_list.dart';
import 'package:golo_app/features/dashboards/widgets/kpi_cart.dart';
import 'package:golo_app/features/dashboards/widgets/quick_action.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Resumen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const KPISection(),
                const SizedBox(height: 20),
                const QuickActionsSection(),
                const SizedBox(height: 20),
                const UpcomingEventsSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}