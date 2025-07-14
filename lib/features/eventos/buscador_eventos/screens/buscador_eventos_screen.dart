// buscador_eventos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/eventos/buscador_eventos/screens/evento_detalle_screen.dart';
import 'package:golo_app/models/evento.dart'; // Asegúrate de importar el modelo Evento
import 'package:intl/intl.dart'; // Para formatear fechas en el botón de rango
import 'package:provider/provider.dart';

// Controladores y Widgets específicos de Eventos
import '../controllers/buscador_eventos_controller.dart';
import '../widgets/busqueda_bar_eventos.dart'; // Asumo que tienes este widget
import '../widgets/lista_eventos.dart'; // Asumo que tienes este widget
import 'editar_evento_screen.dart';

class BuscadorEventosScreen extends StatefulWidget {
  const BuscadorEventosScreen({Key? key}) : super(key: key);

  @override
  State<BuscadorEventosScreen> createState() => _BuscadorEventosScreenState();
}

class _BuscadorEventosScreenState extends State<BuscadorEventosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escucha cambios en el texto de búsqueda para actualizar el controller
    _searchController.addListener(_onSearchChanged);
    // Solicita la carga inicial de eventos de forma segura después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar que el widget todavía está montado antes de acceder al context
      if (mounted) {
        // Usamos listen: false aquí porque solo estamos disparando una acción,
        // la UI reaccionará a través de los Consumers/Selectors.
        Provider.of<BuscadorEventosController>(
          context,
          listen: false,
        ).cargarEventos();
      }
    });
  }

  @override
  void dispose() {
    // Limpiar el listener y el controller para evitar memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Actualiza el estado del controller cuando el texto de búsqueda cambia
  void _onSearchChanged() {
    // Usamos listen: false porque estamos dentro de un método que no es build
    Provider.of<BuscadorEventosController>(
      context,
      listen: false,
    ).setSearchText(_searchController.text);
  }

  // Navega a la pantalla de creación/edición de eventos
  void _abrirEditorEvento({Evento? evento}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasa el evento si es para editar, o null si es para crear
        builder: (_) => EditarEventoScreen(evento: evento),
      ),
    ).then((_) {
      // Opcional: Recargar eventos si hubo cambios al volver de la pantalla de edición.
      // Podría ser innecesario si el controller maneja bien la actualización local.
      // Provider.of<BuscadorEventosController>(context, listen: false).cargarEventos();
    });
  }

  // Muestra el diálogo de confirmación para eliminar
  Future<void> _confirmarEliminarEvento(Evento evento) async {
    final controller = Provider.of<BuscadorEventosController>(
      context,
      listen: false,
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Evento'),
            content: Text(
              '¿Estás seguro de que deseas eliminar el evento "${evento.codigo} - ${evento.nombreCliente}"?\nEsta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), // No confirmar
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), // Sí confirmar
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Destacar la acción destructiva
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      // Verificar mounted de nuevo por si el diálogo tardó mucho
      await controller.eliminarEvento(evento.id!);
      // Mostrar feedback si hubo error (opcional, el Consumer ya muestra el error global)
      // if (controller.error != null && mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error al eliminar: ${controller.error}')),
      //   );
      // }
    }
  }

  // Limpia todos los filtros aplicados
  void _limpiarFiltros() {
    _searchController.clear(); // Limpia también la barra de búsqueda
    final controller = Provider.of<BuscadorEventosController>(
      context,
      listen: false,
    );
    controller.setSearchText(
      '',
    ); // Asegura que el estado del controller se actualice
    controller.setFacturableFiltro(null);
    controller.setEstadoFiltro(null);
    controller.setTipoFiltro(null);
    controller.setFechaRangoFiltro(null);
  }

  // Muestra el selector de rango de fechas
  Future<void> _seleccionarRangoFechas(
    BuscadorEventosController controller,
  ) async {
    final initialDateRange =
        controller.fechaRangoFiltro ??
        DateTimeRange(
          start: DateTime.now().subtract(
            const Duration(days: 30),
          ), // Rango inicial por defecto
          end: DateTime.now(),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020), // Límite inferior
      lastDate: DateTime(DateTime.now().year + 5), // Límite superior razonable
      initialDateRange: initialDateRange,
      // locale: const Locale('es', 'ES'), // Descomentar para localización
    );

    if (pickedRange != null) {
      controller.setFechaRangoFiltro(pickedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear Nuevo Evento',
            onPressed:
                () => _abrirEditorEvento(), // Llama sin argumento para crear
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Barra de Búsqueda ---
            BusquedaBarEventos(
              controller: _searchController,
              // onChanged es manejado por el listener del controller
            ),
            const SizedBox(height: 8),

            // --- Sección de Filtros ---
            Consumer<BuscadorEventosController>(
              // Consumer solo para la sección de filtros
              builder: (context, controller, _) {
                bool hayFiltrosActivos =
                    controller.facturableFiltro != null ||
                    controller.estadoFiltro != null ||
                    controller.tipoFiltro != null ||
                    controller.fechaRangoFiltro != null ||
                    controller.searchText.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      // Usa Wrap para que los filtros se ajusten mejor en pantallas pequeñas
                      spacing: 8.0, // Espacio horizontal entre filtros
                      runSpacing: 4.0, // Espacio vertical si hay salto de línea
                      children: [
                        // --- Filtros Rápidos (Facturable) ---
                        FilterChip(
                          label: const Text('Facturable'),
                          selected: controller.facturableFiltro == true,
                          onSelected:
                              (selected) => controller.setFacturableFiltro(
                                selected ? true : null,
                              ),
                          tooltip: 'Mostrar solo eventos facturables',
                        ),
                        FilterChip(
                          label: const Text('No Facturable'),
                          selected: controller.facturableFiltro == false,
                          onSelected:
                              (selected) => controller.setFacturableFiltro(
                                selected ? false : null,
                              ),
                          tooltip: 'Mostrar solo eventos no facturables',
                        ),

                        // --- Filtro Dropdown (Estado) ---
                        DropdownButton<EstadoEvento?>(
                          value: controller.estadoFiltro,
                          hint: const Text('Estado'),
                          underline:
                              Container(), // Ocultar línea inferior si se desea
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos Estados'),
                            ),
                            ...EstadoEvento.values.map(
                              (estado) => DropdownMenuItem(
                                value: estado,
                                // Muestra el nombre del enum de forma legible
                                child: Text(estado.name),
                              ),
                            ),
                          ],
                          onChanged:
                              (value) => controller.setEstadoFiltro(value),
                        ),

                        // --- Filtro Dropdown (Tipo) ---
                        DropdownButton<TipoEvento?>(
                          value: controller.tipoFiltro,
                          hint: const Text('Tipo'),
                          underline: Container(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos Tipos'),
                            ),
                            ...TipoEvento.values.map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(
                                  tipo.name,
                                ), // Muestra el nombre del enum
                              ),
                            ),
                          ],
                          onChanged: (value) => controller.setTipoFiltro(value),
                        ),

                        // --- Botón Filtro Fecha ---
                        ElevatedButton.icon(
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            controller.fechaRangoFiltro != null
                                ? '${DateFormat('dd/MM/yy').format(controller.fechaRangoFiltro!.start)} - ${DateFormat('dd/MM/yy').format(controller.fechaRangoFiltro!.end)}'
                                : 'Fechas',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _seleccionarRangoFechas(controller),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),

                        // --- Botón Limpiar Filtros (solo si hay filtros activos) ---
                        if (hayFiltrosActivos)
                          TextButton.icon(
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Limpiar'),
                            onPressed: _limpiarFiltros,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 24), // Separador visual
            // --- Lista de Eventos ---
            Expanded(
              child: Consumer<BuscadorEventosController>(
                // Consumer principal para la lista
                builder: (context, controller, _) {
                  // 1. Manejar estado de carga
                  if (controller.loading && controller.eventos.isEmpty) {
                    // Muestra loading solo si la lista está vacía (carga inicial)
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. Manejar estado de error
                  if (controller.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error al cargar eventos:\n${controller.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    );
                  }

                  // 3. Manejar estado vacío (después de carga, sin errores)
                  if (controller.eventos.isEmpty && !controller.loading) {
                    return const EmptyDataWidget(
                      message: 'No hay eventos creados.',
                      callToAction: 'Presiona el botón + para agregar tu primer evento.',
                      icon: Icons.event_note_outlined,
                    );
                  }

                  // 4. Aplicar filtros a la lista cargada
                  final eventosFiltrados =
                      controller.eventos.where((evento) {
                        // Filtro por texto (insensible a mayúsculas)
                        final textLow = controller.searchText.toLowerCase();
                        final matchesText =
                            textLow.isEmpty ||
                            evento.nombreCliente.toLowerCase().contains(
                              textLow,
                            ) ||
                            evento.codigo.toLowerCase().contains(textLow);

                        // Filtro por facturable
                        final matchesFacturable =
                            controller.facturableFiltro == null ||
                            evento.facturable == controller.facturableFiltro;

                        // Filtro por estado
                        final matchesEstado =
                            controller.estadoFiltro == null ||
                            evento.estado == controller.estadoFiltro;

                        // Filtro por tipo
                        final matchesTipo =
                            controller.tipoFiltro == null ||
                            evento.tipoEvento == controller.tipoFiltro;

                        // Filtro por fecha (asegurarse que end sea inclusivo)
                        final matchesFecha;
                        if (controller.fechaRangoFiltro == null) {
                          matchesFecha = true;
                        } else {
                          // Comparar solo la fecha, ignorando la hora
                          final fechaEvento = DateUtils.dateOnly(evento.fecha);
                          final fechaInicio = DateUtils.dateOnly(
                            controller.fechaRangoFiltro!.start,
                          );
                          // Para que el final sea inclusivo, comparamos con el día siguiente al final del rango
                          final fechaFinSiguiente = DateUtils.addDaysToDate(
                            DateUtils.dateOnly(
                              controller.fechaRangoFiltro!.end,
                            ),
                            1,
                          );

                          matchesFecha =
                              !fechaEvento.isBefore(fechaInicio) &&
                              fechaEvento.isBefore(fechaFinSiguiente);
                        }

                        // Retorna true si CUMPLE TODOS los filtros aplicados
                        return matchesText &&
                            matchesFacturable &&
                            matchesEstado &&
                            matchesTipo &&
                            matchesFecha;
                      }).toList();

                  // 5. Mostrar mensaje si no hay resultados después de filtrar
                  if (eventosFiltrados.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay eventos que coincidan con los filtros.',
                      ),
                    );
                  }

                  // 6. Mostrar la lista filtrada
                  return ListaEventos(
                    eventos: eventosFiltrados,
                    onVerDetalle: (evento) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventoDetalleScreen(eventoInicial: evento),
                        ),
                      );
                    },
                    onEditar: (evento) {
                      _abrirEditorEvento(evento: evento);
                    },
                    onEliminar: (evento) {
                      _confirmarEliminarEvento(evento);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
