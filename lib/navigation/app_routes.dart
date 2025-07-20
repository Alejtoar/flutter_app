import 'package:flutter/material.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumos_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedios_screen.dart';
import 'package:golo_app/features/catalogos/platos/screens/platos_screen.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedores_screen.dart';
import 'package:golo_app/features/eventos/screens/buscador_eventos_screen.dart';
import 'package:golo_app/features/eventos/screens/calendario_eventos_screen.dart';
import 'package:golo_app/navigation/widgets/main_scaffold.dart';

/// Clase que contiene las rutas de la aplicación y sus respectivos builders.
/// 
/// Esta clase centraliza la definición de rutas y la construcción de pantallas,
/// facilitando la navegación y mantenimiento de la aplicación.
class AppRoutes {
  // Rutas de autenticación
  static const String login = '/login';
  
  // Rutas principales
  static const String dashboard = '/dashboard';
  
  // Rutas de catálogos
  static const String insumos = '/catalogos/insumos';
  static const String intermedios = '/catalogos/intermedios';
  static const String platos = '/catalogos/platos';
  static const String proveedores = '/catalogos/proveedores';
  
  // Rutas de eventos
  static const String eventosBuscador = '/eventos/buscar';
  static const String eventosCalendario = '/eventos/calendario';

  /// Mapa que asocia cada ruta con su respectivo constructor de pantalla.
  /// 
  /// Cada entrada en este mapa define una ruta de la aplicación y la función
  /// que construye la pantalla correspondiente, envuelta en un MainScaffold.
  static final Map<String, WidgetBuilder> routes = {
    // Pantalla de inicio de sesión
    login: (context) => const LoginPage(),
    
    // Pantalla principal
    dashboard: (context) => const MainScaffold(child: DashboardScreen()),
    
    // Pantallas de catálogos
    insumos: (context) => const MainScaffold(child: InsumosScreen()),
    intermedios: (context) => const MainScaffold(child: IntermediosScreen()),
    platos: (context) => const MainScaffold(child: PlatosScreen()),
    proveedores: (context) => const MainScaffold(child: ProveedoresScreen()),
    
    // Pantallas de eventos
    eventosBuscador: (context) => const MainScaffold(child: BuscadorEventosScreen()),
    eventosCalendario: (context) => const MainScaffold(child: CalendarioEventosScreen()),
  };
}
