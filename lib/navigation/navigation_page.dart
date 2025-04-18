//navigation_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumos_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedios_screen.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedores_screen.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/navigation/widgets/bottom_navigation.dart';
import 'package:golo_app/navigation/widgets/rail_navigation.dart';


class NavigationPage extends StatelessWidget {
  const NavigationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;

    return Scaffold(
      body: Consumer<NavigationController>(
        builder: (context, controller, _) {
          return Row(
            children: [
              if (!isSmallScreen) RailNavigation(isExpanded: width > 800),
              if (!isSmallScreen) const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildCurrentScreen(controller, context)),
            ],
          );
        },
      ),
      bottomNavigationBar:
          isSmallScreen ? _buildMobileNavigation(context) : null,
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    return const BottomNavigation();
  }

  Widget _buildCurrentScreen(
    NavigationController controller,
    BuildContext context,
  ) {
    // Prioridad: Submenú > Menú principal
    if (controller.isSubMenuOpen) {
      return _buildSubScreen(controller, context);
    }
    return _buildMainScreen(controller);
  }

  Widget _buildMainScreen(NavigationController controller) {
    switch (controller.mainMenuIndex) {
      case 0: // Inicio
        return const DashboardScreen();
      case 1: // Eventos
        return _buildPantallaGenerica('Eventos');
      case 2: // Planificación
        return _buildPantallaGenerica('Planificación');
      case 3: // Catálogos
        return _buildCatalogosMain(controller);
      case 4: // Reportes
        return _buildPantallaGenerica('Reportes');
      case 5: // Admin
        return _buildPantallaGenerica('Admin');
      default:
        return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  Widget _buildPantallaGenerica(String titulo) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 50),
            const SizedBox(height: 20),
            Text('Pantalla de $titulo en desarrollo'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubScreen(
    NavigationController controller,
    BuildContext context,
  ) {
    final currentSubItems = controller.currentSubMenuItems;
    final currentItem = currentSubItems[controller.subMenuIndex];
    return Scaffold(
      body:
          currentItem.label == 'Insumos'
              ? Consumer<InsumoController>(
                  builder: (context, controller, _) {
                    return const InsumosScreen();
                  },
                )
              : currentItem.label == 'Intermedios'
                  ? const IntermediosScreen()
              : currentItem.label == 'Proveedores'
                  ? Consumer<ProveedorController>(
                      builder: (context, controller, _) {
                        return const ProveedoresScreen();
                      },
                    )
                  : _buildPantallaGenerica(currentItem.label),
    );
  }

  Widget _buildCatalogosMain(NavigationController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Seleccione una categoría del submenú'),
            ElevatedButton(
              onPressed: controller.backToMain,
              child: const Text('Volver al menú principal'),
            ),
          ],
        ),
      ),
    );
  }
}
