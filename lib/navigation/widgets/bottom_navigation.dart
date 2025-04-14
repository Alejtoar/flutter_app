import 'package:flutter/material.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:provider/provider.dart';

class BottomNavigation extends StatelessWidget {
  final void Function(int index)? onItemSelected;

  const BottomNavigation({Key? key, this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NavigationController>(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.isSubMenuOpen) _buildSubMenuBar(context, controller),
        _buildMainNavigationBar(controller, theme),
      ],
    );
  }

  Widget _buildSubMenuBar(
    BuildContext context,
    NavigationController controller,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver al menú principal',
            onPressed: controller.backToMain,
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          ...controller.currentMenuItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                onPressed:
                    () => controller.navigateToSub(
                      controller.currentMenuItems.indexOf(item),
                    ),
                child: Text(item.label),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigationBar(
    NavigationController controller,
    ThemeData theme,
  ) {
    return BottomNavigationBar(
      items:
          controller.mainMenuItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
      currentIndex: controller.mainMenuIndex,
      onTap: (index) => _handleMainItemTap(index, controller),
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.disabledColor,
    );
  }

  void _handleMainItemTap(int index, NavigationController controller) {
    if (onItemSelected != null) {
      onItemSelected!(index);
    } else {
      final item = controller.mainMenuItems[index];
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        controller.navigateToMain(index);
      } else {
        controller.navigateToMain(index);
        // Aquí podrías navegar directamente a una pantalla si no tiene subitems
      }
    }
  }
}
