# API Documentation

## Modelos

### Plato

#### Estructura
```dart
class Plato {
  final String id;
  final String nombre;
  final String descripcion;
  final double costoTotal;
  final double precioVenta;
  final List<String> categorias;
  final List<IntermedioRequerido> intermedios;
  final bool activo;
}
```

#### Métodos
```dart
// Constructores
Plato.fromJson(Map<String, dynamic> json)
Plato.fromFirestore(DocumentSnapshot doc)

// Conversión
Map<String, dynamic> toJson()
Map<String, dynamic> toFirestore()

// Utilidades
double get margenGanancia
bool tieneCategoria(String categoria)
```

### Evento

#### Estructura
```dart
class Evento {
  final String id;
  final String nombre;
  final DateTime fecha;
  final TipoEvento tipo;
  final EstadoEvento estado;
  final List<String> platosId;
  final Map<String, dynamic> detalles;
}
```

#### Métodos
```dart
// Constructores
Evento.fromJson(Map<String, dynamic> json)
Evento.fromFirestore(DocumentSnapshot doc)

// Conversión
Map<String, dynamic> toJson()
Map<String, dynamic> toFirestore()

// Utilidades
bool get esProximo
bool get requiereConfirmacion
```

## Servicios

### PlatoService

#### Métodos
```dart
// CRUD Básico
Future<List<Plato>> obtenerTodos({bool? activo})
Future<Plato> obtenerPlato(String id)
Future<Plato> crearPlato(Plato plato)
Future<void> actualizarPlato(Plato plato)
Future<void> desactivarPlato(String id)

// Búsqueda y Filtrado
Future<List<Plato>> buscarPlatos(String query)
Future<List<Plato>> filtrarPorCategoria(String categoria)

// Costos
Future<void> actualizarCostos(String id, CostoProduccion costos)
Future<List<CostoProduccion>> obtenerHistorialCostos(String id)
```

### EventoService

#### Métodos
```dart
// CRUD Básico
Future<List<Evento>> obtenerEventos({
  DateTime? fechaInicio,
  DateTime? fechaFin,
  TipoEvento? tipo,
  EstadoEvento? estado,
})
Future<Evento> obtenerEvento(String id)
Future<void> crearEvento(Evento evento)
Future<void> actualizarEvento(Evento evento)

// Gestión de Estado
Future<void> confirmarEvento(String id)
Future<void> cancelarEvento(String id, String motivo)

// Platos
Future<void> agregarPlato(String eventoId, String platoId)
Future<void> removerPlato(String eventoId, String platoId)
```

## ViewModels

### PlatoViewModel

#### Estado
```dart
bool loading
String? error
List<Plato> platos
Plato? platoSeleccionado
Map<String, List<Plato>> platosPorCategoria
```

#### Métodos
```dart
// Carga de Datos
Future<void> cargarPlatos({bool? activo})
Future<void> cargarPlatosPorCategoria(List<String> categorias)

// Operaciones CRUD
Future<bool> crearPlato(Plato plato)
Future<bool> actualizarPlato(Plato plato)
Future<bool> desactivarPlato(String id)

// Selección
void seleccionarPlato(String id)
void limpiarSeleccion()
```

### EventoViewModel

#### Estado
```dart
bool loading
String? error
List<Evento> eventos
List<Evento> eventosUrgentes
Evento? eventoSeleccionado
```

#### Métodos
```dart
// Carga de Datos
Future<void> cargarEventos({
  DateTime? fechaInicio,
  DateTime? fechaFin,
  TipoEvento? tipo,
  EstadoEvento? estado,
})

// Operaciones CRUD
Future<bool> crearEvento(Evento evento)
Future<bool> actualizarEvento(Evento evento)
Future<bool> confirmarEvento(String id)

// Gestión de Platos
Future<bool> agregarPlato(String platoId)
Future<bool> removerPlato(String platoId)
```

## Enums y Tipos

### TipoEvento
```dart
enum TipoEvento {
  privado,
  corporativo,
  social,
  otro
}
```

