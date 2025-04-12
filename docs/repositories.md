# Repositories

Los repositories son responsables de la capa de acceso a datos de la aplicación. Implementan el patrón Repository para abstraer el acceso a la base de datos y proporcionar una interfaz consistente para el resto de la aplicación.

## Estructura

```
lib/
├── repositories/
│   ├── insumo_repository.dart
│   ├── insumo_repository_impl.dart
│   ├── proveedor_repository.dart
│   ├── proveedor_repository_impl.dart
│   ├── plato_repository.dart
│   ├── plato_repository_impl.dart
│   ├── intermedio_repository.dart
│   ├── intermedio_repository_impl.dart
│   ├── insumo_utilizado_repository.dart
│   ├── insumo_utilizado_repository_impl.dart
│   ├── intermedio_requerido_repository.dart
│   ├── intermedio_requerido_repository_impl.dart
│   ├── evento_repository.dart
│   ├── evento_repository_impl.dart
│   ├── plato_evento_repository.dart
│   ├── plato_evento_repository_impl.dart
│   └── intermedio_evento_repository.dart
│       └── intermedio_evento_repository_impl.dart
```

## Interfaces de Repositories

### InsumoRepository
```dart
abstract class InsumoRepository {
  // CRUD
  Future<Insumo> crear(Insumo insumo);
  Future<Insumo> obtener(String id);
  Future<List<Insumo>> obtenerTodos({String? proveedorId});
  Future<List<Insumo>> obtenerVarios(List<String> ids);
  Future<void> actualizar(Insumo insumo);
  Future<void> desactivar(String id);
  Future<List<Insumo>> buscarPorNombre(String query);
  Future<String> generarNuevoCodigo();
  Future<void> desactivarPorProveedor(String proveedorId);
  Future<int> contarActivosPorProveedor(String proveedorId);
  Future<Insumo> obtenerPorCodigo(String codigo);
  Future<void> eliminarInsumo(String id);

  // Métodos de filtrado
  Future<List<Insumo>> filtrarInsumosPorCategoria(String categoria);
  Future<List<Insumo>> filtrarInsumosPorCategorias(List<String> categorias);
  Future<List<Insumo>> filtrarInsumosPorNombre(String nombre);
  Future<List<Insumo>> filtrarInsumosPorProveedor(String proveedorId);
}
```

### ProveedorRepository
```dart
abstract class ProveedorRepository {
  Future<Proveedor> crear(Proveedor proveedor);
  Future<Proveedor> obtener(String id);
  Future<List<Proveedor>> obtenerTodos();
  Future<List<Proveedor>> obtenerPorNombre(String nombre);
  Future<void> actualizar(Proveedor proveedor);
  Future<void> eliminar(String id);
}
```

### PlatoRepository
```dart
abstract class PlatoRepository {
  Future<Plato> crear(Plato plato);
  Future<Plato> obtener(String id);
  Future<List<Plato>> obtenerTodos();
  Future<void> actualizar(Plato plato);
  Future<void> eliminar(String id);
  Future<List<Plato>> buscarPorNombre(String query);
  Future<List<Plato>> filtrarPorCategoria(String categoria);
}
```

### EventoRepository
```dart
abstract class EventoRepository {
  Future<Evento> crear(Evento evento);
  Future<Evento> obtener(String id);
  Future<List<Evento>> obtenerTodos();
  Future<void> actualizar(Evento evento);
  Future<void> eliminar(String id);
  Future<List<Evento>> obtenerPorTipo(TipoEvento tipo);
  Future<List<Evento>> obtenerPorEstado(EstadoEvento estado);
  Future<List<Evento>> obtenerProximos();
}
```

### IntermedioRepository
```dart
abstract class IntermedioRepository {
  Future<Intermedio> crear(Intermedio intermedio);
  Future<Intermedio> obtener(String id);
  Future<List<Intermedio>> obtenerTodos();
  Future<void> actualizar(Intermedio intermedio);
  Future<void> eliminar(String id);
}
```

### Relaciones
```dart
// PlatoEventoRepository
abstract class PlatoEventoRepository {
  Future<void> asociarPlatoEvento(String platoId, String eventoId);
  Future<void> desasociarPlatoEvento(String platoId, String eventoId);
  Future<List<Plato>> obtenerPlatosPorEvento(String eventoId);
}

// IntermedioEventoRepository
abstract class IntermedioEventoRepository {
  Future<void> asociarIntermedioEvento(String intermedioId, String eventoId);
  Future<List<Intermedio>> obtenerIntermediosPorEvento(String eventoId);
}
```

## Implementaciones

Todas las implementaciones:
1. Extienden su interfaz correspondiente
2. Utilizan Firestore como backend
3. Implementan manejo consistente de errores
4. Soportan caché local cuando es necesario

Ejemplo de implementación base:
```dart
class PlatoFirestoreRepository implements PlatoRepository {
  final FirebaseFirestore _firestore;
  
  @override
  Future<Plato> crear(Plato plato) async {
    try {
      final docRef = await _firestore.collection('platos').add(plato.toMap());
      return plato.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreError(e);
    }
  }
  
  // ... otros métodos
}
```

## Manejo de Errores

```dart
Exception _handleFirestoreError(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return Exception('No tienes permiso para acceder a los datos');
    case 'not-found':
      return Exception('Registro no encontrado');
    case 'invalid-argument':
      return Exception('Datos no válidos');
    default:
      return Exception('Error de Firebase: ${e.message}');
  }
}
```

## Repositorios Especializados

| Repositorio | Descripción |
|-------------|-------------|
| `InsumoRepository` | CRUD para insumos |
| `InsumoUtilizadoRepository` | Relación insumo-plato |
| `IntermedioRequeridoRepository` | Relación insumo-intermedio |
| `ProveedorRepository` | Gestión de proveedores |
