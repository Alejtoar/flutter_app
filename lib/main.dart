import 'package:flutter/material.dart';
import 'package:golo_app/navigation/nav_rail.dart';
import 'package:provider/provider.dart';

 
void main() {
  runApp(
    MultiProvider(
      providers: [], // Lista vacía por ahora
      child: const MyApp(),
    ),
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AppNavigation(), // Usamos nuestro navigation rail aquí
      debugShowCheckedModeBanner: false,
    );
  }
}