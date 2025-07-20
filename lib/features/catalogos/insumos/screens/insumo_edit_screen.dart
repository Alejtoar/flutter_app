//insumo_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'package:golo_app/features/common/widgets/selector_unidades.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/widgets/selector_proveedores.dart';
import 'package:golo_app/models/proveedor.dart';
import 'package:collection/collection.dart';

class AddEditInsumoScreen extends StatefulWidget {
  final Insumo? insumo;

  const AddEditInsumoScreen({super.key, this.insumo});

  @override
  AddEditInsumoScreenState createState() => AddEditInsumoScreenState();
}

class AddEditInsumoScreenState extends State<AddEditInsumoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late List<String> _selectedCategories = [];
  Proveedor? _selectedProveedor;
  String? _unidadSeleccionada;
  String? _codigoGenerado;
  bool _isSaving = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final i = widget.insumo;
    // ... (inicializar controladores de texto y categorías) ...
    _nombreController = TextEditingController(text: i?.nombre ?? '');
    _precioController = TextEditingController(
      text: i?.precioUnitario.toString() ?? '',
    );
    _selectedCategories = List.from(i?.categorias ?? []);
    _unidadSeleccionada = i?.unidad;

    // 2. Usar el patrón de carga/generación de código
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cargar proveedores es necesario para el selector
      context.read<InsumoController>().cargarProveedores();
      _loadInitialDataAndCode();
    });
  }

  Future<void> _loadInitialDataAndCode() async {
    final i = widget.insumo;
    if (i == null) {
      // Modo Creación: Generar Código
      if (!mounted) return;
      setState(() => _isGeneratingCode = true);
      final controller = context.read<InsumoController>();
      try {
        final codigo = await controller.generarNuevoCodigo();
        if (mounted) setState(() => _codigoGenerado = codigo);
      } catch (e) {
        if (mounted) {
          showAppSnackBar(
            context,
            'Error al generar código: $e',
            isError: true,
          );
        }
        if (mounted) setState(() => _codigoGenerado = "I-ERR");
      } finally {
        if (mounted) setState(() => _isGeneratingCode = false);
      }
    } else {
      // Modo Edición
      if (mounted) {
        setState(() {
          _codigoGenerado = i.codigo;
          // Seleccionar proveedor existente
          final controller = context.read<InsumoController>();
          _selectedProveedor = controller.proveedores.firstWhereOrNull(
            (p) => p.id == i.proveedorId,
          );
        });
      }
    }
  }

  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      showAppSnackBar(
        context,
        'Selecciona al menos una categoría',
        isError: true,
      );
      return;
    }
    if (widget.insumo == null &&
        (_codigoGenerado == null ||
            _codigoGenerado!.isEmpty ||
            _codigoGenerado == 'I-ERR')) {
      showAppSnackBar(
        context,
        'No se pudo generar un código válido. Inténtalo de nuevo.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final controller = context.read<InsumoController>();
    try {
      String codigo = widget.insumo?.codigo ?? '';
      if (widget.insumo == null) {
        // Generar código único automáticamente
        codigo = await controller.generarNuevoCodigo();
      }
      final insumo = Insumo.crear(
        id: widget.insumo?.id,
        codigo: codigo,
        nombre: _nombreController.text,
        categorias: _selectedCategories,
        unidad: _unidadSeleccionada ?? 'unidad',
        precioUnitario: double.parse(_precioController.text),
        proveedorId: _selectedProveedor?.id ?? '',
        fechaCreacion: widget.insumo?.fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
      if (widget.insumo == null) {
        await controller.crearInsumo(insumo);
      } else {
        await controller.actualizarInsumo(insumo);
      }
      if (mounted) {
        showAppSnackBar(
          context,
          'Insumo ${widget.insumo == null ? 'creado' : 'actualizado'} correctamente.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.insumo == null ? 'Nuevo Insumo' : 'Editar Insumo'),
        actions: [
          // 2. Añadir el botón de guardar en la AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                _isSaving
                    ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Guardar',
                      onPressed: _guardarInsumo,
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Insumo',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child:
                      _isGeneratingCode && widget.insumo == null
                          // Muestra el indicador de carga si está generando código para un nuevo insumo
                          ? const SizedBox(
                            height: 20,
                            child: Row(
                              children: [
                                Text("Generando... "),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ),
                          )
                          // Muestra el código generado/existente o un mensaje de error
                          : Text(
                            _codigoGenerado ??
                                (widget.insumo != null
                                    ? ''
                                    : 'Error al generar'),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              // Muestra el texto en rojo si el código es el de error
                              color:
                                  _codigoGenerado == 'I-ERR'
                                      ? Colors.red
                                      : null,
                            ),
                          ),
                ),
              ),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Requerido';
                        if (double.tryParse(value) == null) {
                          return 'Número inválido';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: SelectorUnidades(
                      unidadSeleccionada: _unidadSeleccionada,
                      onChanged:
                          (unidad) =>
                              setState(() => _unidadSeleccionada = unidad),
                      label: 'Unidad',
                    ),
                  ),
                ],
              ),
              // Selector de categorías
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: SelectorCategorias(
                  seleccionadas: _selectedCategories,

                  onChanged:
                      (categorias) =>
                          setState(() => _selectedCategories = categorias),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: SelectorProveedores(
                  proveedores: context.read<InsumoController>().proveedores,
                  proveedorSeleccionado: _selectedProveedor,
                  onChanged: (Proveedor? proveedor) {
                    setState(() {
                      _selectedProveedor = proveedor;
                    });
                  },
                  label: 'Proveedor',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}
