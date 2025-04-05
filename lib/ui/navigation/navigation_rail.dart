import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_state.dart';

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationState = context.watch<NavigationState>();
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: navigationState.currentIndex,
      onDestinationSelected: navigationState.setCurrentIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.restaurant_menu),
          label: Text('Platos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event),
          label: Text('Eventos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text('Reportes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Configuración'),
        ),
      ],
    );
  }
}
