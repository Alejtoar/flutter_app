import 'package:flutter/material.dart';
import 'package:golo_app/features/dashboards/widgets/kpi_section.dart'; // Separaremos los widgets
import 'package:golo_app/features/dashboards/widgets/quick_actions_section.dart';
import 'package:golo_app/features/dashboards/widgets/upcoming_events_section.dart';
import 'package:golo_app/features/eventos/controllers/buscador_eventos_controller.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los datos necesarios para el dashboard al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    // Usar el controlador de eventos para cargar la lista de eventos
    // (si no está ya cargada por otra pantalla)
    final eventosController = context.read<BuscadorEventosController>();
    if (eventosController.eventos.isEmpty) {
        await eventosController.cargarEventos();
    }
    // Si necesitas datos de otros controladores, cárgalos aquí también
    // await context.read<InsumoController>().cargarInsumos();
  }

  Future<void> _refreshData() async {
    // Función para el RefreshIndicator
    await context.read<BuscadorEventosController>().cargarEventos();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un Consumer para que las secciones se reconstruyan si los datos cambian
    return Consumer<BuscadorEventosController>(
      builder: (context, eventosController, child) {
        if (eventosController.loading && eventosController.eventos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            // physics: AlwaysScrollableScrollPhysics() para que el refresh funcione aunque no haya scroll
            physics: const AlwaysScrollableScrollPhysics(), 
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del Día', // Título más dinámico
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Pasar la lista de eventos a los widgets que la necesitan
                KPISection(eventos: eventosController.eventos),
                const SizedBox(height: 24),
                const QuickActionsSection(),
                const SizedBox(height: 24),
                UpcomingEventsSection(eventos: eventosController.eventos),
              ],
            ),
          ),
        );
      },
    );
  }
}