// actions/generar_tabla_insumos.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/common/utils/loading_dialog_helper.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/eventos/screens/shopping_list_display_screen.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/services/shopping_list_service.dart';
import 'package:provider/provider.dart';
// Podrías necesitar importar otros modelos y controladores aquí

Future<void> generarListaCompras(BuildContext context, Evento evento) async {
  // Verificar si el evento tiene ID, necesario para buscar sus relaciones
  if (evento.id == null || evento.id!.isEmpty) {
     showAppSnackBar(context, "El evento no tiene un ID válido.", isError: true);
     return;
  }
  final eventoId = evento.id!;
  debugPrint("[Action] Iniciando generación de lista de compras para Evento ID: $eventoId");

  final VoidCallback closeLoadingDialog = showLoadingDialog(context, message: 'Calculando...');

  try {
    final shoppingService = context.read<ShoppingListService>();
    final GroupedShoppingListResult listaAgrupada =
        await shoppingService.getCombinedGroupedShoppingList([eventoId]);
    
    // 2. Cierra el diálogo ANTES de hacer cualquier otra cosa.
    closeLoadingDialog();
    
    // 3. Verifica el montaje y navega/muestra feedback.
    if (!context.mounted) return;

    if (listaAgrupada.isEmpty) {
      debugPrint("[Action] Lista de compras generada vacía para Evento ID: $eventoId");
      showAppSnackBar(context, "No se encontraron insumos requeridos para este evento.");
    } else {
      debugPrint("[Action] Lista de compras generada con ${listaAgrupada.length} grupos de proveedores.");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingListDisplayScreen(
            groupedShoppingList: listaAgrupada,
            eventoIds: [eventoId],
            separateByFacturable: false, // Asumiendo combinado por defecto
          ),
        ),
      );
    }
  } catch (e, st) {
    debugPrint("[Action][ERROR] al generar lista de compras: $e\n$st");
    // 4. Cierra el diálogo también en caso de error.
    closeLoadingDialog();
    if (context.mounted) {
      showAppSnackBar(context, "Error al generar la lista de compras: $e", isError: true);
    }
  }
}