import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import 'package:golo_app/features/common/utils/snackbar_helper.dart';
import 'package:golo_app/features/common/widgets/lista_componentes_requeridos.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/insumo_utilizado.dart';

import 'package:golo_app/features/catalogos/intermedios/widgets/modal_agregar_insumos.dart';
import 'package:golo_app/features/catalogos/intermedios/widgets/modal_editar_cantidad_insumo.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import 'package:golo_app/features/common/widgets/selector_categorias.dart';
import 'package:golo_app/features/common/widgets/selector_unidades.dart';

class IntermedioEditScreen extends StatefulWidget {
  final Intermedio? intermedio;
  const IntermedioEditScreen({Key? key, this.intermedio}) : super(key: key);

  @override
  // Corregido: La clase de estado ahora es pública
  IntermedioEditScreenState createState() => IntermedioEditScreenState();
}

class IntermedioEditScreenState extends State<IntermedioEditScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _cantidadController;
  late TextEditingController _reduccionController;
  late TextEditingController _recetaController;
  late TextEditingController _tiempoController;
  // Estado
  String? _codigoGenerado;
  String? _unidadSeleccionada;
  List<String> _categorias = [];
  List<InsumoUtilizado> _insumosUtilizados = [];
  // Banderas de estado
  bool _isLoadingRelations = false;
  bool _isSaving = false;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    final i = widget.intermedio;

    _nombreController = TextEditingController(text: i?.nombre ?? '');
    _cantidadController = TextEditingController(
      text: (i?.cantidadEstandar ?? 1).toString(),
    );
    _reduccionController = TextEditingController(
      text: (i?.reduccionPorcentaje ?? 0).toString(),
    );
    _recetaController = TextEditingController(text: i?.receta ?? '');
    _tiempoController = TextEditingController(
      text: (i?.tiempoPreparacionMinutos ?? 0).toString(),
    );
    _categorias = List.from(i?.categorias ?? []);
    _unidadSeleccionada = i?.unidad;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialDataAndCode();
    });
  }

  Future<void> _loadInitialDataAndCode() async {
    if (!mounted) return;
    debugPrint("[IntermedioEditScreen] Iniciando carga...");
    // Precargar catálogo de Insumos, necesario para las listas y modales
    final insumoCtrl = context.read<InsumoController>();
    if (insumoCtrl.insumos.isEmpty) await insumoCtrl.cargarInsumos();

    final i = widget.intermedio;
    if (i == null) {
      // Modo Creación: Generar Código
      setState(() => _isGeneratingCode = true);
      final controller = context.read<IntermedioController>();
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
      } finally {
        if (mounted) setState(() => _isGeneratingCode = false);
      }
    } else {
      // Modo Edición: Usar código existente y Cargar Relaciones
      _codigoGenerado = i.codigo;
      setState(() => _isLoadingRelations = true);
      final controller = context.read<IntermedioController>();
      try {
        await controller.cargarInsumosUtilizadosPorIntermedio(i.id!);
        if (mounted) {
          _insumosUtilizados = List.from(controller.insumosUtilizados);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(
            context,
            'Error al cargar insumos utilizados: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoadingRelations = false);
      }
    }
    debugPrint("[IntermedioEditScreen] Carga inicial finalizada.");
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
    final insumoCtrl = context.read<InsumoController>();
    if (insumoCtrl.insumos.isEmpty) {
      await insumoCtrl.cargarInsumos();
      if (!mounted) return; // Verificar de nuevo tras el await
    }
    await showDialog(
      context: context,
      builder:
          (ctx) => ModalAgregarInsumos(
            insumosIniciales: _insumosUtilizados,
            onGuardar: (nuevos) {
              if (mounted) {
                setState(() => _insumosUtilizados = List.from(nuevos));
              }
            },
          ),
    );
  }

  Future<void> _editarInsumoUtilizado(InsumoUtilizado iu) async {
    final insumoCtrl = context.read<InsumoController>();
    final insumoBase = insumoCtrl.insumos.firstWhereOrNull(
      (i) => i.id == iu.insumoId,
    );

    if (insumoBase == null) {
      showAppSnackBar(
        context,
        'Insumo base no encontrado para editar.',
        isError: true,
      );
      return;
    }

    final editado = await showDialog<InsumoUtilizado>(
      context: context,
      builder:
          (ctx) => ModalEditarCantidadInsumo(
            insumoUtilizado: iu,
            insumo: insumoBase,
            onGuardar: (nuevaCantidad) {
              Navigator.of(ctx).pop(iu.copyWith(cantidad: nuevaCantidad));
            },
          ),
    );

    if (editado != null && mounted) {
      setState(() {
        final idx = _insumosUtilizados.indexWhere(
          (x) => x.insumoId == editado.insumoId,
        );
        if (idx != -1) _insumosUtilizados[idx] = editado;
      });
    }
  }

  void _eliminarInsumoUtilizado(InsumoUtilizado iu) {
    setState(() {
      _insumosUtilizados.removeWhere((x) => x.insumoId == iu.insumoId);
      debugPrint(
        "[IntermedioEditScreen] InsumoUtilizado eliminado localmente: ${iu.insumoId}",
      );
    });
  }

  Future<void> _guardarIntermedio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorias.isEmpty) {
      showAppSnackBar(
        context,
        'Debes seleccionar al menos una categoría.',
        isError: true,
      );
      return;
    }
    if (widget.intermedio == null &&
        (_codigoGenerado == null || _codigoGenerado!.isEmpty)) {
      showAppSnackBar(
        context,
        'Aún se está generando el código, espera un momento.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final intermedioData = Intermedio.crear(
      id: widget.intermedio?.id,
      codigo: _codigoGenerado!,
      nombre: _nombreController.text.trim(),
      categorias: _categorias,
      unidad: _unidadSeleccionada ?? 'unidad',
      cantidadEstandar: double.tryParse(_cantidadController.text) ?? 1,
      reduccionPorcentaje: double.tryParse(_reduccionController.text) ?? 0,
      receta: _recetaController.text.trim(),
      tiempoPreparacionMinutos: int.tryParse(_tiempoController.text) ?? 0,
      fechaCreacion: widget.intermedio?.fechaCreacion,
      fechaActualizacion: DateTime.now(),
      activo: widget.intermedio?.activo ?? true,
    );

    final ctrl = context.read<IntermedioController>();
    bool success = false;
    String? errorMessage;

    try {
      if (widget.intermedio == null) {
        final creado = await ctrl.crearIntermedioConInsumos(
          intermedioData,
          _insumosUtilizados,
        );
        success = creado != null;
      } else {
        success = await ctrl.actualizarIntermedioConInsumos(
          intermedioData,
          _insumosUtilizados,
        );
      }
      if (!success) errorMessage = ctrl.error;
    } catch (e) {
      errorMessage = e.toString();
      success = false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      if (success) {
        showAppSnackBar(
          context,
          'Intermedio ${widget.intermedio == null ? 'creado' : 'actualizado'} con éxito.',
        );
        Navigator.of(context).pop(true);
      } else {
        showAppSnackBar(
          context,
          'Error al guardar: ${errorMessage ?? "Error desconocido"}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esEdicion = widget.intermedio != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Intermedio' : 'Crear Intermedio'),
        actions: [
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
                      onPressed: _guardarIntermedio,
                    ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Sección Código ---
            if (esEdicion) // Modo Edición: Mostrar código existente
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Intermedio',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _codigoGenerado ?? 'N/A',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else // Modo Creación: Mostrar código generado o indicador
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Código Intermedio',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  child:
                      _isGeneratingCode
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
                          : Text(
                            _codigoGenerado ??
                                'Error al generar', // Mostrar código o mensaje de error
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _codigoGenerado == null
                                      ? Colors.red
                                      : null, // Color rojo si hubo error
                            ),
                          ),
                ),
              ),

            // --- Campos del Formulario ---
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              textCapitalization: TextCapitalization.words,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Campo requerido'
                          : null,
            ),
            const SizedBox(height: 16),

            Text(
              'Categorías *',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            SelectorCategorias(
              categorias: Intermedio.categoriasDisponibles.keys.toList(),
              seleccionadas: _categorias,
              onChanged: (cats) => setState(() => _categorias = cats),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Alinear línea base de los campos
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad Estándar *',
                      hintText: 'Ej: 1000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Debe ser > 0';
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
                        (val) => setState(() => _unidadSeleccionada = val),
                    // Opcional: añade un label si el SelectorUnidades lo soporta
                    // label: 'Unidad *',
                    // validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _reduccionController,
              decoration: const InputDecoration(
                labelText: 'Reducción por Cocción (%)',
                hintText: 'Ej: 15 (para 15%)',
                suffixText: '%',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // Es opcional
                final n = double.tryParse(v);
                if (n == null || n < 0 || n > 100) return 'Entre 0-100';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recetaController,
              decoration: const InputDecoration(
                labelText: 'Receta (Opcional)',
                hintText: 'Pasos de preparación, notas...',
                alignLabelWithHint: true, // Alinear mejor con maxLines > 1
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tiempoController,
              decoration: const InputDecoration(
                labelText: 'Tiempo Preparación (minutos)',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null; // Es opcional
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Número inválido';
                return null;
              },
            ),
            const Divider(height: 32, thickness: 1),

            // Sección Insumos Utilizados con Widget Genérico
            _buildSectionHeader('Insumos Utilizados', _abrirModalInsumos),
            _buildRelationListSection(
              isLoading: _isLoadingRelations && esEdicion,
              isEmpty: _insumosUtilizados.isEmpty,
              listWidget: ListaComponentesRequeridos<InsumoUtilizado>(
                items: _insumosUtilizados,
                nombreGetter: (iu) {
                  final insumoCtrl = context.read<InsumoController>();
                  return insumoCtrl.insumos
                          .firstWhereOrNull((ins) => ins.id == iu.insumoId)
                          ?.nombre ??
                      iu.insumoId;
                },
                cantidadGetter: (iu) {
                  final insumoCtrl = context.read<InsumoController>();
                  final unidad =
                      insumoCtrl.insumos
                          .firstWhereOrNull((ins) => ins.id == iu.insumoId)
                          ?.unidad ??
                      '';
                  return '${iu.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
                },
                onEditar: _editarInsumoUtilizado,
                onEliminar: _eliminarInsumoUtilizado,
                emptyListText: "No hay insumos utilizados añadidos.",
              ),
              loadingText: 'Cargando insumos...',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helpers de UI (copiados de las otras pantallas) ---
  Widget _buildSectionHeader(String title, VoidCallback onAddPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar'),
            onPressed: onAddPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationListSection({
    required bool isLoading,
    required bool isEmpty,
    required Widget listWidget,
    required String loadingText,
  }) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 8),
              Text(loadingText),
            ],
          ),
        ),
      );
    } else if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
          child: Text(
            listWidget.toStringShallow(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(maxHeight: 200), // Ajustar altura
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: listWidget,
        ),
      );
    }
  }
}
