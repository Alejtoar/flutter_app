import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/navigation/navigation_page.dart';
import 'package:golo_app/repositories/insumo_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_repository_impl.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository_impl.dart';
import 'package:golo_app/repositories/proveedor_repository_impl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationController()),
        Provider(create: (_) => FirebaseFirestore.instance),
        ChangeNotifierProvider(
          create:
              (context) => InsumoController(
                InsumoFirestoreRepository(
                  Provider.of<FirebaseFirestore>(context, listen: false),
                ),
                ProveedorFirestoreRepository(
                  Provider.of<FirebaseFirestore>(context, listen: false),
                ),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => ProveedorController(
                ProveedorFirestoreRepository(
                  Provider.of<FirebaseFirestore>(context, listen: false),
                ),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (_) => IntermedioController(
                IntermedioFirestoreRepository(FirebaseFirestore.instance),
                InsumoUtilizadoFirestoreRepository(FirebaseFirestore.instance),
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Golo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NavigationPage(), // Pantalla principal directa
    );
  }
}
