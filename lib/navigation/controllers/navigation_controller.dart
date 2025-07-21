import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';

class NavigationController extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _currentRoute = AppRoutes.dashboard; // Iniciar en el dashboard

  String get currentRoute => _currentRoute;

  void navigateTo(String route) {
    if (route == '/logout') {
      _handleLogout();
      return;
    }

    if (_currentRoute == route) return; // No navegar si ya estamos ahí

    _currentRoute = route;
    // Usar el navigatorKey para navegar sin necesitar BuildContext
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
    
    // Notificar para que los widgets de navegación puedan actualizar su estado seleccionado
    notifyListeners();
  }


  void syncRouteOnStartup(BuildContext context) {
     // Se usa en didChangeDependencies para que el estado inicial sea correcto
     final route = ModalRoute.of(context)?.settings.name;
     if (route != null && route != _currentRoute) {
        _currentRoute = route;
        // No notificar para evitar bucles.
     }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    _currentRoute = AppRoutes.login; // Actualizar estado interno
    navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    notifyListeners();
  }
}