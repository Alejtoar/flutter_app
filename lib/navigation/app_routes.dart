import 'package:flutter/material.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumos_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedios_screen.dart';
import 'package:golo_app/features/catalogos/platos/screens/platos_screen.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedores_screen.dart';
import 'package:golo_app/features/eventos/screens/buscador_eventos_screen.dart';
import 'package:golo_app/features/eventos/screens/calendario_eventos_screen.dart';
//import 'package:golo_app/navigation/widgets/main_scaffold.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String insumos = '/catalogos/insumos';
  static const String intermedios = '/catalogos/intermedios';
  static const String platos = '/catalogos/platos';
  static const String proveedores = '/catalogos/proveedores';
  static const String eventosBuscador = '/eventos/buscar';
  static const String eventosCalendario = '/eventos/calendario';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    dashboard: (context) => DashboardScreen(),
    insumos: (context) => InsumosScreen(),
    intermedios: (context) => IntermediosScreen(),
    platos: (context) => PlatosScreen(),
    proveedores: (context) => ProveedoresScreen(),
    eventosBuscador: (context) => BuscadorEventosScreen(),
    eventosCalendario: (context) => CalendarioEventosScreen(),
  };
}
