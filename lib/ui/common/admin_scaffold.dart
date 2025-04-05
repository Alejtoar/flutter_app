import 'package:flutter/material.dart';
import '../navigation/navigation_rail.dart';
import '../navigation/bottom_nav_bar.dart';

class AdminScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showDetailPanel;
  final Widget? detailPanel;

  const AdminScaffold({
    Key? key,
    required this.child,
    required this.title,
    this.actions,
    this.showDetailPanel = false,
    this.detailPanel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 1200;
    final isMediumScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: Row(
        children: [
          if (isLargeScreen) const AppNavigationRail(),
          Expanded(
            child: child,
          ),
          if (showDetailPanel && detailPanel != null)
            SizedBox(
              width: isMediumScreen ? 400 : MediaQuery.of(context).size.width * 0.85,
              child: detailPanel!,
            ),
        ],
      ),
      bottomNavigationBar: isLargeScreen ? null : const AppBottomNavBar(),
    );
  }
}
