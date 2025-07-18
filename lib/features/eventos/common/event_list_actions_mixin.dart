import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/screens/evento_detalle_screen.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/features/eventos/controllers/buscador_eventos_controller.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/eventos/screens/editar_evento_screen.dart';
import 'package:golo_app/features/eventos/screens/shopping_list_display_screen.dart';
import 'package:provider/provider.dart';

// El mixin se aplica a un State<T> donde T es un StatefulWidget.
// Esto nos da acceso a `context`, `mounted` y `setState`.
mixin EventListActionsMixin<T extends StatefulWidget> on State<T> {

  // --- ESTADO QUE EL MIXIN GESTIONARÁ ---
  bool isSelectionMode = false;
  Set<String> selectedEventIds = {};

  
  void verDetalle(Evento evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventoDetalleScreen(eventoInicial: evento),
      ),
    );
  }

  void editarEvento(Evento? evento) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarEventoScreen(evento: evento)),
    ).then((result) {
      if (result == true && mounted) {
        // La pantalla que usa el mixin deberá implementar su propia recarga si es necesario.
        // O podemos hacer que el mixin llame a un método abstracto.
        context.read<BuscadorEventosController>().cargarEventos();
      }
    });
  }

  void eliminarEvento(Evento evento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text('¿Seguro que deseas eliminar "${evento.codigo}"?'),
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
    if (confirm != true || !mounted) return;

    final controller = context.read<BuscadorEventosController>();
    await controller.eliminarUnEvento(evento.id!);
    if (mounted) {
       if (controller.error != null) {
         showAppSnackBar(context, controller.error!, isError: true);
       } else {
         showAppSnackBar(context, 'Evento "${evento.codigo}" eliminado.');
       }
    }
  }

  void eliminarEventosSeleccionados() async {
    final cantidad = selectedEventIds.length;
    if (cantidad == 0) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar $cantidad Eventos'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
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
    if (confirm != true || !mounted) return;

    final controller = context.read<BuscadorEventosController>();
    await controller.eliminarEventosEnLote(selectedEventIds);

    if (mounted) {
      if (controller.error != null) {
        showAppSnackBar(context, controller.error!, isError: true);
      } else {
        showAppSnackBar(context, '$cantidad eventos eliminados.');
      }
      // El mixin se encarga de llamar a setState para actualizar la UI
      setState(() {
        isSelectionMode = false;
        selectedEventIds.clear();
      });
    }
  }

  void calcularListaDeComprasEnLote({required bool separarPorFacturable}) async {
    final idsACalcular = selectedEventIds.toList();
    if (idsACalcular.isEmpty) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final shoppingService = context.read<ShoppingListService>();
      GroupedShoppingListResult listaAgrupada;
      if (separarPorFacturable) {
         listaAgrupada = await shoppingService.getSeparatedGroupedShoppingList(idsACalcular);
      } else {
         listaAgrupada = await shoppingService.getCombinedGroupedShoppingList(idsACalcular);
      }

      if (!mounted) { Navigator.pop(context); return; }
      Navigator.pop(context); // Cerrar indicador

      if (listaAgrupada.isEmpty) {
        showAppSnackBar(context, "No se encontraron insumos para los eventos seleccionados.");
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShoppingListDisplayScreen(
              groupedShoppingList: listaAgrupada,
              eventoIds: idsACalcular,
              separateByFacturable: separarPorFacturable,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) showAppSnackBar(context, "Error al generar la lista de compras: $e", isError: true);
    }
  }
  Color colorPorEstado(EstadoEvento estado) {
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

  // --- AppBar Dinámica Común ---
  AppBar buildContextualAppBar(
      {required String defaultTitle, required VoidCallback onAdd}) {
    if (isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.blueGrey[700],
        title: Text('${selectedEventIds.length} seleccionados'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              isSelectionMode = false;
              selectedEventIds.clear();
            });
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Acciones en Lote',
            onSelected: (value) {
              switch (value) {
                case 'lista_compras_combinada':
                  calcularListaDeComprasEnLote(separarPorFacturable: false);
                  break;
                case 'lista_compras_separada':
                  calcularListaDeComprasEnLote(separarPorFacturable: true);
                  break;
                case 'eliminar':
                  eliminarEventosSeleccionados();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>( value: 'lista_compras_combinada', child: ListTile( leading: Icon(Icons.shopping_cart_checkout), title: Text('Compras (Combinado)'), ), ),
              const PopupMenuItem<String>( value: 'lista_compras_separada', child: ListTile( leading: Icon(Icons.splitscreen_outlined), title: Text('Compras (Separar Facturable)'), ), ),
              const PopupMenuDivider(),
              PopupMenuItem<String>( value: 'eliminar', child: ListTile( leading: Icon(Icons.delete_sweep_outlined, color: Colors.red[700]), title: Text('Eliminar Seleccionados', style: TextStyle(color: Colors.red[700])), ), ),
            ],
          ),
        ],
      );
    } else {
      // AppBar normal
      return AppBar(
        title: Text(defaultTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear Nuevo Evento',
            onPressed: onAdd,
          ),
        ],
      );
    }
  }
}