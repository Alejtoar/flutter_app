import 'package:flutter/material.dart';
import 'package:golo_app/navigation/widgets/rail_navigationv2.dart';
import 'package:golo_app/navigation/widgets/bottom_navigation.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;

    return Scaffold(
      body: Row(
        children: [
          if (!isSmallScreen) RailNavigation(isExpanded: width > 800),
          if (!isSmallScreen) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isSmallScreen ? const BottomNavigation() : null,
    );
  }
}
