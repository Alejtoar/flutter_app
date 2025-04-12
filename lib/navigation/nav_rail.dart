import 'package:flutter/material.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';


// Importa otras pantallas según sea necesario

class AppNavigation extends StatefulWidget {
  const AppNavigation({Key? key}) : super(key: key);

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;
  int _expandedSection = -1;

  final List<NavigationRailDestination> _mainDestinations = [
    const NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Inicio'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: Text('Eventos'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: Text('Planificación'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: Text('Catálogos'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: Text('Reportes'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Admin'),
    ),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Inicio',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.event_outlined),
      activeIcon: Icon(Icons.event),
      label: 'Eventos',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_menu_outlined),
      activeIcon: Icon(Icons.restaurant_menu),
      label: 'Catálogos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;
    final bool isLargeScreen = width > 800;

    return Scaffold(
      bottomNavigationBar:
          isSmallScreen
              ? BottomNavigationBar(
                items: _bottomNavItems,
                currentIndex: _selectedIndex.clamp(
                  0,
                  _bottomNavItems.length - 1,
                ),
                onTap: (int index) {
                  setState(() {
                    _selectedIndex = index;
                    _expandedSection = -1;
                  });
                },
              )
              : null,
      body: Row(
        children: <Widget>[
          if (!isSmallScreen)
            SingleChildScrollView(
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                extended: isLargeScreen,
                minExtendedWidth: 200,
                onDestinationSelected: (int index) {
                  setState(() {
                    if (_expandedSection != -1) {
                      _handleSubItemSelection(index);
                    } else {
                      _selectedIndex = index;
                      // Solo expandir secciones que tienen subitems
                      if ([1, 2, 3, 4, 5].contains(index)) {
                        _expandedSection = index;
                      }
                    }
                  });
                },
                destinations:
                    _expandedSection == -1
                        ? _mainDestinations
                        : [
                          NavigationRailDestination(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Atrás'),
                            padding: const EdgeInsets.only(top: 16),
                          ),
                          ..._getSubDestinations(_expandedSection),
                        ],
              ),
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildCurrentScreen()),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _getSubDestinations(int section) {
    switch (section) {
      case 1: // Eventos
        return [
          const NavigationRailDestination(
            icon: Icon(Icons.list_alt),
            label: Text('Todos los Eventos'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.add_circle_outline),
            label: Text('Nuevo Evento'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.calendar_today),
            label: Text('Calendario'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.filter_alt),
            label: Text('Por Estado'),
          ),
        ];
      case 2: // Planificación
        return [
          const NavigationRailDestination(
            icon: Icon(Icons.menu_book),
            label: Text('Diseñar Menú'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.calculate),
            label: Text('Calculadora'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.format_list_bulleted),
            label: Text('Insumos Requeridos'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.directions_car),
            label: Text('Logística'),
          ),
        ];
      // Añadir otros casos para las demás secciones
      default:
        return [];
    }
  }

  void _handleSubItemSelection(int index) {
    if (index == 0) {
      // Botón "Atrás"
      setState(() {
        _expandedSection = -1;
      });
    } else {
      // Aquí manejas la navegación real
      final subItemIndex = index - 1;
      print('Navegar a: $_expandedSection - $subItemIndex');
      // Ejemplo: Navegar a pantalla específica
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ...));
    }
  }

  Widget _buildCurrentScreen() {
    if (_expandedSection != -1) {
      return _buildSubScreen(_expandedSection);
    }

    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        //return const EventosScreen() ;
        return const Scaffold(
          body: Center(child: Text('Pantalla de Eventos en desarrollo')),
        );
      case 2:
        return const Placeholder(); // Reemplazar con PlanningScreen()
      case 3:
        return const Placeholder(); // Reemplazar con CatalogScreen()
      case 4:
        return const Placeholder(); // Reemplazar con ReportsScreen()
      case 5:
        return const Placeholder(); // Reemplazar con AdminScreen()
      default:
        return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  Widget _buildSubScreen(int section) {
    // Aquí puedes implementar pantallas específicas para subsecciones
    return Center(child: Text('Contenido de la sección $section'));
  }
}
