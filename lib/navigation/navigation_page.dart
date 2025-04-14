import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumos_screen.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/navigation/models/main_menu.dart';
import 'package:golo_app/navigation/widgets/bottom_navigation.dart';
import 'package:golo_app/navigation/widgets/rail_navigation.dart';
import 'package:golo_app/repositories/insumo_repository_impl.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;
    final controller = Provider.of<NavigationController>(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            children: [
              if (!isSmallScreen) RailNavigation(isExpanded: width > 800),
              if (!isSmallScreen) const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _buildCurrentScreen(controller)),
            ],
          );
        },
      ),
      bottomNavigationBar:
          isSmallScreen ? _buildMobileNavigation(context) : null,
    );
  }

  Widget _buildMobileNavigation(BuildContext context) {
    final controller = Provider.of<NavigationController>(context);

    return BottomNavigation(
      onItemSelected: (index) {
        if (MainMenu.items[index].subItems != null) {
          controller.navigateToMain(index);
        } else {
          controller.navigateToMain(index);
        }
      },
    );
  }

  Widget _buildCurrentScreen(NavigationController controller) {
    if (controller.isSubMenuOpen) {
      return _buildSubScreen(controller);
    }

    switch (controller.mainMenuIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return ChangeNotifierProvider(
        create: (_) => InsumoController(InsumoFirestoreRepository(FirebaseFirestore.instance)),
        child: const InsumosScreen(),
      );
      // ... otros casos
      default:
        return const Center(child: Text('Pantalla no encontrada'));
    }
  }

  Widget _buildSubScreen(NavigationController controller) {
    if (controller.currentMenuItems.isEmpty) {
      return const Center(child: Text('No hay elementos disponibles'));
    }

    final currentIndex = controller.currentIndex.clamp(
      0,
      controller.currentMenuItems.length - 1,
    );
    final currentItem = controller.currentMenuItems[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.label),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(currentItem.icon, size: 50),
            const SizedBox(height: 20),
            Text('Detalles de ${currentItem.label}'),
          ],
        ),
      ),
    );
  }
}
