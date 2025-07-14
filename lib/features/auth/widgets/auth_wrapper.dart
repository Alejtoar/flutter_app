import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/auth/screens/login_page.dart';
import 'package:golo_app/navigation/app_routes.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Si el usuario está logueado, vamos al dashboard
          // Usar pushReplacementNamed es más seguro que microtask
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Si no, vamos a la página de login
        return const LoginPage(); // Asegúrate de que esta pantalla exista
      },
    );
  }
}