import 'package:flutter/material.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/features/dashboards/widgets/kpi_card.dart';
import 'package:table_calendar/table_calendar.dart';

class KPISection extends StatelessWidget {
  final List<Evento> eventos;
  const KPISection({super.key, required this.eventos});

  @override
  Widget build(BuildContext context) {
    // --- Lógica para calcular KPIs ---
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    final eventosHoy = eventos.where((e) => isSameDay(e.fecha, hoy)).length;
    final eventosPorConfirmar = eventos.where((e) => e.estado == EstadoEvento.enCotizacion || e.estado == EstadoEvento.cotizado).length;
    final eventosEnPrueba = eventos.where((e) => e.estado == EstadoEvento.enPruebaMenu).length;
    // -------------------------------

    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Text('Indicadores Clave', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias, // Para que el Row no se salga de los bordes redondeados
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Usar los valores calculados
                  KPICard(title: 'Eventos Hoy', value: eventosHoy.toString(), icon: Icons.today, color: Colors.blue),
                  KPICard(title: 'Por Confirmar', value: eventosPorConfirmar.toString(), icon: Icons.pending_actions, color: Colors.orange),
                  KPICard(title: 'En Prueba Menú', value: eventosEnPrueba.toString(), icon: Icons.restaurant_menu, color: Colors.green),
                ],
              ),
            ),
          ),
       ],
    );
  }
}