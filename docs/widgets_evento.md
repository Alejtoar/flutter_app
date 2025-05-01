//busqueda_bar_eventos.dart
import 'package:flutter/material.dart';

class BusquedaBarEventos extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const BusquedaBarEventos({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      ),
      onChanged: onChanged,
    );
  }
}

//lista_eventos.dart
import 'package:flutter/material.dart';
import '../../../../models/evento.dart';

class ListaEventos extends StatelessWidget {
  final List<Evento> eventos;
  final void Function(Evento) onVerDetalle;
  final void Function(Evento) onEditar;
  final void Function(Evento) onEliminar;

  const ListaEventos({
    Key? key,
    required this.eventos,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  Color _colorPorEstado(EstadoEvento estado) {
    switch (estado) {
      case EstadoEvento.cotizado:
        return Colors.blue[100]!;
      case EstadoEvento.confirmado:
        return Colors.green[100]!;
      case EstadoEvento.completado:
        return Colors.grey[400]!;
      case EstadoEvento.cancelado:
        return Colors.red[200]!;
      case EstadoEvento.enPruebaMenu:
        return Colors.orange[200]!;
      case EstadoEvento.enCotizacion:
        return Colors.purple[100]!;
      }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: eventos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final evento = eventos[i];
        return Card(
          color: _colorPorEstado(evento.estado),
          child: ListTile(
            title: Text(evento.nombreCliente),
            subtitle: Text('Fecha: ${evento.fecha.day}/${evento.fecha.month}/${evento.fecha.year}\nEstado: ${evento.estado.toString().split('.').last}'),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver',
                  onPressed: () => onVerDetalle(evento),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => onEditar(evento),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar',
                  onPressed: () => onEliminar(evento),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//lista_insumos_evento.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';
import '../../../../models/insumo_evento.dart';

class ListaInsumosEvento extends StatelessWidget {
  final List<InsumoEvento> insumosEvento;
  final void Function(InsumoEvento) onEditar;
  final void Function(InsumoEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaInsumosEvento({
    Key? key,
    required this.insumosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (insumosEvento.isEmpty) {
      return const Center(child: Text('No hay insumos agregados'));
    }
    return Builder(
      builder: (context) {
        final insumoCtrl = Provider.of<InsumoController>(context, listen: true);
        return DataTable(
          columns: const [
            DataColumn(label: Text('Insumo')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: insumosEvento.map((ie) {
            String nombre = ie.insumoId;
            String? unidad;
            try {
              final insumo = insumoCtrl.insumos.firstWhere((x) => x.id == ie.insumoId);
              nombre = insumo.nombre;
              unidad = insumo.unidad;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${ie.cantidad}${unidad != null ? ' $unidad' : ''}')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(ie),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(ie),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

//lista_intermedios_evento.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';
import '../../../../models/intermedio_evento.dart';

class ListaIntermediosEvento extends StatelessWidget {
  final List<IntermedioEvento> intermediosEvento;
  final void Function(IntermedioEvento) onEditar;
  final void Function(IntermedioEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaIntermediosEvento({
    Key? key,
    required this.intermediosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (intermediosEvento.isEmpty) {
      return const Center(child: Text('No hay intermedios agregados'));
    }
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        return DataTable(
          columns: const [
            DataColumn(label: Text('Intermedio')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: intermediosEvento.map((ie) {
            String nombre = ie.intermedioId;
            String? unidad;
            try {
              final intermedio = intermedioCtrl.intermedios.firstWhere((x) => x.id == ie.intermedioId);
              nombre = intermedio.nombre;
              unidad = intermedio.unidad;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${ie.cantidad} ${unidad != null ? ' $unidad' : ''}')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(ie),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(ie),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

//lista_platos_evento.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';
import '../../../../models/plato_evento.dart';

class ListaPlatosEvento extends StatelessWidget {
  final List<PlatoEvento> platosEvento;
  final void Function(PlatoEvento) onEditar;
  final void Function(PlatoEvento) onEliminar;
  final VoidCallback? onAgregar;

  const ListaPlatosEvento({
    Key? key,
    required this.platosEvento,
    required this.onEditar,
    required this.onEliminar,
    this.onAgregar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (platosEvento.isEmpty) {
      return const Center(child: Text('No hay platos agregados'));
    }
    return Builder(
      builder: (context) {
        final platoCtrl = Provider.of<PlatoController>(context, listen: true);
        return DataTable(
          columns: const [
            DataColumn(label: Text('Plato')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: platosEvento.map((pe) {
            String nombre = pe.platoId;
            try {
              final plato = platoCtrl.platos.firstWhere((x) => x.id == pe.platoId);
              nombre = plato.nombre;
            } catch (_) {}
            return DataRow(
              cells: [
                DataCell(Text(nombre)),
                DataCell(Text('${pe.cantidad} Platos')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => onEditar(pe),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      onPressed: () => onEliminar(pe),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

//modal_agregar_insumos_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo_evento.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/insumos/controllers/insumo_controller.dart';

class ModalAgregarInsumosEvento extends StatelessWidget {
  final List<InsumoEvento> insumosIniciales;
  final void Function(List<InsumoEvento>) onGuardar;

  const ModalAgregarInsumosEvento({Key? key, required this.insumosIniciales, required this.onGuardar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InsumoController>(
      builder: (context, insumoCtrl, _) {
        if (insumoCtrl.insumos.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        return ModalAgregarRequeridos<InsumoEvento>(
          titulo: 'Agregar Insumos al Evento',
          requeridosIniciales: insumosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return insumoCtrl.insumos.where((i) => i.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final insumo = item as Insumo;
            return ListTile(
              title: Text(insumo.nombre),
              subtitle: Text(insumo.unidad),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            if (item is Insumo) return item.unidad;
            if (item is InsumoEvento) {
              final insumo = insumoCtrl.insumos.firstWhere(
                (i) => i.id == item.insumoId,
                orElse: () => Insumo(
                  id: '', codigo: '', nombre: '', categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true
                ),
              );
              return insumo.unidad;
            }
            return '';
          },
          crearRequerido: (item, cantidad) {
            final insumo = item as Insumo;
            return InsumoEvento(
              id: null,
              eventoId: '', // Se asigna al guardar el plato
              insumoId: insumo.id!,
              cantidad: cantidad,
              unidad: insumo.unidad,
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar insumo',
          nombreMostrar: (r) =>
            insumoCtrl.insumos.firstWhere((i) => i.id == r.insumoId, orElse: () => Insumo(id: r.insumoId, codigo: '', nombre: r.insumoId, categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true)).nombre,
          subtitleBuilder: (r) {
            final insumo = insumoCtrl.insumos.firstWhere((i) => i.id == r.insumoId, orElse: () => Insumo(id: r.insumoId, codigo: '', nombre: r.insumoId, categorias: [], unidad: '', precioUnitario: 0, proveedorId: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true));
            final unidad = insumo.unidad;
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}

//modal_agregar_intermedios_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio_evento.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/intermedios/controllers/intermedio_controller.dart';

class ModalAgregarIntermediosEvento extends StatelessWidget {
  final List<IntermedioEvento> intermediosIniciales;
  final void Function(List<IntermedioEvento>) onGuardar;

  const ModalAgregarIntermediosEvento({Key? key, required this.intermediosIniciales, required this.onGuardar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IntermedioController>(
      builder: (context, intermedioCtrl, _) {
        if (intermedioCtrl.intermedios.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ));
        }
        return ModalAgregarRequeridos<IntermedioEvento>(
          titulo: 'Agregar Intermedios al Evento',
          requeridosIniciales: intermediosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return intermedioCtrl.intermedios.where((i) => i.nombre.toLowerCase().contains(query.toLowerCase())).toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final intermedio = item as Intermedio;
            return ListTile(
              title: Text(intermedio.nombre),
              subtitle: Text(intermedio.unidad),
              trailing: yaAgregado ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            if (item is Intermedio) return item.unidad;
            if (item is IntermedioEvento) {
              final intermedio = intermedioCtrl.intermedios.firstWhere(
                (i) => i.id == item.intermedioId,
                orElse: () => Intermedio(
                  id: '', codigo: '', nombre: '', categorias: [], unidad: '', cantidadEstandar: 0, reduccionPorcentaje: 0, receta: '', tiempoPreparacionMinutos: 0, fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true
                ),
              );
              return intermedio.unidad;
            }
            return '';
          },
          crearRequerido: (item, cantidad) {
            final intermedio = item as Intermedio;
            return IntermedioEvento(
              id: null,
              eventoId: '', // Se asigna al guardar el evento
              intermedioId: intermedio.id!,
              cantidad: cantidad.toInt(),
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar intermedio',
          nombreMostrar: (r) =>
            intermedioCtrl.intermedios.firstWhere((i) => i.id == r.intermedioId, orElse: () => Intermedio(id: r.intermedioId, codigo: '', nombre: r.intermedioId, categorias: [], unidad: '', cantidadEstandar: 0, reduccionPorcentaje: 0, receta: '', tiempoPreparacionMinutos: 0, fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true)).nombre,
          subtitleBuilder: (r) {
            final intermedio = intermedioCtrl.intermedios.firstWhere((i) => i.id == r.intermedioId, orElse: () => Intermedio(id: r.intermedioId, codigo: '', nombre: r.intermedioId, categorias: [], unidad: '', cantidadEstandar: 0, reduccionPorcentaje: 0, receta: '', tiempoPreparacionMinutos: 0, fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true));
            final unidad = intermedio.unidad;
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}

//modal_agregar_platos_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';
import 'package:provider/provider.dart';
import 'package:golo_app/features/common/modal_agregar_requeridos.dart';
import 'package:golo_app/features/catalogos/platos/controllers/plato_controller.dart';

class ModalAgregarPlatosEvento extends StatelessWidget {
  final List<PlatoEvento> platosIniciales;
  final void Function(List<PlatoEvento>) onGuardar;

  const ModalAgregarPlatosEvento({
    Key? key,
    required this.platosIniciales,
    required this.onGuardar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatoController>(
      builder: (context, platoCtrl, _) {
        if (platoCtrl.platos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ModalAgregarRequeridos<PlatoEvento>(
          titulo: 'Agregar Platos al Evento',
          requeridosIniciales: platosIniciales,
          onGuardar: onGuardar,
          onBuscar: (query) async {
            return platoCtrl.platos
                .where(
                  (p) => p.nombre.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
          },
          itemBuilder: (item, yaAgregado, onTap) {
            final plato = item as Plato;
            return ListTile(
              title: Text(plato.nombre),
              subtitle: Text(plato.descripcion),
              trailing:
                  yaAgregado
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
              onTap: yaAgregado ? null : onTap,
            );
          },
          unidadGetter: (item) {
            return 'Platos';
          },
          crearRequerido: (item, cantidad) {
            final plato = item as Plato;
            return PlatoEvento(
              id: null,
              eventoId: '', // Se asigna al guardar el plato
              platoId: plato.id!,
              cantidad: cantidad.toInt(),
            );
          },
          labelCantidad: 'Cantidad',
          labelBuscar: 'Buscar plato',
          nombreMostrar:
              (r) =>
                  platoCtrl.platos
                      .firstWhere(
                        (p) => p.id == r.platoId,
                        orElse:
                            () => Plato(
                              id: r.platoId,
                              codigo: '',
                              nombre: r.platoId,
                              categorias: [],
                              receta: '',
                              fechaCreacion: DateTime.now(),
                              fechaActualizacion: DateTime.now(),
                              activo: true,
                              porcionesMinimas: 1,
                            ),
                      )
                      .nombre,
          subtitleBuilder: (r) {
            //final plato = platoCtrl.platos.firstWhere((p) => p.id == r.platoId, orElse: () => Plato(id: r.platoId, codigo: '', nombre: r.platoId, categorias: [], receta: '', fechaCreacion: DateTime.now(), fechaActualizacion: DateTime.now(), activo: true, porcionesMinimas:1));
            final unidad = 'Platos';
            return 'Cantidad: ${r.cantidad}${unidad.isNotEmpty ? ' $unidad' : ''}';
          },
          unidadLabel: null,
        );
      },
    );
  }
}

//modal_editar_cantidad_insumo_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/insumo.dart';
import 'package:golo_app/models/insumo_evento.dart';

/// Modal para editar la cantidad de un insumo en un evento.
class ModalEditarCantidadInsumoEvento extends StatefulWidget {
  final InsumoEvento insumoEvento;
  final Insumo insumo;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadInsumoEvento({
    Key? key,
    required this.insumoEvento,
    required this.insumo,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadInsumoEvento> createState() => _ModalEditarCantidadInsumoEventoState();
}

class _ModalEditarCantidadInsumoEventoState extends State<ModalEditarCantidadInsumoEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.insumoEvento.cantidad.toString());
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.insumo.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffixText: widget.insumo.unidad,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final nuevaCantidad = double.tryParse(_cantidadController.text);
                    if (nuevaCantidad == null || nuevaCantidad <= 0) return;
                    widget.onGuardar(nuevaCantidad);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//modal_editar_cantidad_intermedio_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/intermedio.dart';
import 'package:golo_app/models/intermedio_evento.dart';

/// Modal para editar la cantidad de un intermedio en un evento.
class ModalEditarCantidadIntermedioEvento extends StatefulWidget {
  final IntermedioEvento intermedioEvento;
  final Intermedio intermedio;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadIntermedioEvento({
    Key? key,
    required this.intermedioEvento,
    required this.intermedio,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadIntermedioEvento> createState() => _ModalEditarCantidadIntermedioEventoState();
}

class _ModalEditarCantidadIntermedioEventoState extends State<ModalEditarCantidadIntermedioEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.intermedioEvento.cantidad.toString());
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.intermedio.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffixText: widget.intermedio.unidad,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final nuevaCantidad = double.tryParse(_cantidadController.text);
                    if (nuevaCantidad == null || nuevaCantidad <= 0) return;
                    widget.onGuardar(nuevaCantidad);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//modal_editar_cantidad_plato_evento.dart
import 'package:flutter/material.dart';
import 'package:golo_app/models/plato.dart';
import 'package:golo_app/models/plato_evento.dart';

/// Modal para editar la cantidad de un plato en un evento.
class ModalEditarCantidadPlatoEvento extends StatefulWidget {
  final PlatoEvento platoEvento;
  final Plato plato;
  final void Function(double nuevaCantidad) onGuardar;

  const ModalEditarCantidadPlatoEvento({
    Key? key,
    required this.platoEvento,
    required this.plato,
    required this.onGuardar,
  }) : super(key: key);

  @override
  State<ModalEditarCantidadPlatoEvento> createState() => _ModalEditarCantidadPlatoEventoState();
}

class _ModalEditarCantidadPlatoEventoState extends State<ModalEditarCantidadPlatoEvento> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: widget.platoEvento.cantidad.toString());
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.plato.nombre,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final nuevaCantidad = double.tryParse(_cantidadController.text);
                    if (nuevaCantidad == null || nuevaCantidad <= 0) return;
                    widget.onGuardar(nuevaCantidad);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
