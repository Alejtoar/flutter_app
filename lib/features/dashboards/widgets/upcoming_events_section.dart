import 'package:flutter/material.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/navigation/app_routes.dart';
import 'package:intl/intl.dart';
// Para la pantalla de detalle
import 'package:golo_app/features/eventos/screens/evento_detalle_screen.dart';


class UpcomingEventsSection extends StatelessWidget {
  final List<Evento> eventos;
  const UpcomingEventsSection({super.key, required this.eventos});

  @override
  Widget build(BuildContext context) {
    // --- Lógica para obtener los próximos 3 eventos ---
    final ahora = DateTime.now();
    final proximosEventos = eventos
        .where((e) => e.fecha.isAfter(ahora) && e.estado == EstadoEvento.confirmado)
        .toList();
    // Ordenar por fecha más cercana primero
    proximosEventos.sort((a, b) => a.fecha.compareTo(b.fecha));
    final eventosAMostrar = proximosEventos.take(3).toList();
    // ------------------------------------------------

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text('Próximos Eventos (Confirmados)', style: Theme.of(context).textTheme.titleLarge),
         const SizedBox(height: 16),
         Card(
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 if (eventosAMostrar.isEmpty)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 32.0),
                     child: Text('No hay eventos confirmados próximamente.'),
                   )
                 else
                   ListView.separated(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: eventosAMostrar.length,
                     separatorBuilder: (_, __) => const Divider(),
                     itemBuilder: (context, index) {
                       final evento = eventosAMostrar[index];
                       return ListTile(
                         leading: const Icon(Icons.event_available),
                         title: Text(evento.nombreCliente),
                         subtitle: Text(DateFormat('dd MMMM yyyy, hh:mm a', 'es_ES').format(evento.fecha)),
                         trailing: const Icon(Icons.chevron_right),
                         onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => EventoDetalleScreen(eventoInicial: evento)));
                         },
                       );
                     },
                   ),
                 const Divider(),
                 Align(
                   alignment: Alignment.centerRight,
                   child: TextButton(
                     onPressed: () {
                       Navigator.pushNamed(context, AppRoutes.eventosBuscador);
                     },
                     child: const Text('Ver todos los eventos'),
                   ),
                 ),
               ],
             ),
           ),
         ),
      ],
    );
  }
}