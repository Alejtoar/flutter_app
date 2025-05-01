// lib/features/eventos/buscador_eventos/widgets/botones_detalle_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/evento.dart';
// Importar pantalla de edición para el callback onEditar (si la navegación se queda aquí)
// O quitar esto si la navegación se maneja en la pantalla padre a través del callback.
// import 'package:golo_app/features/eventos/buscador_eventos/screens/editar_evento_screen.dart';

class BotonesDetalleEvento extends StatelessWidget {
  final Evento evento;
  final bool isLoading; // Para deshabilitar botones durante la carga
  // Callbacks para cada acción
  final VoidCallback onEditar;
  final VoidCallback onGenerarFactura;
  final VoidCallback onGenerarListaCompras;
  final VoidCallback onExportarPdfCompleto;
  final VoidCallback onExportarPdfSimple;

  const BotonesDetalleEvento({
    Key? key,
    required this.evento,
    this.isLoading = false,
    required this.onEditar,
    required this.onGenerarFactura,
    required this.onGenerarListaCompras,
    required this.onExportarPdfCompleto,
    required this.onExportarPdfSimple,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color? disabledFgColor = Colors.grey[700]; // Color para texto/icono deshabilitado
    final Color? disabledBgColor = Colors.grey[300]; // Color para fondo deshabilitado

    return Padding(
      // Añadir padding alrededor del grupo de botones si se desea
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 10.0, // Espacio horizontal entre botones
        runSpacing: 10.0, // Espacio vertical si hay salto de línea
        alignment: WrapAlignment.center, // Centrar los botones
        children: [
          // --- Botón Editar ---
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text("Editar"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 40), // Tamaño mínimo
              // Cambiar color si está deshabilitado
              backgroundColor: isLoading ? disabledBgColor : Theme.of(context).colorScheme.primary,
              foregroundColor: isLoading ? disabledFgColor : Colors.white,
              disabledForegroundColor: disabledFgColor?.withValues(alpha: 0.8),
            ),
            // Llama al callback onEditar pasado desde la pantalla padre
            onPressed: isLoading ? null : onEditar,
          ),

          // --- Botón Lista Compras ---
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_checkout, size: 18),
            label: const Text("Compras"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 40),
              backgroundColor: isLoading ? disabledBgColor : Theme.of(context).colorScheme.primary,
              foregroundColor: isLoading ? disabledFgColor : Colors.white,
              disabledForegroundColor: disabledFgColor?.withValues(alpha: 0.8),
            ),
            onPressed: isLoading ? null : onGenerarListaCompras,
          ),

          // --- Botón Factura ---
          ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text("Factura"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 40),
              backgroundColor: isLoading ? disabledBgColor : Theme.of(context).colorScheme.primary,
              foregroundColor: isLoading ? disabledFgColor : Colors.white,
              disabledForegroundColor: disabledFgColor?.withValues(alpha: 0.8),
            ),
            onPressed: isLoading ? null : onGenerarFactura,
          ),

          // --- Menú Exportar PDF (como botón) ---
          PopupMenuButton<String>(
            // Usar un ElevatedButton como el child que el usuario ve y toca
            // El onPressed aquí puede ser null porque PopupMenuButton maneja el tap.
            // O dejarlo vacío: onPressed: isLoading ? null : (){},
            enabled: !isLoading, // El menú se deshabilita si isLoading es true
            tooltip: "Exportar a PDF",
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text("Exportar PDF"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(110, 40),
                backgroundColor:
                    isLoading
                        ? disabledBgColor
                        : Theme.of(context).colorScheme.primary,
                foregroundColor: isLoading ? disabledFgColor : Colors.white,
                disabledForegroundColor: disabledFgColor?.withValues(alpha: 0.8),
                disabledBackgroundColor: disabledBgColor,
              ),
              onPressed: isLoading ? null : null,
            ),
            // Cuando se selecciona una opción del menú:
            onSelected: (String value) {
              // Llama al callback correspondiente pasado desde la pantalla padre
              if (value == 'completo') {
                onExportarPdfCompleto();
              } else if (value == 'simple') {
                onExportarPdfSimple();
              }
            },
            // Define las opciones del menú
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'completo', // Valor devuelto en onSelected
                    child: ListTile(
                      leading: Icon(Icons.article_outlined, size: 20),
                      title: Text(
                        'Completo',
                        style: TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'simple', // Valor devuelto en onSelected
                    child: ListTile(
                      leading: Icon(Icons.summarize_outlined, size: 20),
                      title: Text(
                        'Simple',
                        style: TextStyle(fontSize: 14),
                      ),
                      dense: true,
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
