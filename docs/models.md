# Modelos

## Modelos Principales

### 1. Plato
```dart
class Plato {
  String id;
  String nombre;
  String descripcion;
  List<String> categorias;
  bool activo;
  DateTime? fechaCreacion;
  DateTime? fechaActualizacion;
}
```
**Descripción**: Representa un plato del menú con su información básica, categorización y fechas de creación y actualización.

### 2. Evento
```dart
class Evento {
  String id;
  String nombre;
  DateTime fecha;
  TipoEvento tipo;
  EstadoEvento estado;
  List<String> platosId;
  Map<String, dynamic> detalles;
}
```
**Descripción**: Gestiona eventos y reservaciones del restaurante.

### 3. IntermedioRequerido
```dart
class IntermedioRequerido {
  String? id;
  String platoId;
  String intermedioId;
  double cantidad;
}
```
**Descripción**: Representa los componentes intermedios o preparaciones requeridas para un plato. Enlaza un plato con sus intermedios requeridos y sus cantidades.

### 4. InsumoUtilizado
```dart
class InsumoUtilizado {
  String? id;
  String insumoId;
  String intermedioId;
  double cantidad;
}
```
**Descripción**: Representa la relación entre un intermedio y sus ingredientes (insumos), incluyendo la cantidad utilizada.

### 5. PlatoEvento
```dart
class PlatoEvento {
  String? id;
  String eventoId;
  String platoId;
  int cantidad;
}
```
**Descripción**: Enlaza platos con eventos con sus respectivas cantidades.

## Relaciones entre Modelos

1. **Plato -> IntermedioRequerido**
   - Un plato puede tener múltiples intermedios requeridos
   - Cada intermedio está enlazado a un plato específico a través de `platoId`

2. **IntermedioRequerido -> InsumoUtilizado**
   - Cada intermedio puede tener múltiples ingredientes
   - Los ingredientes están enlazados a su intermedio a través de `intermedioId`

3. **Evento -> PlatoEvento**
   - Un evento puede tener múltiples platos
   - Cada plato está enlazado a un evento a través de `eventoId`

4. **PlatoEvento -> Plato**
   - Enlaza platos de eventos con sus definiciones de platos originales
   - Mantiene la cantidad de cada plato en el evento

## Flujo de Cálculo de Costos

El sistema de cálculo de costos es ahora jerárquico e integrado en la estructura del modelo:

1. **Nivel de Ingrediente (InsumoUtilizado)**
   - Cada ingrediente tiene un precio unitario
   - El costo se calcula como `cantidad * precioUnitario`

2. **Nivel de Intermedio (IntermedioRequerido)**
   - Suma los costos de todos los ingredientes
   - Costo total = suma de todos los costos de ingredientes

3. **Nivel de Plato (Plato)**
   - Suma los costos de todos los intermedios requeridos
   - Aplica un margen del 30% para obtener el precio de venta final

Este enfoque jerárquico proporciona una forma más precisa y mantenible de calcular costos directamente desde los ingredientes y intermedios utilizados en cada plato.

## Métodos
- `crear`: Factory constructor con validación de campos
- `fromFirestore`: Constructor para crear instancia desde documento Firestore
- `fromMap`: Constructor para crear instancia desde Map
- `toFirestore`: Convierte la instancia a Map para Firestore
- `copyWith`: Crea una copia con campos actualizados
- `==` y `hashCode`: Implementación de equidad
- `toString`: Representación en string del objeto

## Validaciones
- `intermedioId` no puede estar vacío
- `codigo` no puede estar vacío
- `nombre` no puede estar vacío
- `cantidad` debe ser positiva