### EstadoEvento
```dart
enum EstadoEvento {
  pendiente,
  confirmado,
  enProceso,
  completado,
  cancelado
}
```

### CostoTipo
```dart
enum CostoTipo {
  directo,
  indirecto,
  adicional
}
```

## Interfaces

### IFirebaseService
```dart
abstract class IFirebaseService<T> {
  Future<T> get(String id);
  Future<List<T>> getAll();
  Future<void> set(String id, T data);
  Future<void> delete(String id);
  Stream<List<T>> watch();
}
```

### IViewModel
```dart
abstract class IViewModel {
  bool get loading;
  String? get error;
  void setLoading(bool value);
  void setError(String? error);
}
```

## Excepciones

### ServiceException
```dart
class ServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ServiceException(this.message, {this.code, this.originalError});
}
```

### ValidationException
```dart
class ValidationException implements Exception {
  final String message;
  final Map<String, String> errors;

  ValidationException(this.message, {this.errors = const {}});
}
```

## Ejemplos de Uso

### Crear y Guardar un Plato
```dart
final platoService = PlatoService();
final platoViewModel = PlatoViewModel(platoService);

// Crear nuevo plato
final plato = Plato(
  nombre: 'Pasta Carbonara',
  descripcion: 'Pasta italiana tradicional',
  costoTotal: 15000,
  precioVenta: 25000,
  categorias: ['Pasta', 'Principal'],
  intermedios: [],
  activo: true,
);

// Guardar plato
try {
  final success = await platoViewModel.crearPlato(plato);
  if (success) {
    print('Plato creado exitosamente');
  }
} on ServiceException catch (e) {
  print('Error al crear plato: ${e.message}');
}
```

### Gestionar un Evento
```dart
final eventoService = EventoService();
final eventoViewModel = EventoViewModel(eventoService);

// Crear nuevo evento
final evento = Evento(
  nombre: 'Cena Corporativa',
  fecha: DateTime.now().add(Duration(days: 7)),
  tipo: TipoEvento.corporativo,
  estado: EstadoEvento.pendiente,
  platosId: [],
  detalles: {
    'numeroInvitados': 50,
    'ubicacion': 'Salón Principal',
  },
);

// Guardar evento
try {
  final success = await eventoViewModel.crearEvento(evento);
  if (success) {
    // Agregar platos al evento
    await eventoViewModel.agregarPlato('plato-id-1');
    await eventoViewModel.agregarPlato('plato-id-2');
    
    // Confirmar evento
    await eventoViewModel.confirmarEvento(evento.id);
  }
} on ServiceException catch (e) {
  print('Error al gestionar evento: ${e.message}');
}
```

## Reglas de Validación

### Plato
```dart
void validarPlato(Plato plato) {
  if (plato.nombre.isEmpty) {
    throw ValidationException(
      'Nombre inválido',
      errors: {'nombre': 'El nombre es requerido'},
    );
  }
  
  if (plato.precioVenta <= plato.costoTotal) {
    throw ValidationException(
      'Precio inválido',
      errors: {'precioVenta': 'El precio debe ser mayor al costo'},
    );
  }
  
  if (plato.categorias.isEmpty) {
    throw ValidationException(
      'Categorías inválidas',
      errors: {'categorias': 'Debe tener al menos una categoría'},
    );
  }
}
```

### Evento
```dart
void validarEvento(Evento evento) {
  if (evento.nombre.isEmpty) {
    throw ValidationException(
      'Nombre inválido',
      errors: {'nombre': 'El nombre es requerido'},
    );
  }
  
  if (evento.fecha.isBefore(DateTime.now())) {
    throw ValidationException(
      'Fecha inválida',
      errors: {'fecha': 'La fecha debe ser futura'},
    );
  }
  
  if (evento.platosId.isEmpty) {
    throw ValidationException(
      'Platos inválidos',
      errors: {'platosId': 'Debe tener al menos un plato'},
    );
  }
}
```
