// actions/generar_tabla_insumos.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/shoping_list/screens/shopping_list_display_screen.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:provider/provider.dart';
// Podrías necesitar importar otros modelos y controladores aquí

Future<void> generarListaCompras(BuildContext context, Evento evento) async {
  // Verificar si el evento tiene ID, necesario para buscar sus relaciones
  if (evento.id == null || evento.id!.isEmpty) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text("El evento no tiene un ID válido para generar la lista."), backgroundColor: Colors.orange),
     );
     return;
  }
  final eventoId = evento.id!;
  debugPrint("[Action] Iniciando generación de lista de compras para Evento ID: $eventoId");

  // Mostrar indicador de carga modal (no bloquea taps fuera por defecto)
  showDialog(
    context: context,
    barrierDismissible: false, // No permitir cerrar tocando fuera
    builder: (BuildContext dialogContext) => const Center(
      child: Card( // Opcional: un card para mejor apariencia
         child: Padding(
           padding: EdgeInsets.all(20.0),
           child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 CircularProgressIndicator(),
                 SizedBox(width: 20),
                 Text("Generando lista..."),
              ],
           ),
         ),
      ),
    ),
  );

  try {
    // Obtener el servicio ShoppingListService usando Provider
    // Usamos read porque estamos fuera del build y no necesitamos escuchar cambios aquí
    final shoppingService = context.read<ShoppingListService>();

    // Generar la lista de compras agrupada para UN SOLO evento
    // NOTA: Si quisieras generar para múltiples eventos, pasarías una lista de IDs aquí
    final GroupedShoppingListResult listaAgrupada =
        await shoppingService.generateAndGroupShoppingList([eventoId]);

    // Cerrar el indicador de carga ANTES de navegar o mostrarSnackBar
    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return; // Verificar montaje de nuevo después del await

    // Verificar si la lista generada está vacía
    if (listaAgrupada.isEmpty) {
       debugPrint("[Action] Lista de compras generada vacía para Evento ID: $eventoId");
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("No se encontraron insumos requeridos para este evento.")),
       );
    } else {
       debugPrint("[Action] Lista de compras generada con ${listaAgrupada.length} grupos de proveedores.");
       // Navegar a la pantalla de visualización pasando la lista agrupada
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (_) => ShoppingListDisplayScreen(
              groupedShoppingList: listaAgrupada,
              eventoIds: [eventoId], // Pasar el ID del evento para el título
              // Podrías pasar el objeto Evento completo si la pantalla lo necesita
              // evento: evento,
           ),
         ),
       );
    }

  } catch (e, st) {
     debugPrint("[Action][ERROR] al generar lista de compras: $e\n$st");
     // Asegurarse de cerrar el diálogo de carga incluso si hay error
     if (context.mounted) Navigator.pop(context);
     if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar la lista de compras: $e"),
            backgroundColor: Colors.red,
          ),
        );
     }
  }
}