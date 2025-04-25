import 'package:flutter/material.dart';
import 'package:golo_app/models/evento.dart';
import 'package:intl/intl.dart';
import '../widgets/lista_platos_evento.dart';
import '../widgets/lista_intermedios_evento.dart';
import '../widgets/lista_insumos_evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo.dart';
import '../widgets/modal_agregar_platos_evento.dart';
import '../widgets/modal_agregar_intermedios_evento.dart';
import '../widgets/modal_agregar_insumos_evento.dart';

class EditarEventoScreen extends StatefulWidget {
  final Evento? evento;
  const EditarEventoScreen({Key? key, this.evento}) : super(key: key);

  @override
  State<EditarEventoScreen> createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  // Estado local para las listas del evento
  List<PlatoEvento> _platosEvento = [];
  List<IntermedioEvento> _intermediosEvento = [];
  List<InsumoEvento> _insumosEvento = [];

  // Etiquetas amigables para los enums
  String _etiquetaTipoEvento(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.matrimonio:
        return 'Matrimonio';
      case TipoEvento.produccionAudiovisual:
        return 'Producción Audiovisual';
      case TipoEvento.chefEnCasa:
        return 'Chef en Casa';
      case TipoEvento.institucional:
        return 'Institucional';
    }
  }

  String _etiquetaEstadoEvento(EstadoEvento estado) {
    switch (estado) {
      case EstadoEvento.cotizado:
        return 'Cotizado';
      case EstadoEvento.confirmado:
        return 'Confirmado';
      case EstadoEvento.esCotizacion:
        return 'En Cotización';
      case EstadoEvento.enPruebaMenu:
        return 'En Prueba de Menú';
      case EstadoEvento.completado:
        return 'Completado';
      case EstadoEvento.cancelado:
        return 'Cancelado';
    }
  }

  late TextEditingController _nombreClienteController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  late TextEditingController _ubicacionController;
  late TextEditingController _comentariosLogisticaController;
  late TextEditingController _numeroInvitadosController;
  late DateTime _fecha;
  late TipoEvento _tipoEvento;
  late EstadoEvento _estadoEvento;
  late bool _facturable;

  @override
  void initState() {
    final e = widget.evento;
    _nombreClienteController = TextEditingController(
      text: e?.nombreCliente ?? '',
    );
    _telefonoController = TextEditingController(text: e?.telefono ?? '');
    _correoController = TextEditingController(text: e?.correo ?? '');
    _ubicacionController = TextEditingController(text: e?.ubicacion ?? '');
    _comentariosLogisticaController = TextEditingController(
      text: e?.comentariosLogistica ?? '',
    );
    _numeroInvitadosController = TextEditingController(
      text: e?.numeroInvitados.toString() ?? '',
    );
    _fecha = e?.fecha ?? DateTime.now();
    _tipoEvento = e?.tipoEvento ?? TipoEvento.institucional;
    _estadoEvento = e?.estado ?? EstadoEvento.cotizado;
    _facturable = e?.facturable ?? false;
    super.initState();
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ubicacionController.dispose();
    _comentariosLogisticaController.dispose();
    _numeroInvitadosController.dispose();
    super.dispose();
  }

  void _guardarEvento() {
    // TODO: Implementar guardado
    // Si widget.evento == null => crear, si no, actualizar
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.evento != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Evento' : 'Nuevo Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esEdicion)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text(
                      'Código:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.evento!.codigo),
                  ],
                ),
              ),
            TextField(
              controller: _nombreClienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
              ),
            ),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: 'Ubicación'),
            ),
            TextField(
              controller: _numeroInvitadosController,
              decoration: const InputDecoration(
                labelText: 'Número de invitados',
              ),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Fecha del evento:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('yyyy-MM-dd').format(_fecha)),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _fecha = picked);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text(
                      'Facturable',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _facturable,
                      onChanged: (v) => setState(() => _facturable = v),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoEvento>(
                    value: TipoEvento.values.contains(_tipoEvento) ? _tipoEvento : null,
                    items:
                        TipoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_etiquetaTipoEvento(e)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _tipoEvento = v!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<EstadoEvento>(
                    value: EstadoEvento.values.contains(_estadoEvento) ? _estadoEvento : null,
                    items:
                        EstadoEvento.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_etiquetaEstadoEvento(e)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _estadoEvento = v!),
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
              ],
            ),

            TextField(
              controller: _comentariosLogisticaController,
              decoration: const InputDecoration(
                labelText: 'Comentarios logística',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platos del evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: () async {
                    // Mostrar modal para agregar platos
                    final seleccionados = await showDialog<List<Plato>>(
                      context: context,
                      builder: (ctx) => ModalAgregarPlatosEvento(
                        platosIniciales: [], // TODO: pasar los platos actuales del evento
                        onGuardar: (nuevos) => Navigator.of(ctx).pop(nuevos),
                      ),
                    );
                    if (seleccionados != null) {
                      setState(() {
                        // TODO: convertir Plato a PlatoEvento y actualizar _platosEvento
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(40, 36)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaPlatosEvento(
                platosEvento: _platosEvento,
                onEditar: (pe) async {
                  final nuevos = List<PlatoEvento>.from(_platosEvento);
                  final idx = nuevos.indexWhere((x) => x.platoId == pe.platoId);
                  if (idx == -1) return;
                  // Aquí puedes abrir un modal para editar la cantidad, por ahora solo ejemplo:
                  // final editado = await showDialog<PlatoEvento>(...);
                  // if (editado != null) setState(() => _platosEvento[idx] = editado);
                },
                onEliminar: (pe) {
                  setState(() {
                    _platosEvento.removeWhere((x) => x.platoId == pe.platoId);
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intermedios del evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: () async {
                    final seleccionados = await showDialog<List<Intermedio>>(
                      context: context,
                      builder: (ctx) => ModalAgregarIntermediosEvento(
                        intermediosIniciales: [], // TODO: pasar los intermedios actuales del evento
                        onGuardar: (nuevos) => Navigator.of(ctx).pop(nuevos),
                      ),
                    );
                    if (seleccionados != null) {
                      setState(() {
                        // TODO: convertir Intermedio a IntermedioEvento y actualizar _intermediosEvento
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(40, 36)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaIntermediosEvento(
                intermediosEvento: _intermediosEvento,
                onEditar: (ie) async {
                  final nuevos = List<IntermedioEvento>.from(_intermediosEvento);
                  final idx = nuevos.indexWhere((x) => x.intermedioId == ie.intermedioId);
                  if (idx == -1) return;
                  // Aquí puedes abrir un modal para editar la cantidad, por ahora solo ejemplo:
                  // final editado = await showDialog<IntermedioEvento>(...);
                  // if (editado != null) setState(() => _intermediosEvento[idx] = editado);
                },
                onEliminar: (ie) {
                  setState(() {
                    _intermediosEvento.removeWhere((x) => x.intermedioId == ie.intermedioId);
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Insumos del evento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: () async {
                    final seleccionados = await showDialog<List<Insumo>>(
                      context: context,
                      builder: (ctx) => ModalAgregarInsumosEvento(
                        insumosIniciales: [], // TODO: pasar los insumos actuales del evento
                        onGuardar: (nuevos) => Navigator.of(ctx).pop(nuevos),
                      ),
                    );
                    if (seleccionados != null) {
                      setState(() {
                        // TODO: convertir Insumo a InsumoEvento y actualizar _insumosEvento
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(40, 36)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaInsumosEvento(
                insumosEvento: _insumosEvento,
                onEditar: (ie) async {
                  final nuevos = List<InsumoEvento>.from(_insumosEvento);
                  final idx = nuevos.indexWhere((x) => x.insumoId == ie.insumoId);
                  if (idx == -1) return;
                  // Aquí puedes abrir un modal para editar la cantidad, por ahora solo ejemplo:
                  // final editado = await showDialog<InsumoEvento>(...);
                  // if (editado != null) setState(() => _insumosEvento[idx] = editado);
                },
                onEliminar: (ie) {
                  setState(() {
                    _insumosEvento.removeWhere((x) => x.insumoId == ie.insumoId);
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarEvento,
              child: Text(esEdicion ? 'Guardar cambios' : 'Crear evento'),
            ),
          ],
        ),
      ),
    );
  }
}
