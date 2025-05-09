import 'package:flutter/material.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/repositories/evento_repository.dart';
import 'package:golo_app/repositories/plato_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_requerido_repository_impl.dart';
import 'package:golo_app/repositories/insumo_requerido_repository_impl.dart';
import 'package:golo_app/features/catalogos/proveedores/controllers/proveedor_controller.dart';
import 'package:golo_app/navigation/controllers/navigation_controller.dart';
import 'package:golo_app/repositories/insumo_repository_impl.dart';
import 'package:golo_app/repositories/intermedio_repository_impl.dart';
import 'package:golo_app/repositories/insumo_utilizado_repository_impl.dart';
import 'package:golo_app/repositories/proveedor_repository_impl.dart';
import 'package:golo_app/services/excel_export_service.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/eventos/buscador_eventos/controllers/buscador_eventos_controller.dart';
import 'repositories/evento_repository_impl.dart';
import 'repositories/plato_evento_repository_impl.dart';
import 'repositories/insumo_evento_repository_impl.dart';
import 'repositories/intermedio_evento_repository_impl.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- Crear Instancia de Firestore ---
  final db = FirebaseFirestore.instance;

  // --- Crear Instancias de Repositorios (usando la misma instancia 'db') ---
  // (Para mejor legibilidad y reutilización)
  final eventoRepo = EventoFirestoreRepository(db);
  final platoEventoRepo = PlatoEventoFirestoreRepository(db);
  final intermedioEventoRepo = IntermedioEventoFirestoreRepository(db);
  final insumoEventoRepo = InsumoEventoFirestoreRepository(db);
  final platoRepo = PlatoFirestoreRepository(db);
  final intermedioRepo = IntermedioFirestoreRepository(db);
  final insumoRepo = InsumoFirestoreRepository(db);
  final insumoRequeridoRepo = InsumoRequeridoFirestoreRepository(db);
  final intermedioRequeridoRepo = IntermedioRequeridoFirestoreRepository(db);
  final insumoUtilizadoRepo = InsumoUtilizadoFirestoreRepository(db);
  final proveedorRepo = ProveedorFirestoreRepository(db);
  final excelExportService = ExcelExportService();

  runApp(
    MultiProvider(
      providers: [
        // --- Proveedores de Controladores (Usando instancias de repo) ---
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(
          create:
              (_) => BuscadorEventosController(
                eventoRepository: eventoRepo,
                platoEventoRepository: platoEventoRepo,
                insumoEventoRepository: insumoEventoRepo,
                intermedioEventoRepository: intermedioEventoRepo,
              ),
        ),
        ChangeNotifierProvider(
          // InsumoController necesita InsumoRepository y ProveedorRepository
          create: (_) => InsumoController(insumoRepo, proveedorRepo),
        ),
        ChangeNotifierProvider(
          // ProveedorController necesita ProveedorRepository
          create: (_) => ProveedorController(proveedorRepo),
        ),
        ChangeNotifierProvider(
          // IntermedioController necesita IntermedioRepository y InsumoUtilizadoRepository
          create:
              (_) => IntermedioController(intermedioRepo, insumoUtilizadoRepo),
        ),
        ChangeNotifierProvider(
          // PlatoController necesita PlatoRepository, IntermedioRequeridoRepo, InsumoRequeridoRepo
          create:
              (_) => PlatoController(
                platoRepo,
                intermedioRequeridoRepo,
                insumoRequeridoRepo,
              ),
        ),
        Provider<EventoRepository>(
          create:
              (_) =>
                  eventoRepo, // Proveer la instancia ya creada de EventoRepository
        ),

        // --- Proveedor para el Servicio ---
        Provider<ShoppingListService>(
          create:
              (_) => ShoppingListService(
                // Pasar todas las instancias de repositorio necesarias
                eventoRepo: eventoRepo,
                platoEventoRepo: platoEventoRepo,
                intermedioEventoRepo: intermedioEventoRepo,
                insumoEventoRepo: insumoEventoRepo,
                platoRepo: platoRepo,
                intermedioRepo: intermedioRepo,
                insumoRepo: insumoRepo,
                insumoRequeridoRepo: insumoRequeridoRepo,
                intermedioRequeridoRepo: intermedioRequeridoRepo,
                insumoUtilizadoRepo: insumoUtilizadoRepo,
                proveedorRepo: proveedorRepo,
                // Si separaste el servicio de agrupación, créalo y pásalo aquí también:
                // providerGrouper: ProviderGroupingService(proveedorRepo: proveedorRepo),
              ),
          // Opcional: lazy: false si quieres que se cree inmediatamente al inicio
          // lazy: false,
        ),
        Provider<ExcelExportService>(create: (_) => excelExportService),
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
      initialRoute: AppRoutes.dashboard,
      routes: AppRoutes.routes, // Pantalla principal directa
    );
  }
}
