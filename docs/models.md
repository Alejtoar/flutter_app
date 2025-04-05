# Modelos

## Modelos Principales

### 1. Plato
```dart
class Plato {
  String id;
  String nombre;
  String descripcion;
  double costoTotal;
  double precioVenta;
  List<String> categorias;
  List<IntermedioRequerido> intermedios;
  bool activo;
}
```
**Descripción**: Representa un plato del menú con su información básica, costos y componentes.

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
- `orden` (int): Orden de presentación/preparación

### Métodos
- `crear`: Factory constructor con validación de campos
- `fromFirestore`: Constructor para crear instancia desde documento Firestore
- `fromMap`: Constructor para crear instancia desde Map
- `toFirestore`: Convierte la instancia a Map para Firestore
- `copyWith`: Crea una copia con campos actualizados
- `==` y `hashCode`: Implementación de equidad
- `toString`: Representación en string del objeto

### Validaciones
- `intermedioId` no puede estar vacío
- `codigo` no puede estar vacío
- `nombre` no puede estar vacío
- `cantidad` debe ser positiva
