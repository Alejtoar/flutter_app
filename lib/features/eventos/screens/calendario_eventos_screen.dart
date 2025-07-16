import 'package:flutter/material.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:golo_app/features/eventos/common/event_list_actions_mixin.dart';
import 'package:golo_app/features/eventos/controllers/buscador_eventos_controller.dart';
import 'package:golo_app/models/evento.dart'; // Modelo Evento
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarioEventosScreen extends StatefulWidget {
  const CalendarioEventosScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioEventosScreen> createState() =>
      _CalendarioEventosScreenState();
}

class _CalendarioEventosScreenState extends State<CalendarioEventosScreen>
    with EventListActionsMixin<CalendarioEventosScreen> {
  // Estado para el calendario
  CalendarFormat _calendarFormat = CalendarFormat.month; // Vista inicial
  DateTime _focusedDay =
      DateTime.now(); // El día que el calendario está mostrando (ej. el mes de hoy)
  DateTime? _selectedDay; // El día que el usuario ha tocado

  // Lista para los eventos del día seleccionado
  late final ValueNotifier<List<Evento>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    // Cargar los eventos si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BuscadorEventosController>().cargarEventos();
    });

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // --- Lógica del Calendario ---

  // Función que obtiene los eventos para un día específico
  List<Evento> _getEventsForDay(DateTime day) {
    // Obtener la lista completa de eventos del controller
    final controller = context.read<BuscadorEventosController>();
    // Filtrar los eventos cuya fecha coincida con el día seleccionado
    // Es importante comparar solo año, mes y día, ignorando la hora.
    return controller.eventos
        .where((evento) => isSameDay(evento.fecha, day))
        .toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        isSelectionMode = false;
        selectedEventIds.clear();
      });
      // Actualizar la lista de eventos para el nuevo día seleccionado
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildContextualAppBar(
        defaultTitle: 'Calendario de Eventos',
        onAdd: () => editarEvento(null),
      ),
      body: Consumer<BuscadorEventosController>(
        // Escuchar cambios en la lista de eventos
        builder: (context, controller, child) {
          if (controller.loading && controller.eventos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // --- EL WIDGET DEL CALENDARIO ---
              TableCalendar<Evento>(
                locale: 'es_ES', // Usar localización en español
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // --- Parte clave: Mostrar marcadores para los eventos ---
                eventLoader: (day) {
                  return _getEventsForDay(day);
                },
                // Personalizar la apariencia del calendario
                calendarStyle: const CalendarStyle(
                  // Estilo para los marcadores de eventos
                  markerDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonShowsNext: false,
                ),
              ),
              const SizedBox(height: 8.0),

              // --- LISTA DE EVENTOS PARA EL DÍA SELECCIONADO ---
              Expanded(
                child: ValueListenableBuilder<List<Evento>>(
                  valueListenable: _selectedEvents,
                  builder: (context, eventosDelDia, _) {
                    return GenericListView<Evento>(
                      items: eventosDelDia,
                      idGetter: (evento) => evento.id!,
                      onSelectionModeChanged:
                          (isMode) => setState(() => isSelectionMode = isMode),
                      onSelectionChanged:
                          (ids) => setState(() => selectedEventIds = ids),
                      itemBuilder: (context, evento, isSelected, onSelect) {
                        // Usar una Card o ListTile personalizado aquí
                        return GenericListItemCard(
                          isSelected: isSelected,
                          onSelect: onSelect,
                          title: Text(evento.nombreCliente),
                          subtitle: Text(
                            'Fecha: ${DateFormat('dd/MM/yy').format(evento.fecha)}\nEstado: ${evento.estado.name}',
                          ),
                          // Opcional: un color de fondo como en tu ListaEventos original
                          cardColor: colorPorEstado(evento.estado),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                color: colorPorEstado(evento.estado),
                              ), // Icono coloreado por estado
                              Text(
                                evento.codigo,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          actions:
                              isSelectionMode
                                  ? []
                                  : [
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'Ver Detalle',
                                      onPressed: () => verDetalle(evento),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar',
                                      onPressed: () => editarEvento(evento),
                                    ), // Llama a la nueva _editar
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      tooltip: 'Eliminar',
                                      onPressed: () => eliminarEvento(evento),
                                    ), // Llama a la nueva _eliminar
                                  ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
