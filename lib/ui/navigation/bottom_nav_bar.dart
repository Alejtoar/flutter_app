import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_state.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationState = context.watch<NavigationState>();
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: navigationState.currentIndex,
      onDestinationSelected: navigationState.setCurrentIndex,
      backgroundColor: colorScheme.surface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu),
          label: 'Platos',
        ),
        NavigationDestination(
          icon: Icon(Icons.event),
          label: 'Eventos',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics),
          label: 'Reportes',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}
