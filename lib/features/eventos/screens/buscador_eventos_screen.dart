// buscador_eventos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:golo_app/features/eventos/common/event_list_actions_mixin.dart';
import 'package:golo_app/models/evento.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Controladores y Widgets específicos de Eventos
import '../controllers/buscador_eventos_controller.dart';
import '../widgets/busqueda_bar_eventos.dart';

class BuscadorEventosScreen extends StatefulWidget {
  const BuscadorEventosScreen({Key? key}) : super(key: key);

  @override
  State<BuscadorEventosScreen> createState() => _BuscadorEventosScreenState();
}

class _BuscadorEventosScreenState extends State<BuscadorEventosScreen>
    with EventListActionsMixin<BuscadorEventosScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Estado para selección múltiple

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
      appBar: buildContextualAppBar(
        defaultTitle: 'Eventos',
        onAdd: () => editarEvento(null),
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
                      callToAction:
                          'Presiona el botón + para agregar tu primer evento.',
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
                  return GenericListView<Evento>(
                    items: eventosFiltrados,
                    idGetter: (evento) => evento.id!,
                    onSelectionModeChanged: (isMode) => setState(() => isSelectionMode = isMode), // Actualiza la variable del mixin
                    onSelectionChanged: (ids) => setState(() => selectedEventIds = ids),
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
        ),
      ),
    );
  }
}
