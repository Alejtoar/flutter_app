import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golo_app/features/auth/widgets/auth_wrapper.dart';
import 'package:golo_app/navigation/widgets/main_scaffold.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/features/dashboards/screens/dashboard_screen.dart';
// ... importa todas tus pantallas ...
import 'package:golo_app/features/eventos/screens/calendario_eventos_screen.dart';
import 'package:golo_app/config/app_config.dart';
import 'package:golo_app/features/catalogos/insumos/screens/insumos_screen.dart';
import 'package:golo_app/features/catalogos/intermedios/screens/intermedios_screen.dart';
import 'package:golo_app/features/catalogos/platos/screens/platos_screen.dart';
import 'package:golo_app/features/catalogos/proveedores/screens/proveedores_screen.dart';
import 'package:golo_app/features/eventos/screens/buscador_eventos_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String insumos = '/catalogos/insumos';
  static const String intermedios = '/catalogos/intermedios';
  static const String platos = '/catalogos/platos';
  static const String proveedores = '/catalogos/proveedores';
  static const String eventosBuscador = '/eventos/buscar';
  static const String eventosCalendario = '/eventos/calendario';
  // Añade rutas para edición si quieres
  // static const String eventoEdit = '/eventos/editar'; // :id se añadirá dinámicamente

  // La clave global para el Navigator, ahora gestionada por go_router
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Una clave separada para el Navigator DENTRO del MainScaffold
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: AppConfig.instance.environment == Environment.dev ? dashboard : '/',
    navigatorKey: _rootNavigatorKey,
     redirect: (BuildContext context, GoRouterState state) {
       final bool loggedIn = FirebaseAuth.instance.currentUser != null;
       final bool isLoggingIn = state.matchedLocation == login;

       // Si no está logueado y no está en la página de login, redirigir a login
       // (Esto es para el flavor 'prod')
       if (!loggedIn && !isLoggingIn && AppConfig.instance.environment == Environment.prod) {
          return login;
       }

       // Si está logueado y en la página de login, redirigir al dashboard
       if (loggedIn && isLoggingIn) {
          return dashboard;
       }
       
       // En todos los demás casos, no redirigir
       return null;
    },
    routes: [
      // --- Rutas que NO tienen la barra lateral/inferior ---
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      // --- RUTA CONTENEDORA (SHELL ROUTE) ---
      // Todas las rutas anidadas aquí se mostrarán DENTRO del MainScaffold
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // El 'child' es la pantalla actual (Dashboard, Platos, etc.)
          return MainScaffold(child: child);
        },
        routes: [
          // Estas son las pantallas que usan el MainScaffold
          GoRoute(
            path: dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: platos,
            builder: (context, state) => const PlatosScreen(),
          ),
          GoRoute(
            path: insumos,
            builder: (context, state) => const InsumosScreen(),
          ),
           GoRoute(
            path: intermedios,
            builder: (context, state) => const IntermediosScreen(),
          ),
           GoRoute(
            path: proveedores,
            builder: (context, state) => const ProveedoresScreen(),
          ),
           GoRoute(
            path: eventosBuscador,
            builder: (context, state) => const BuscadorEventosScreen(),
          ),
           GoRoute(
            path: eventosCalendario,
            builder: (context, state) => const CalendarioEventosScreen(),
          ),
          // Aquí puedes añadir rutas de edición que también usen el Scaffold
          // GoRoute(
          //   path: '/eventos/editar/:id', // :id es un parámetro
          //   builder: (context, state) {
          //      final eventId = state.pathParameters['id'];
          //      // ... Lógica para cargar y mostrar EditarEventoScreen
          //   }
          // ),
        ],
      ),
    ],
  );
}