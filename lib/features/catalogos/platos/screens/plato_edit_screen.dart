import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/insumo_requerido.dart';
import 'package:golo_app/models/intermedio_requerido.dart';
import 'package:golo_app/features/catalogos/platos/widgets/lista_insumos_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/lista_intermedios_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_insumos_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_agregar_intermedios_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_insumo_requerido.dart';
import 'package:golo_app/features/catalogos/platos/widgets/modal_editar_cantidad_intermedio_requerido.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/common/selector_categorias.dart';

class PlatoEditScreen extends StatefulWidget {
  final Plato? plato;
  const PlatoEditScreen({Key? key, this.plato}) : super(key: key);

  @override
  State<PlatoEditScreen> createState() => _PlatoEditScreenState();
}

class _PlatoEditScreenState extends State<PlatoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _codigoGenerado;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _recetaController;
  late TextEditingController _porcionesController;
  List<String> _categorias = [];
  List<InsumoRequerido> _insumos = [];
  List<IntermedioRequerido> _intermedios = [];

  Future<void> _editarInsumoRequerido(InsumoRequerido iu) async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) await insumoCtrl.cargarInsumos();
    final idx = insumoCtrl.insumos.indexWhere((x) => x.id == iu.insumoId);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insumo no encontrado en catálogo actual.'),
        ),
      );
      return;
    }
    final insumo = insumoCtrl.insumos[idx];
    final editado = await showDialog<InsumoRequerido>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumoRequerido(
            insumoRequerido: iu,
            insumo: insumo,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(iu.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _insumos.indexWhere((x) => x.insumoId == iu.insumoId);
        if (idxLocal != -1) _insumos[idxLocal] = editado;
      });
    }
  }

  Future<void> _editarIntermedioRequerido(IntermedioRequerido ir) async {
    final intermedioCtrl = Provider.of<IntermedioController>(
      context,
      listen: false,
    );
    if (intermedioCtrl.intermedios.isEmpty)
      await intermedioCtrl.cargarIntermedios();
    final idx = intermedioCtrl.intermedios.indexWhere(
      (x) => x.id == ir.intermedioId,
    );
    Intermedio intermedio;
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intermedio no encontrado en catálogo actual.'),
        ),
      );
      intermedio = Intermedio(
        id: ir.intermedioId,
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
    final editado = await showDialog<IntermedioRequerido>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadIntermedioRequerido(
            intermedioRequerido: ir,
            intermedio: intermedio,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(ir.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );
    if (editado != null) {
      setState(() {
        final idxLocal = _intermedios.indexWhere(
          (x) => x.intermedioId == ir.intermedioId,
        );
        if (idxLocal != -1) _intermedios[idxLocal] = editado;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.plato;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _recetaController = TextEditingController(text: p?.receta ?? '');
    _porcionesController = TextEditingController(
      text: (p?.porcionesMinimas ?? 1).toString(),
    );
    _categorias = List.from(p?.categorias ?? []);

    // Asegura la carga de catálogos globales de insumos e intermedios
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      final intermedioCtrl = Provider.of<IntermedioController>(
        context,
        listen: false,
      );
      if (insumoCtrl.insumos.isEmpty) {
        await insumoCtrl.cargarInsumos();
      }
      if (intermedioCtrl.intermedios.isEmpty) {
        await intermedioCtrl.cargarIntermedios();
      }
    });

    if (p == null) {
      // Generar código automáticamente al crear
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctrl = Provider.of<PlatoController>(context, listen: false);
        final codigo = await ctrl.generarNuevoCodigo();
        if (!mounted) return;
        setState(() => _codigoGenerado = codigo);
      });
    } else {
      _codigoGenerado = p.codigo;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final platoCtrl = Provider.of<PlatoController>(context, listen: false);
        await platoCtrl.cargarRelacionesPorPlato(p.id!);
        setState(() {
          _insumos = List.from(platoCtrl.insumosRequeridos);
          _intermedios = List.from(platoCtrl.intermediosRequeridos);
        });
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _recetaController.dispose();
    _porcionesController.dispose();
    super.dispose();
  }

  void _abrirModalInsumos() async {
    final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
    if (insumoCtrl.insumos.isEmpty) {
      await insumoCtrl.cargarInsumos();
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumosRequeridos(
            insumosIniciales: _insumos,
            onGuardar: (nuevos) {
              setState(() => _insumos = List.from(nuevos));
            },
          ),
    );
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
          (ctx) => ModalAgregarIntermediosRequeridos(
            intermediosIniciales: _intermedios,
            onGuardar: (nuevos) {
              setState(() => _intermedios = List.from(nuevos));
            },
          ),
    );
  }

  void _guardar() async {
    debugPrint('===> [_guardar] Iniciando guardado de plato');
    if (!_formKey.currentState!.validate()) {
      debugPrint('===> [_guardar] Formulario inválido');
      return;
    }
    if (_categorias.isEmpty) {
      debugPrint('===> [_guardar] No hay categorías seleccionadas');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos una categoría'),
        ),
      );
      return;
    }
    if (!mounted) {
      debugPrint('===> [_guardar] Widget no montado, cancelando guardado');
      return;
    }
    debugPrint('===> [_guardar] Leyendo valores de controladores');
    final plato = Plato(
      id: widget.plato?.id,
      codigo: _codigoGenerado ?? '',
      nombre: _nombreController.text.trim(),
      categorias: _categorias,
      porcionesMinimas: int.tryParse(_porcionesController.text) ?? 1,
      receta: _recetaController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      fechaCreacion: widget.plato?.fechaCreacion,
      fechaActualizacion: DateTime.now(),
      activo: widget.plato?.activo ?? true,
    );
    debugPrint(
      '===> [_guardar] Plato construido: id=${plato.id}, nombre=${plato.nombre}, categorias=${plato.categorias}, receta=${plato.receta}, descripcion=${plato.descripcion}',
    );
    final controller = Provider.of<PlatoController>(context, listen: false);
    bool exito;
    if (widget.plato == null) {
      debugPrint('===> [_guardar] Creando plato nuevo');
      final creado = await controller.crearPlatoConRelaciones(
        plato,
        _intermedios,
        _insumos,
      );
      exito = creado != null;
    } else {
      debugPrint('===> [_guardar] Actualizando plato existente');
      exito = await controller.actualizarPlatoConRelaciones(
        plato,
        _intermedios,
        _insumos,
      );
    }
    if (!mounted) {
      debugPrint(
        '===> [_guardar] Widget desmontado después de guardar, no navego ni muestro SnackBar',
      );
      return;
    }
    if (exito) {
      debugPrint('===> [_guardar] Guardado exitoso, navegando hacia atrás');
      Navigator.of(context).pop();
    } else {
      debugPrint('===> [_guardar] Error al guardar: ${controller.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Error al guardar el plato'),
        ),
      );
    }
    debugPrint('===> [_guardar] Fin de _guardar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plato == null ? 'Crear Plato' : 'Editar Plato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_codigoGenerado != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Código'),
                    child: Text(
                      _codigoGenerado!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _porcionesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Porciones estándar',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final n = int.tryParse(v);
                  if (n == null || n < 1)
                    return 'Debe ser un número entero mayor a 0';
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectorCategorias(
                  categorias: Plato.categoriasDisponibles.keys.toList(),
                  seleccionadas: _categorias,
                  onChanged: (cats) => setState(() => _categorias = cats),
                ),
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _recetaController,
                decoration: const InputDecoration(
                  labelText: 'Receta (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Insumos requeridos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _abrirModalInsumos,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar insumos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListaInsumosRequeridos(
                  insumos: _insumos,
                  onEditar: _editarInsumoRequerido,
                  onEliminar: (iu) {
                    setState(() {
                      _insumos.removeWhere((x) => x.insumoId == iu.insumoId);
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Intermedios requeridos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _abrirModalIntermedios,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar intermedios'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListaIntermediosRequeridos(
                  intermedios: _intermedios,
                  onEditar: _editarIntermedioRequerido,
                  onEliminar: (ir) {
                    setState(() {
                      _intermedios.removeWhere(
                        (x) => x.intermedioId == ir.intermedioId,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardar,
                child: Text(widget.plato == null ? 'Crear' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
