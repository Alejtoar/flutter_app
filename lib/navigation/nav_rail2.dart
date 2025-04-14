import 'package:flutter/material.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';

class NavigationRailPage extends StatefulWidget {
  const NavigationRailPage({Key? key}) : super(key: key);

  @override
  State<NavigationRailPage> createState() => _NavigationRailPageState();
}

const _navBarItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.dashboard_outlined),
    activeIcon: Icon(Icons.dashboard),
    label: 'Inicio',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.event_outlined),
    activeIcon: Icon(Icons.event),
    label: 'Eventos',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.assignment_outlined),
    activeIcon: Icon(Icons.assignment),
    label: 'Planificación',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.restaurant_menu_outlined),
    activeIcon: Icon(Icons.restaurant_menu),
    label: 'Catálogos',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.analytics_outlined),
    activeIcon: Icon(Icons.analytics),
    label: 'Reportes',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_outlined),
    activeIcon: Icon(Icons.settings),
    label: 'Admin',
  ),
];

class _NavigationRailPageState extends State<NavigationRailPage> {
  int _selectedIndex = 0;
  int _expandedSection = -1;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;
    final bool isLargeScreen = width > 800;

    return Scaffold(
      bottomNavigationBar:
          isSmallScreen
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expandedSection != -1)
                    Container(
                      height: 50,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              setState(() {
                                _expandedSection = -1;
                              });
                            },
                          ),
                          ..._getSubDestinations(_expandedSection).map((item) {
                            final index =
                                _getSubDestinations(
                                  _expandedSection,
                                ).indexOf(item) +
                                1;
                            return TextButton(
                              onPressed: () => _handleSubItemSelection(index),
                              child: Text((item.label as Text).data!),
                            );
                          }),
                        ],
                      ),
                    ),
                  BottomNavigationBar(
                    items: _navBarItems,
                    currentIndex: _selectedIndex,
                    selectedItemColor: Theme.of(context).colorScheme.primary,
                    unselectedItemColor:
                        Theme.of(context).colorScheme.onSurface,
                    onTap: (int index) {
                      setState(() {
                        if (_expandedSection == -1 &&
                            [1, 2, 3, 4, 5].contains(index)) {
                          _expandedSection = index;
                        } else {
                          _selectedIndex = index;
                          _expandedSection = -1;
                        }
                      });
                    },
                  ),
                ],
              )
              : null,
      body: Row(
        children: <Widget>[
          if (!isSmallScreen)
            NavigationRail(
              selectedIndex:
                  _selectedIndex <
                          (_expandedSection == -1
                              ? _navBarItems.length
                              : _getSubDestinations(_expandedSection).length +
                                  1)
                      ? _selectedIndex
                      : 0,
              onDestinationSelected: (int index) {
                setState(() {
                  if (_expandedSection != -1) {
                    if (index >= 0 &&
                        index <
                            _getSubDestinations(_expandedSection).length + 1) {
                      _handleSubItemSelection(index);
                    }
                  } else {
                    if (index >= 0 && index < _navBarItems.length) {
                      _selectedIndex = index;
                      if ([1, 2, 3, 4, 5].contains(index)) {
                        _expandedSection = index;
                      }
                    }
                  }
                });
              },
              extended: isLargeScreen,
              destinations:
                  _expandedSection == -1
                      ? _navBarItems
                          .map(
                            (item) => NavigationRailDestination(
                              icon: item.icon,
                              selectedIcon: item.activeIcon,
                              label: Text(item.label!),
                            ),
                          )
                          .toList()
                      : [
                        NavigationRailDestination(
                          icon: const Icon(Icons.arrow_back),
                          selectedIcon: const Icon(Icons.arrow_back),
                          label: const Text('Atrás'),
                          padding: const EdgeInsets.only(top: 16),
                        ),
                        ..._getSubDestinations(_expandedSection),
                      ],
            ),
          if (!isSmallScreen) const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
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
            selectedIcon: Icon(Icons.list_alt),
            label: Text('Todos los Eventos'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: Text('Nuevo Evento'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.calendar_today),
            selectedIcon: Icon(Icons.calendar_today),
            label: Text('Calendario'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.filter_alt),
            selectedIcon: Icon(Icons.filter_alt),
            label: Text('Por Estado'),
          ),
        ];
      case 2: // Planificación
        return [
          const NavigationRailDestination(
            icon: Icon(Icons.menu_book),
            selectedIcon: Icon(Icons.menu_book),
            label: Text('Diseñar Menú'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.calculate),
            selectedIcon: Icon(Icons.calculate),
            label: Text('Calculadora'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: Text('Insumos Requeridos'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.directions_car),
            selectedIcon: Icon(Icons.directions_car),
            label: Text('Logística'),
          ),
        ];
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
      // Actualizar el índice seleccionado para reflejar la selección
      setState(() {
        _selectedIndex = _expandedSection;
      });
      // Aquí puedes navegar a pantallas específicas
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
        return const Scaffold(body: Center(child: Text('Pantalla de Eventos')));
      case 2:
        return const Scaffold(
          body: Center(child: Text('Pantalla de Planificación')),
        );
      case 3:
        return const Scaffold(
          body: Center(child: Text('Pantalla de Catálogos')),
        );
      case 4:
        return const Scaffold(
          body: Center(child: Text('Pantalla de Reportes')),
        );
      case 5:
        return const Scaffold(
          body: Center(child: Text('Pantalla de Administración')),
        );
      default:
        return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  Widget _buildSubScreen(int section) {
    // Implementa pantallas específicas para subsecciones
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Contenido de la sección ${_navBarItems[section].label}'),
          const SizedBox(height: 20),
          Text('Subsección seleccionada'),
        ],
      ),
    );
  }
}
