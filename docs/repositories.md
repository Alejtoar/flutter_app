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
│   └── intermedio_requerido_repository_impl.dart
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

## Implementaciones

Todas las implementaciones siguen el patrón:
1. Extienden su interfaz correspondiente
2. Utilizan Firestore como backend
3. Implementan un manejo consistente de errores
4. Manejan estados y caché cuando es necesario

## Manejo de Errores

Todos los repositories implementan un manejo consistente de errores usando el método `_handleFirestoreError`:
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
      return Exception('Error al acceder a los datos: ${e.message}');
  }
}
```

## Caché

Algunos repositories implementan caché en memoria para optimizar el rendimiento:
- `InsumoRepository`: Caché de códigos de insumos
- `ProveedorRepository`: Caché de proveedores frecuentemente accedidos

## Filtrado

Los repositories implementan métodos de filtrado eficientes usando consultas de Firestore:
- Filtrado por categoría
- Filtrado por proveedor
- Búsqueda parcial de nombres
- Filtrado por estado activo
