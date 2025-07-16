// evento_detalle_screen.dart (Versión Final Simplificada)
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:golo_app/features/eventos/actions/generar_tabla_insumos.dart';
import 'package:golo_app/features/eventos/screens/editar_evento_screen.dart';
import 'package:golo_app/models/evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo.dart';

import 'package:golo_app/features/eventos/controllers/buscador_eventos_controller.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// Importar el widget de botones
import 'package:golo_app/features/eventos/widgets/botones_detalle_evento.dart';
// Importaciones para PDF
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class EventoDetalleScreen extends StatefulWidget {
  final Evento eventoInicial;

  const EventoDetalleScreen({Key? key, required this.eventoInicial})
    : super(key: key);

  @override
  State<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends State<EventoDetalleScreen> {
  bool _isLoading = true;
  String? _error;
  Evento?
  _eventoCompleto; // Usaremos este para pasar a los botones si es necesario

  // Listas y Mapas para formateo (igual que antes)
  List<PlatoEvento> _platosEvento = [];
  List<IntermedioEvento> _intermediosEvento = [];
  List<InsumoEvento> _insumosEvento = [];
  Map<String, Plato> _mapaPlatos = {};
  Map<String, Intermedio> _mapaIntermedios = {};
  Map<String, Insumo> _mapaInsumos = {};

  @override
  void initState() {
    super.initState();
    _eventoCompleto = widget.eventoInicial;
    _cargarDetallesCompletos();
  }

  // --- _cargarDetallesCompletos (igual que antes) ---
  Future<void> _cargarDetallesCompletos() async {
    // ... (misma implementación que la versión anterior de esta pantalla)
    if (!mounted) return;
    debugPrint(
      "[EventoDetalleScreen] Iniciando carga completa de detalles para evento ID: ${widget.eventoInicial.id}",
    );
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final buscadorCtrl = context.read<BuscadorEventosController>();
      final platoCtrl = context.read<PlatoController>();
      final intermedioCtrl = context.read<IntermedioController>();
      final insumoCtrl = context.read<InsumoController>();
      _eventoCompleto = widget.eventoInicial; // Resetear por si acaso
      await buscadorCtrl.cargarRelacionesPorEvento(widget.eventoInicial.id!);
      if (!mounted) return;
      _platosEvento = List.from(buscadorCtrl.platosEvento);
      _intermediosEvento = List.from(buscadorCtrl.intermediosEvento);
      _insumosEvento = List.from(buscadorCtrl.insumosEvento);
      await Future.wait([
        if (platoCtrl.platos.isEmpty) platoCtrl.cargarPlatos(),
        if (intermedioCtrl.intermedios.isEmpty)
          intermedioCtrl.cargarIntermedios(),
        if (insumoCtrl.insumos.isEmpty) insumoCtrl.cargarInsumos(),
      ]);
      if (!mounted) return;
      _mapaPlatos = {
        for (var p in platoCtrl.platos)
          if (p.id != null) p.id!: p,
      };
      _mapaIntermedios = {
        for (var i in intermedioCtrl.intermedios)
          if (i.id != null) i.id!: i,
      };
      _mapaInsumos = {
        for (var i in insumoCtrl.insumos)
          if (i.id != null) i.id!: i,
      };
    } catch (e, st) {
      debugPrint(
        "[EventoDetalleScreen][ERROR] Cargando detalles completos: $e\n$st",
      );
      if (mounted) setState(() => _error = "Error al cargar detalles: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helpers de Formato (igual que antes, necesarios para la vista) ---
  String _formatNombrePlato(PlatoEvento pe) {
    String nombreBase = _mapaPlatos[pe.platoId]?.nombre ?? pe.platoId;
    String nombreFinal =
        pe.nombrePersonalizado?.isNotEmpty ?? false
            ? "${pe.nombrePersonalizado} ($nombreBase)" // Muestra ambos si hay personalizado
            : nombreBase;

    // Añadir extras
    String extrasStr = "";
    if (pe.insumosExtra?.isNotEmpty ?? false) {
      extrasStr +=
          "+I: " +
          pe.insumosExtra!
              .map(
                (e) => "${_mapaInsumos[e.id]?.nombre ?? e.id} x${e.cantidad}",
              )
              .join(', ');
    }
    if (pe.intermediosExtra?.isNotEmpty ?? false) {
      if (extrasStr.isNotEmpty) extrasStr += " ";
      extrasStr +=
          "+M: " +
          pe.intermediosExtra!
              .map(
                (e) =>
                    "${_mapaIntermedios[e.id]?.nombre ?? e.id} x${e.cantidad}",
              )
              .join(', ');
    }

    // Añadir removidos
    String removidosStr = "";
    if (pe.insumosRemovidos?.isNotEmpty ?? false) {
      removidosStr +=
          "-I: " +
          pe.insumosRemovidos!
              .map((id) => _mapaInsumos[id]?.nombre ?? id)
              .join(', ');
    }
    if (pe.intermediosRemovidos?.isNotEmpty ?? false) {
      if (removidosStr.isNotEmpty) removidosStr += " ";
      removidosStr +=
          "-M: " +
          pe.intermediosRemovidos!
              .map((id) => _mapaIntermedios[id]?.nombre ?? id)
              .join(', ');
    }

    // Construir string final
    String detalles = "";
    if (extrasStr.isNotEmpty) detalles += "{${extrasStr.trim()}}";
    if (removidosStr.isNotEmpty)
      detalles += (detalles.isNotEmpty ? " " : "") + "{${removidosStr.trim()}}";

    return "$nombreFinal ${detalles.isNotEmpty ? detalles : ''} x ${pe.cantidad}";
  }

  String _formatNombrePlatoSimple(PlatoEvento pe) {
    String nombreBase = _mapaPlatos[pe.platoId]?.nombre ?? pe.platoId;
    String nombreFinal =
        pe.nombrePersonalizado?.isNotEmpty ?? false
            ? "${pe.nombrePersonalizado} ($nombreBase)"
            : nombreBase;
    String extrasStr =
        pe.insumosExtra
            ?.map((e) => _mapaInsumos[e.id]?.nombre ?? e.id)
            .join(', ') ??
        '';
    String interExtrasStr =
        pe.intermediosExtra
            ?.map((e) => _mapaIntermedios[e.id]?.nombre ?? e.id)
            .join(', ') ??
        '';
    String insRemovidosStr =
        pe.insumosRemovidos
            ?.map((id) => _mapaInsumos[id]?.nombre ?? id)
            .join(', ') ??
        '';
    String interRemovidosStr =
        pe.intermediosRemovidos
            ?.map((id) => _mapaIntermedios[id]?.nombre ?? id)
            .join(', ') ??
        '';
    String detalles = "";
    if (extrasStr.isNotEmpty) detalles += "+Ins: $extrasStr";
    if (interExtrasStr.isNotEmpty)
      detalles += "${detalles.isNotEmpty ? '; ' : ''}+Int: $interExtrasStr";
    if (insRemovidosStr.isNotEmpty)
      detalles += "${detalles.isNotEmpty ? '; ' : ''}-Ins: $insRemovidosStr";
    if (interRemovidosStr.isNotEmpty)
      detalles += "${detalles.isNotEmpty ? '; ' : ''}-Int: $interRemovidosStr";
    return "$nombreFinal x ${pe.cantidad}${detalles.isNotEmpty ? ' ($detalles)' : ''}";
  }

  String _formatNombreIntermedio(IntermedioEvento ie) {
    final nombreBase =
        _mapaIntermedios[ie.intermedioId]?.nombre ?? ie.intermedioId;
    final unidad = _mapaIntermedios[ie.intermedioId]?.unidad ?? '';
    return "$nombreBase x ${ie.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}";
  }

  String _formatNombreInsumo(InsumoEvento ie) {
    final nombreBase = _mapaInsumos[ie.insumoId]?.nombre ?? ie.insumoId;
    final unidad = ie.unidad; // Ya viene en InsumoEvento
    return "$nombreBase x ${ie.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}";
  }
  // Podrías quitar _formatNombrePlatoSimple si solo lo usas en el PDF

  // --- Build Principal ---
  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');
    final DateFormat timeFormatter = DateFormat('hh:mm a');
    // Usar _eventoCompleto si ya cargó, sino el inicial para la AppBar
    final eventoMostrado = _eventoCompleto ?? widget.eventoInicial;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle: ${eventoMostrado.codigo}'),
        // Las acciones ahora están en el cuerpo
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _cargarDetallesCompletos,
                child: ListView(
                  // Usamos ListView para el contenido principal
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // --- Contenido de Detalles (igual que antes) ---
                    _buildHeader(eventoMostrado, dateFormatter, timeFormatter),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Información del Cliente'),
                    _buildInfoCliente(eventoMostrado),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Detalles del Evento'),
                    _buildInfoEvento(
                      eventoMostrado,
                      dateFormatter,
                      timeFormatter,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Menú y Requerimientos'),
                    if (_platosEvento.isEmpty &&
                        _intermediosEvento.isEmpty &&
                        _insumosEvento.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('No hay items definidos para este evento.'),
                      )
                    else ...[
                      if (_platosEvento.isNotEmpty) ...[
                        _buildSubSectionTitle('Platos'),
                        // Usar formato completo para la vista en pantalla
                        _buildItemList(
                          _platosEvento.map(_formatNombrePlato).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_intermediosEvento.isNotEmpty) ...[
                        _buildSubSectionTitle('Intermedios Adicionales'),
                        _buildItemList(
                          _intermediosEvento
                              .map(_formatNombreIntermedio)
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_insumosEvento.isNotEmpty) ...[
                        _buildSubSectionTitle('Insumos Adicionales'),
                        _buildItemList(
                          _insumosEvento.map(_formatNombreInsumo).toList(),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    if (eventoMostrado.comentariosLogistica != null &&
                        eventoMostrado.comentariosLogistica!.isNotEmpty) ...[
                      _buildSectionTitle('Comentarios de Logística'),
                      Text(eventoMostrado.comentariosLogistica!),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionTitle('Estado y Auditoría'),
                    _buildInfoAuditoria(
                      eventoMostrado,
                      dateFormatter,
                      timeFormatter,
                    ),
                    const Divider(
                      height: 32,
                      thickness: 1,
                    ), // Separador antes de botones
                    // --- Widget de Botones ---
                    BotonesDetalleEvento(
                      evento: eventoMostrado,
                      isLoading: _isLoading, // Pasar estado de carga
                      // Pasar las funciones definidas en _EventoDetalleScreenState como callbacks
                      onEditar: _navegarAEditar,
                      onGenerarFactura: _generarFactura,
                      onGenerarListaCompras: _generarListaCompras,
                      onExportarPdfCompleto:
                          () => _exportarPDF(
                            completo: true,
                          ), // Lambda que llama a _exportarPDF
                      onExportarPdfSimple:
                          () => _exportarPDF(
                            completo: false,
                          ), // Lambda que llama a _exportarPDF
                    ),
                    const SizedBox(height: 20), // Espacio al final
                  ],
                ),
              ),
    );
  }

  // --- Widgets de Construcción de UI ---

  Widget _buildHeader(
    Evento evento,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evento.nombreCliente,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${dateFormatter.format(evento.fecha)} a las ${timeFormatter.format(evento.fecha)}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(evento.ubicacion)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text("${evento.numeroInvitados} invitados"),
                const Spacer(),
                Chip(
                  label: Text(
                    evento.tipoEvento.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blueGrey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildInfoCliente(Evento evento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.person_outline, "Cliente", evento.nombreCliente),
        _buildInfoRow(Icons.phone_outlined, "Teléfono", evento.telefono),
        _buildInfoRow(Icons.email_outlined, "Correo", evento.correo),
      ],
    );
  }

  Widget _buildInfoEvento(
    Evento evento,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.event_note, "Tipo", evento.tipoEvento.name),
        _buildInfoRow(
          Icons.location_city_outlined,
          "Ubicación",
          evento.ubicacion,
        ),
        _buildInfoRow(
          Icons.people_alt_outlined,
          "Nº Invitados",
          evento.numeroInvitados.toString(),
        ),
        _buildInfoRow(
          Icons.access_time,
          "Fecha y Hora",
          "${dateFormatter.format(evento.fecha)} ${timeFormatter.format(evento.fecha)}",
        ),
        _buildInfoRow(
          Icons.receipt_long_outlined,
          "Facturable",
          evento.facturable ? "Sí" : "No",
        ),
      ],
    );
  }

  Widget _buildInfoAuditoria(
    Evento evento,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    final formatCompleto = DateFormat('dd/MM/yyyy hh:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.flag_outlined, "Estado Actual", evento.estado.name),
        if (evento.fechaCotizacion != null)
          _buildInfoRow(
            Icons.request_quote_outlined,
            "Fecha Cotización",
            formatCompleto.format(evento.fechaCotizacion!),
          ),
        if (evento.fechaConfirmacion != null)
          _buildInfoRow(
            Icons.check_circle_outline,
            "Fecha Confirmación",
            formatCompleto.format(evento.fechaConfirmacion!),
          ),
        _buildInfoRow(
          Icons.history_toggle_off,
          "Creado",
          formatCompleto.format(evento.fechaCreacion),
        ),
        _buildInfoRow(
          Icons.update,
          "Últ. Actualización",
          formatCompleto.format(evento.fechaActualizacion),
        ),
      ],
    );
  }

  Widget _buildItemList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Text("• $item")).toList(),
      ),
    );
  }

  void _navegarAEditar() {
    if (_eventoCompleto == null || _isLoading) return; // Seguridad adicional
    debugPrint(
      "[EventoDetalleScreen] Navegando a Editar para evento ID: ${_eventoCompleto!.id}",
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarEventoScreen(evento: _eventoCompleto!),
      ),
    ).then((_) {
      // Recargar detalles al volver por si hubo cambios
      debugPrint(
        "[EventoDetalleScreen] Volviendo de Editar, recargando detalles...",
      );
      _cargarDetallesCompletos();
    });
  }

  // --- Acción Generar Factura (Placeholder) ---
  void _generarFactura() {
    if (_isLoading || _eventoCompleto == null) return;
    debugPrint(
      "[EventoDetalleScreen] Acción: Generar Factura para evento ${_eventoCompleto!.codigo}",
    );
    // TODO: Implementar lógica de generación/navegación a factura
    _showSnackBar('Funcionalidad "Generar Factura" pendiente.', isError: false);
  }

  // --- Acción Generar Lista de Compras (Placeholder) ---
  void _generarListaCompras() {
    // 1. Verificar si los datos básicos están listos y no estamos cargando
    if (_isLoading || _eventoCompleto == null) {
      _showSnackBar(
        'Espera a que los detalles del evento terminen de cargar.',
        isError: true,
      );
      return;
    }

    // 2. Verificar si el evento tiene ID (ya validado en la acción, pero bueno tenerlo aquí)
    if (_eventoCompleto!.id == null || _eventoCompleto!.id!.isEmpty) {
      _showSnackBar('Este evento no tiene un ID válido.', isError: true);
      return;
    }

    debugPrint(
      "[EventoDetalleScreen] Llamando a la acción generarListaCompras para evento ID: ${_eventoCompleto!.id}",
    );

    // 3. Llamar a la función de acción externa
    // Le pasamos el BuildContext actual y el evento completo
    generarListaCompras(context, _eventoCompleto!);
  }

  // --- Acción Exportar PDF (Ya la teníamos, recibe el flag 'completo') ---
  Future<void> _exportarPDF({required bool completo}) async {
    if (_isLoading || _eventoCompleto == null) {
      _showSnackBar(
        "Espera a que los detalles terminen de cargar.",
        isError: true,
      );
      return;
    }
    final tipoPdf = completo ? "Completo" : "Simple";
    debugPrint(
      "[EventoDetalleScreen] Acción: Exportar PDF $tipoPdf para evento ${_eventoCompleto!.codigo}",
    );

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        // Usar MultiPage
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build:
            (pw.Context context) => [
              // build devuelve List<pw.Widget>
              _buildPdfContenido(
                // Llama al helper que construye el contenido
                context,
                _eventoCompleto!,
                dateFormat,
                _platosEvento,
                _intermediosEvento,
                _insumosEvento, // Pasa listas cargadas
                _mapaPlatos,
                _mapaIntermedios,
                _mapaInsumos, // Pasa mapas cargados
                completo: completo, // Indica qué versión construir
              ),
            ],
      ),
    );

    await _mostrarDialogoImpresion(
      context,
      pdf,
      _eventoCompleto!.codigo,
      completo ? "completo" : "simple",
    );
  }

  // --- Helper para mostrar diálogo de impresión (Ya lo teníamos) ---
  Future<void> _mostrarDialogoImpresion(
    BuildContext context,
    pw.Document pdf,
    String codigoEvento,
    String tipo,
  ) async {
    // ... (Implementación igual que antes, con try-catch y layoutPdf)
    try {
      _showSnackBar("Generando PDF $tipo...", isError: false);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'evento_${codigoEvento}_$tipo.pdf',
      );
      debugPrint("Diálogo de impresión/compartir mostrado para PDF $tipo.");
    } catch (e, st) {
      debugPrint("[ERROR] Exportando PDF $tipo: $e\n$st");
      _showSnackBar("Error al generar o mostrar el PDF: $e", isError: true);
    }
  }

  // --- Helper para construir contenido PDF ---
  pw.Widget _buildPdfContenido(
    pw.Context context,
    Evento evento,
    DateFormat dateFormat,
    List<PlatoEvento> platosEvento,
    List<IntermedioEvento> intermediosEvento,
    List<InsumoEvento> insumosEvento,
    Map<String, Plato> mapaPlatos,
    Map<String, Intermedio> mapaIntermedios,
    Map<String, Insumo> mapaInsumos, {
    required bool completo,
  }) {
    // ... (Implementación completa que genera pw.Widgets, diferenciando por 'completo')
    final pw.TextStyle boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    final pw.TextStyle sectionTitleStyle = pw.TextStyle(
      fontSize: completo ? 14 : 16,
      fontWeight: pw.FontWeight.bold,
    );
    final pw.TextStyle headerTitleStyle = pw.TextStyle(
      fontSize: completo ? 18 : 20,
      fontWeight: pw.FontWeight.bold,
    );
    final pw.EdgeInsets sectionPadding = const pw.EdgeInsets.only(
      left: 10,
      top: 5,
      bottom: 5,
    );
    final pw.EdgeInsets itemPadding = pw.EdgeInsets.only(
      left: completo ? 15 : 5,
      top: 2,
    );
    final formatAuditoria = DateFormat('dd/MM/yyyy hh:mm a');
    final formatFechaSimple = DateFormat('EEEE dd \'de\' MMMM, yyyy', 'es_ES');

    // Reutilizar las funciones de formato que ya tienes en _EventoDetalleScreenState
    String formatPlato(PlatoEvento pe) =>
        _formatNombrePlato(pe); // Asume que tienes _formatNombrePlato
    String formatPlatoSimple(PlatoEvento pe) => _formatNombrePlatoSimple(
      pe,
    ); // Asume que tienes _formatNombrePlatoSimple
    String formatIntermedio(IntermedioEvento ie) =>
        _formatNombreIntermedio(ie); // Asume que tienes _formatNombreIntermedio
    String formatInsumo(InsumoEvento ie) =>
        _formatNombreInsumo(ie); // Asume que tienes _formatNombreInsumo

    if (completo) {
      // --- ESTRUCTURA COMPLETA ---
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Detalle Evento (Interno) - Código: ${evento.codigo}",
              style: headerTitleStyle,
            ),
          ),
          pw.Divider(),
          // Cliente
          pw.Text("Cliente:", style: sectionTitleStyle),
          pw.Padding(
            padding: sectionPadding,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Nombre: ${evento.nombreCliente}"),
                pw.Text("Teléfono: ${evento.telefono}"),
                pw.Text("Correo: ${evento.correo}"),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          // Evento
          pw.Text("Evento:", style: sectionTitleStyle),
          pw.Padding(
            padding: sectionPadding,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Fecha: ${formatAuditoria.format(evento.fecha)}"),
                pw.Text("Ubicación: ${evento.ubicacion}"),
                pw.Text("Invitados: ${evento.numeroInvitados}"),
                pw.Text("Tipo: ${evento.tipoEvento.name}"),
                pw.Text("Facturable: ${evento.facturable ? 'Sí' : 'No'}"),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          // Menú
          pw.Text("Menú y Requerimientos:", style: sectionTitleStyle),
          pw.Padding(
            padding: sectionPadding,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (platosEvento.isNotEmpty) ...[
                  pw.Text("Platos:", style: boldStyle),
                  ...platosEvento.map(
                    (pe) => pw.Padding(
                      padding: itemPadding,
                      child: pw.Text("• ${formatPlato(pe)}"),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                ],
                if (intermediosEvento.isNotEmpty) ...[
                  pw.Text("Intermedios Adicionales:", style: boldStyle),
                  ...intermediosEvento.map(
                    (ie) => pw.Padding(
                      padding: itemPadding,
                      child: pw.Text("• ${formatIntermedio(ie)}"),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                ],
                if (insumosEvento.isNotEmpty) ...[
                  pw.Text("Insumos Adicionales:", style: boldStyle),
                  ...insumosEvento.map(
                    (ie) => pw.Padding(
                      padding: itemPadding,
                      child: pw.Text("• ${formatInsumo(ie)}"),
                    ),
                  ),
                ],
                if (platosEvento.isEmpty &&
                    intermediosEvento.isEmpty &&
                    insumosEvento.isEmpty)
                  pw.Text("- No hay items definidos -"),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          // Comentarios
          if (evento.comentariosLogistica != null &&
              evento.comentariosLogistica!.isNotEmpty) ...[
            pw.Text("Comentarios Logística:", style: sectionTitleStyle),
            pw.Padding(
              padding: sectionPadding,
              child: pw.Text(evento.comentariosLogistica!),
            ),
            pw.SizedBox(height: 8),
          ],
          // Auditoría
          pw.Text("Estado y Auditoría:", style: sectionTitleStyle),
          pw.Padding(
            padding: sectionPadding,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Estado: ${evento.estado.name}"),
                if (evento.fechaCotizacion != null)
                  pw.Text(
                    "F. Cotización: ${formatAuditoria.format(evento.fechaCotizacion!)}",
                  ),
                if (evento.fechaConfirmacion != null)
                  pw.Text(
                    "F. Confirmación: ${formatAuditoria.format(evento.fechaConfirmacion!)}",
                  ),
                pw.Text(
                  "F. Creación: ${formatAuditoria.format(evento.fechaCreacion)}",
                ),
                pw.Text(
                  "F. Actualización: ${formatAuditoria.format(evento.fechaActualizacion)}",
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // --- ESTRUCTURA SIMPLE ---
      final titulo =
          "${evento.tipoEvento.name.toUpperCase()} ${evento.nombreCliente.toUpperCase()}";
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text(titulo, style: headerTitleStyle)),
          pw.SizedBox(height: 15),
          pw.Text("Fecha: ${formatFechaSimple.format(evento.fecha)}"),
          pw.Text("Asistentes: ${evento.numeroInvitados}"),
          pw.Text("Dirección: ${evento.ubicacion}"),
          pw.Divider(height: 20),
          pw.Text("Menú:", style: sectionTitleStyle),
          pw.SizedBox(height: 5),
          if (platosEvento.isEmpty &&
              intermediosEvento.isEmpty &&
              insumosEvento.isEmpty)
            pw.Text("- Menú por definir -")
          else ...[
            ...platosEvento.map(
              (pe) => pw.Padding(
                padding: itemPadding,
                child: pw.Text("• ${formatPlatoSimple(pe)}"),
              ),
            ),
            ...intermediosEvento.map(
              (ie) => pw.Padding(
                padding: itemPadding,
                child: pw.Text("• ${formatIntermedio(ie)}"),
              ),
            ),
            ...insumosEvento.map(
              (ie) => pw.Padding(
                padding: itemPadding,
                child: pw.Text("• ${formatInsumo(ie)}"),
              ),
            ),
          ],
          if (evento.comentariosLogistica != null &&
              evento.comentariosLogistica!.isNotEmpty) ...[
            pw.Divider(height: 20),
            pw.Text(
              "Notas Adicionales:",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(evento.comentariosLogistica!),
          ],
        ],
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Verificar si el widget todavía está montado antes de interactuar con el context
    if (!mounted) {
      debugPrint(
        "[SnackBar WARN] Intento de mostrar SnackBar pero el widget no está montado. Mensaje: $message",
      );
      return;
    }
    // Ocultar cualquier SnackBar anterior para evitar acumulación
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // Mostrar el nuevo SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context)
                    .colorScheme
                    .error // Color de error del tema
                : Colors.green[700], // Un verde un poco más oscuro para éxito
        behavior: SnackBarBehavior.floating, // Opcional: hacerlo flotante
        duration: Duration(seconds: isError ? 4 : 2), // Más tiempo para errores
      ),
    );
  }
} // Fin _EventoDetalleScreenState
