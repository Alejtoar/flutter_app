import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo_utilizado.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/lista_insumos_utilizados.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/modal_agregar_insumos.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/common/selector_categorias.dart';
import 'package:golo_app/features/common/selector_unidades.dart';

class IntermedioEditScreen extends StatefulWidget {
  final Intermedio? intermedio;
  const IntermedioEditScreen({Key? key, this.intermedio}) : super(key: key);

  @override
  State<IntermedioEditScreen> createState() => _IntermedioEditScreenState();
}

class _IntermedioEditScreenState extends State<IntermedioEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _codigoGenerado;
  late TextEditingController _nombreController;
  late TextEditingController _cantidadController;
  late TextEditingController _reduccionController;
  late TextEditingController _recetaController;
  late TextEditingController _tiempoController;
  String? _unidadSeleccionada;
  List<String> _categorias = [];
  List<InsumoUtilizado> _insumosUtilizados = [];

  @override
  void initState() {
    super.initState();
    final i = widget.intermedio;
    _nombreController = TextEditingController(text: i?.nombre ?? '');
    // Asegurarse de que los insumos estén cargados
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final insumoCtrl = Provider.of<InsumoController>(context, listen: false);
      if (insumoCtrl.insumos.isEmpty) {
        await insumoCtrl.cargarInsumos();
      }
    });
    if (i == null) {
      // Generar código automáticamente al crear
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final intermedioCtrl = Provider.of<IntermedioController>(context, listen: false);
        final nuevoCodigo = await intermedioCtrl.generarNuevoCodigo();
        setState(() {
          _codigoGenerado = nuevoCodigo;
        });
      });
    } else {
      _codigoGenerado = i.codigo;
    }
    _cantidadController = TextEditingController(text: i?.cantidadEstandar.toString() ?? '');
    _reduccionController = TextEditingController(text: i?.reduccionPorcentaje.toString() ?? '');
    _recetaController = TextEditingController(text: i?.receta ?? '');
    _tiempoController = TextEditingController(text: i?.tiempoPreparacionMinutos.toString() ?? '');
    _categorias = List.from(i?.categorias ?? []);
    _unidadSeleccionada = i?.unidad ?? null;
    // Si es edición, cargar insumos utilizados desde el controller
    if (i != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctrl = Provider.of<IntermedioController>(context, listen: false);
        await ctrl.cargarInsumosUtilizadosPorIntermedio(i.id!);
        setState(() {
          _insumosUtilizados = List.from(ctrl.insumosUtilizados);
        });
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _reduccionController.dispose();
    _recetaController.dispose();
    _tiempoController.dispose();
    super.dispose();
  }

  void _abrirModalInsumos() async {
    await showDialog(
      context: context,
      builder: (ctx) => ModalAgregarInsumos(
        insumosIniciales: _insumosUtilizados,
        onGuardar: (nuevos) {
          setState(() => _insumosUtilizados = List.from(nuevos));
        },
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos una categoría')),
      );
      return;
    }
    final intermedio = Intermedio(
      id: widget.intermedio?.id,
      codigo: _codigoGenerado,
      nombre: _nombreController.text.trim(),
      categorias: _categorias,
      unidad: _unidadSeleccionada ?? 'unidad',
      cantidadEstandar: double.tryParse(_cantidadController.text) ?? 0,
      reduccionPorcentaje: double.tryParse(_reduccionController.text) ?? 0,
      receta: _recetaController.text.trim(),
      tiempoPreparacionMinutos: int.tryParse(_tiempoController.text) ?? 0,
      fechaCreacion: widget.intermedio?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      activo: true,
    );
    final ctrl = Provider.of<IntermedioController>(context, listen: false);
    if (widget.intermedio == null) {
      await ctrl.crearIntermedioConInsumos(intermedio, _insumosUtilizados);
    } else {
      await ctrl.actualizarIntermedioConInsumos(intermedio, _insumosUtilizados);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.intermedio == null ? 'Crear Intermedio' : 'Editar Intermedio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (widget.intermedio != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Código'),
                    child: Text(widget.intermedio!.codigo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectorCategorias(
                  categorias: Intermedio.categoriasDisponibles.keys.toList(),
                  seleccionadas: _categorias,
                  onChanged: (cats) => setState(() => _categorias = cats),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(labelText: 'Cantidad estándar'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : 'Debe ser un número > 0',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: SelectorUnidades(
                      unidadSeleccionada: _unidadSeleccionada,
                      onChanged: (val) => setState(() => _unidadSeleccionada = val),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _reduccionController,
                decoration: const InputDecoration(labelText: 'Reducción (%)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _recetaController,
                decoration: const InputDecoration(labelText: 'Receta (opcional)'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _tiempoController,
                decoration: const InputDecoration(labelText: 'Tiempo preparación (min)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Insumos utilizados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _abrirModalInsumos,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar insumos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListaInsumosUtilizados(
                  insumosUtilizados: _insumosUtilizados,
                  onEditar: (iu) {},
                  onEliminar: (iu) {
                    setState(() {
                      _insumosUtilizados.removeWhere((x) => x.insumoId == iu.insumoId);
                    });
                  },

                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardar,
                child: Text(widget.intermedio == null ? 'Crear' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
