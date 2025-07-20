import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';

/// Controlador que maneja la navegación de la aplicación.
/// 
/// Este controlador centraliza la lógica de navegación, permitiendo cambiar de ruta
/// desde cualquier parte de la aplicación sin necesidad de un BuildContext.
class NavigationController extends ChangeNotifier {
  /// Clave global para acceder al NavigatorState desde cualquier lugar
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Ruta actual de la aplicación
  String _currentRoute = AppRoutes.dashboard;

  /// Obtiene la ruta actual
  String get currentRoute => _currentRoute;

  /// Navega a la ruta especificada
  /// 
  /// [route] La ruta a la que se desea navegar. Si es '/logout', 
  /// se manejará el cierre de sesión.
  void navigateTo(String route) {
    if (route == '/logout') {
      _handleLogout();
      return;
    }

    // Evitar navegación redundante si ya estamos en la ruta objetivo
    if (_currentRoute == route) return;

    _currentRoute = route;
    // Navegar a la nueva ruta y limpiar el historial de navegación
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
    
    // Notificar a los listeners que la ruta ha cambiado
    notifyListeners();
  }

  /// Sincroniza la ruta actual con la ruta del navegador
  /// 
  /// Este método se debe llamar desde el método didChangeDependencies de un widget
  /// para asegurar que el estado de navegación sea consistente con la URL actual.
  void syncRouteOnStartup(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null && route != _currentRoute) {
      _currentRoute = route;
      // No se notifica para evitar bucles de renderizado
    }
  }

  /// Maneja el proceso de cierre de sesión
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    _currentRoute = AppRoutes.login;
    // Navegar a la pantalla de login y limpiar el historial
    navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    notifyListeners();
  }
}