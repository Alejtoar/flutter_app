// buscador_eventos_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/empty_data_widget.dart';
import 'package:golo_app/features/common/widgets/generic_list_item_card.dart';
import 'package:golo_app/features/common/widgets/generic_list_view.dart';
import 'package:golo_app/features/eventos/buscador_eventos/screens/evento_detalle_screen.dart';
import 'package:golo_app/features/eventos/shoping_list/screens/shopping_list_display_screen.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Controladores y Widgets específicos de Eventos
import '../controllers/buscador_eventos_controller.dart';
import '../widgets/busqueda_bar_eventos.dart';
import 'editar_evento_screen.dart';

class BuscadorEventosScreen extends StatefulWidget {
  const BuscadorEventosScreen({Key? key}) : super(key: key);

  @override
  State<BuscadorEventosScreen> createState() => _BuscadorEventosScreenState();
}

class _BuscadorEventosScreenState extends State<BuscadorEventosScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Estado para selección múltiple
  bool _isSelectionMode = false;
  Set<String> _selectedEventoIds = {};

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

  // Para ver el detalle (navega a EventoDetalleScreen)
  void _verDetalle(Evento evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventoDetalleScreen(eventoInicial: evento),
      ),
    );
  }

  // Para navegar a la pantalla de edición
  void _editar(Evento? evento) {
    // Acepta Evento? para poder crear (con null)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarEventoScreen(evento: evento)),
    ).then((_) {
      // Opcional: recargar al volver si es necesario
      // context.read<BuscadorEventosController>().cargarEventos();
    });
  }

  // Para confirmar y eliminar UN SOLO evento
  void _eliminar(Evento evento) async {
    final controller = context.read<BuscadorEventosController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Evento'),
            content: Text(
              '¿Seguro que deseas eliminar el evento "${evento.codigo} - ${evento.nombreCliente}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      // Reusa la lógica del controlador que ya es robusta
      await controller.eliminarUnEvento(evento.id!);
      if (mounted && controller.error != null) {
        showAppSnackBar(context, controller.error!, isError: true);
      } else if (mounted) {
        showAppSnackBar(context, 'Evento "${evento.codigo}" eliminado.');
      }
    }
  }

  void _eliminarEventosSeleccionados() async {
    final idsAEliminar = Set<String>.from(_selectedEventoIds);
    final cantidad = idsAEliminar.length;
    if (cantidad == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Eliminar $cantidad Eventos'),
            content: const Text(
              '¿Estás seguro? Esta acción no se puede deshacer.',
            ),
            actions: [/* ... botones ... */],
          ),
    );
    if (confirm != true || !mounted) return;

    final controller = context.read<BuscadorEventosController>();
    await controller.eliminarEventosEnLote(idsAEliminar);

    if (mounted) {
      if (controller.error != null) {
        showAppSnackBar(context, controller.error!, isError: true);
      } else {
        showAppSnackBar(context, '$cantidad eventos han sido eliminados.');
      }
      setState(() {
        _isSelectionMode = false;
        _selectedEventoIds.clear();
      });
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

  void _calcularListaDeComprasEnLote({
    bool separarPorFacturable = false,
  }) async {
    final idsACalcular = _selectedEventoIds.toList();
    if (idsACalcular.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final shoppingService = context.read<ShoppingListService>();
      GroupedShoppingListResult listaAgrupada;

      if (separarPorFacturable) {
        // Llamar al método que separa los datos
        listaAgrupada = await shoppingService.getSeparatedGroupedShoppingList(
          idsACalcular,
        );
      } else {
        // Llamar al método que combina los datos
        listaAgrupada = await shoppingService.getCombinedGroupedShoppingList(
          idsACalcular,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador

      if (listaAgrupada.isEmpty) {
        /* ... SnackBar lista vacía ... */
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ShoppingListDisplayScreen(
                  groupedShoppingList: listaAgrupada,
                  eventoIds: idsACalcular,
                ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(
        context,
        "Error al generar la lista de compras: $e",
        isError: true,
      );
    }
  }

  AppBar _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor:
            Colors.blueGrey[700], // Color distintivo para modo selección
        title: Text('${_selectedEventoIds.length} seleccionados'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedEventoIds.clear();
            });
          },
        ),
        actions: [
          // --- Menú de Acciones en Lote ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // Icono de tres puntos
            tooltip: 'Acciones en Lote',
            onSelected: (value) {
              // Llamar a la función correspondiente según la opción seleccionada
              switch (value) {
                case 'lista_compras_combinada':
                  _calcularListaDeComprasEnLote(separarPorFacturable: false);
                  break;
                case 'lista_compras_separada':
                  _calcularListaDeComprasEnLote(separarPorFacturable: true);
                  break;
                case 'eliminar':
                  _eliminarEventosSeleccionados();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'lista_compras_combinada',
                    child: ListTile(
                      leading: Icon(Icons.shopping_cart_checkout),
                      title: Text('Calcular Lista de Compras (Total)'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'lista_compras_separada',
                    child: ListTile(
                      leading: Icon(Icons.splitscreen_outlined),
                      title: Text('Lista de Compras (Separar Facturable)'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.red[700],
                      ),
                      title: Text(
                        'Eliminar Seleccionados',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ),
                ],
          ),
        ],
      );
    } else {
      // AppBar normal (sin cambios)
      return AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear Nuevo Evento',
            onPressed: () => _editar(null),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
                    onSelectionModeChanged: (isSelectionMode) {
                      setState(() => _isSelectionMode = isSelectionMode);
                    },
                    onSelectionChanged: (selectedIds) {
                      setState(() => _selectedEventoIds = selectedIds);
                    },
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
                        cardColor: _colorPorEstado(evento.estado),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              color: _colorPorEstado(evento.estado),
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
                            _isSelectionMode
                                ? []
                                : [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'Ver Detalle',
                                    onPressed: () => _verDetalle(evento),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () => _editar(evento),
                                  ), // Llama a la nueva _editar
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminar(evento),
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

  // Helper para el color de estado (movido aquí desde ListaEventos)
  Color _colorPorEstado(EstadoEvento estado) {
    switch (estado) {
      case EstadoEvento.cotizado:
        return Colors.blue[100]!;
      case EstadoEvento.confirmado:
        return Colors.green[100]!;
      case EstadoEvento.completado:
        return Colors.grey[400]!;
      case EstadoEvento.cancelado:
        return Colors.red[200]!;
      case EstadoEvento.enPruebaMenu:
        return Colors.orange[200]!;
      case EstadoEvento.enCotizacion:
        return Colors.purple[100]!;
    }
  }
}
