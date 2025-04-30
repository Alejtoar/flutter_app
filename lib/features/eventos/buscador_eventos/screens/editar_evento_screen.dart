import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_insumo_evento.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_intermedio_evento.dart';
import 'package:golo_app/features/eventos/buscador_eventos/widgets/modal_editar_cantidad_plato_evento.dart';

import 'package:golo_app/models/intermedio.dart';

import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/evento.dart';
import 'package:intl/intl.dart';
import '../widgets/lista_platos_evento.dart';
import '../widgets/lista_intermedios_evento.dart';
import '../widgets/lista_insumos_evento.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:provider/provider.dart';
import '../controllers/buscador_eventos_controller.dart';
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

  Future<void> _abrirModalPlatos() async {
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    if (platoCtrl.platos.isEmpty) {
      await platoCtrl.cargarPlatos();
    }
    final seleccionados = await showDialog<List<Plato>>(
      context: context,
      builder:
          (ctx) => ModalAgregarPlatosEvento(
            platosIniciales: _platosEvento,
            onGuardar: (nuevos) {
              setState(() => _platosEvento = List.from(nuevos));
            },
          ),
    );
    if (seleccionados != null) {
      setState(() {
        final nuevos = List<PlatoEvento>.from(_platosEvento);
        final nuevosPlatos =
            seleccionados.map((plato) {
              final existente = nuevos.firstWhere(
                (pe) => pe.platoId == plato.id,
                orElse:
                    () => PlatoEvento(
                      eventoId: widget.evento?.id ?? '',
                      platoId: plato.id!,
                      cantidad: 1,
                    ),
              );
              return existente;
            }).toList();
        _platosEvento = nuevosPlatos;
      });
    }
  }

  Future<void> _editarPlatoRequerido(PlatoEvento pe) async {
    final platoCtrl = Provider.of<PlatoController>(context, listen: false);
    if (platoCtrl.platos.isEmpty) await platoCtrl.cargarPlatos();
    final idx = platoCtrl.platos.indexWhere((x) => x.id == pe.platoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plato no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final plato = platoCtrl.platos[idx];
    final editado = await showDialog<PlatoEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadPlatoEvento(
            platoEvento: pe,
            plato: plato,
            onGuardar: (nuevaCantidad) {
              Navigator.of(
                ctx,
              ).pop(pe.copyWith(cantidad: nuevaCantidad.toInt()));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _platosEvento.indexWhere(
          (x) => x.platoId == pe.platoId,
        );
        if (idxLocal != -1) _platosEvento[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioEvento ie) async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty)
      await intermedioCtrl.cargarIntermedios();
    final idx = intermedioCtrl.intermedios.indexWhere(
      (x) => x.id == ie.intermedioId,
    );
    Intermedio intermedio;
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intermedio no encontrado en catálogo actual.'),
        ),
      );
      intermedio = Intermedio(
        id: ie.intermedioId,
        codigo: '',
        nombre: 'Intermedio desconocido',
        categorias: [],
        unidad: '',
        cantidadEstandar: 0,
        reduccionPorcentaje: 0,
        receta: '',
        tiempoPreparacionMinutos: 0,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        activo: true,
      );
    } else {
      intermedio = intermedioCtrl.intermedios[idx];
    }
    final editado = await showDialog<IntermedioEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioEvento(
            intermedioEvento: ie,
            intermedio: intermedio,
            onGuardar: (nuevaCantidad) {
              Navigator.of(
                ctx,
              ).pop(ie.copyWith(cantidad: nuevaCantidad.toInt()));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _intermediosEvento.indexWhere(
          (x) => x.intermedioId == ie.intermedioId,
        );
        if (idxLocal != -1) _intermediosEvento[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarInsumoRequerido(InsumoEvento ie) async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) await insumoCtrl.cargarInsumos();
    final idx = insumoCtrl.insumos.indexWhere((x) => x.id == ie.insumoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insumo no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final insumo = insumoCtrl.insumos[idx];
    final editado = await showDialog<InsumoEvento>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoEvento(
            insumoEvento: ie,
            insumo: insumo,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(ie.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _insumosEvento.indexWhere(
          (x) => x.insumoId == ie.insumoId,
        );
        if (idxLocal != -1) _insumosEvento[idxLocal] = editado;
      });
    }
  }

  void _eliminarPlatoRequerido(PlatoEvento pe) {
    setState(() {
      _platosEvento.removeWhere((x) => x.platoId == pe.platoId);
    });
  }

  void _eliminarIntermedioRequerido(IntermedioEvento ie) {
    setState(() {
      _intermediosEvento.removeWhere((x) => x.intermedioId == ie.intermedioId);
    });
  }

  void _abrirModalIntermedios() async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty) {
      await intermedioCtrl.cargarIntermedios();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarIntermediosEvento(
            intermediosIniciales: _intermediosEvento,
            onGuardar: (nuevos) {
              setState(() => _intermediosEvento = List.from(nuevos));
            },
          ),
    );
  }

  void _abrirModalInsumos() async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      await insumoCtrl.cargarInsumos();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosEvento(
            insumosIniciales: _insumosEvento,
            onGuardar: (nuevos) {
              setState(() => _insumosEvento = List.from(nuevos));
            },
          ),
    );
  }

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

    // Si es edición, cargar relaciones del evento desde el controller
    if (e != null && e.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = Provider.of<BuscadorEventosController>(
          context,
          listen: false,
        );
        await controller.cargarRelacionesPorEvento(e.id!);
        setState(() {
          _platosEvento = List.from(controller.platosEvento);
          _intermediosEvento = List.from(controller.intermediosEvento);
          _insumosEvento = List.from(controller.insumosEvento);
        });
      });
    }
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

  void _guardarEvento() async {
    debugPrint('===> [_guardarEvento] Iniciando guardado de evento');
    
    // Validar campos requeridos
    if (_nombreClienteController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Nombre del cliente es requerido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del cliente es requerido'),
        ),
      );
      return;
    }
    
    if (_telefonoController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Teléfono es requerido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono es requerido'),
        ),
      );
      return;
    }
    
    if (_correoController.text.trim().isEmpty) {
      debugPrint('===> [_guardarEvento] Correo es requerido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El correo es requerido'),
        ),
      );
      return;
    }
    
    if (!mounted) {
      debugPrint('===> [_guardarEvento] Widget no montado, cancelando guardado');
      return;
    }
    
    debugPrint('===> [_guardarEvento] Construyendo objeto Evento');
    final evento = Evento(
      id: widget.evento?.id,
      codigo: widget.evento?.codigo ?? '',
      nombreCliente: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      ubicacion: _ubicacionController.text.trim(),
      numeroInvitados: int.tryParse(_numeroInvitadosController.text) ?? 0,
      tipoEvento: _tipoEvento,
      estado: _estadoEvento,
      fecha: _fecha,
      fechaCotizacion: widget.evento?.fechaCotizacion,
      fechaConfirmacion: widget.evento?.fechaConfirmacion,
      fechaCreacion: widget.evento?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      comentariosLogistica: _comentariosLogisticaController.text.trim(),
      facturable: _facturable,
    );
    
    debugPrint(
      '===> [_guardarEvento] Evento construido: id=${evento.id}, nombreCliente=${evento.nombreCliente}, fecha=${evento.fecha}',
    );
    
    final controller = Provider.of<BuscadorEventosController>(context, listen: false);
    bool exito;
    
    if (widget.evento == null) {
      debugPrint('===> [_guardarEvento] Creando evento nuevo');
      final creado = await controller.crearEventoConRelaciones(
        evento,
        _platosEvento,
        _insumosEvento,
        _intermediosEvento,
      );
      exito = creado != null;
    } else {
      debugPrint('===> [_guardarEvento] Actualizando evento existente');
      exito = await controller.actualizarEventoConRelaciones(
        evento,
        _platosEvento,
        _insumosEvento,
        _intermediosEvento,
      );
    }
    
    if (!mounted) {
      debugPrint(
        '===> [_guardarEvento] Widget desmontado después de guardar, no navego ni muestro SnackBar',
      );
      return;
    }
    
    if (exito) {
      debugPrint('===> [_guardarEvento] Guardado exitoso, navegando hacia atrás');
      Navigator.of(context).pop();
    } else {
      debugPrint('===> [_guardarEvento] Error al guardar: ${controller.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al guardar el evento'),
        ),
      );
    }
    
    debugPrint('===> [_guardarEvento] Fin de _guardarEvento');
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
                    value:
                        TipoEvento.values.contains(_tipoEvento)
                            ? _tipoEvento
                            : null,
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
                    value:
                        EstadoEvento.values.contains(_estadoEvento)
                            ? _estadoEvento
                            : null,
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
                const Text(
                  'Platos del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _abrirModalPlatos,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaPlatosEvento(
                platosEvento: _platosEvento,
                onEditar: _editarPlatoRequerido,
                onEliminar: _eliminarPlatoRequerido,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Intermedios del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _abrirModalIntermedios,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaIntermediosEvento(
                intermediosEvento: _intermediosEvento,
                onEditar: _editarIntermedioRequerido,
                onEliminar: _eliminarIntermedioRequerido,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Insumos del evento',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Insumos'),
                  onPressed: _abrirModalInsumos,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(40, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListaInsumosEvento(
                insumosEvento: _insumosEvento,
                onEditar: _editarInsumoRequerido,
                onEliminar: (ie) {
                  setState(() {
                    _insumosEvento.removeWhere(
                      (x) => x.insumoId == ie.insumoId,
                    );
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
