import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_state.dart';
import '../common/admin_scaffold.dart';
import 'dashboard/dashboard_screen.dart';
import 'platos/platos_screen.dart';
import 'eventos/eventos_screen.dart';
import 'reportes/reportes_screen.dart';
import 'configuracion/configuracion_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationState = context.watch<NavigationState>();
    final screens = [
      const DashboardScreen(),
      const PlatosScreen(),
      const EventosScreen(),
      const ReportesScreen(),
      const ConfiguracionScreen(),
    ];

    return AdminScaffold(
      title: _getTitleForIndex(navigationState.currentIndex),
      child: screens[navigationState.currentIndex],
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Gestión de Platos';
      case 2:
        return 'Gestión de Eventos';
      case 3:
        return 'Reportes y Análisis';
      case 4:
        return 'Configuración';
      default:
        return 'Golo App';
    }
  }
}
