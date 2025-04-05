# Golo App - Sistema de Gestión de Restaurantes

## Descripción General
Golo App es una aplicación de gestión integral para restaurantes desarrollada con Flutter. La aplicación permite administrar platos, eventos, inventario y costos de producción, facilitando la operación diaria del restaurante.

## Objetivos
- Gestionar el menú y platos del restaurante
- Administrar eventos y reservaciones
- Controlar costos de producción
- Gestionar inventario y materias primas
- Generar reportes y análisis

## Arquitectura

### Patrón de Diseño
La aplicación utiliza el patrón MVVM (Model-View-ViewModel) con las siguientes capas:

1. **Models**: Representación de datos y lógica de negocio
2. **Views**: Interfaces de usuario y widgets
3. **ViewModels**: Lógica de presentación y estado
4. **Services**: Capa de acceso a datos y servicios externos

### Estructura del Proyecto
```
lib/
├── models/           # Modelos de datos
├── services/         # Servicios y acceso a datos
├── ui/
│   ├── common/      # Widgets comunes
│   ├── navigation/   # Navegación
│   ├── screens/     # Pantallas principales
│   └── theme/       # Temas y estilos
├── viewmodels/      # ViewModels
└── views/           # Componentes de vista
```

## Componentes Principales

### 1. Gestión de Platos
- **PlatoModel**: Estructura de datos para platos
- **PlatoViewModel**: Lógica de negocio para platos
- **PlatoService**: Acceso a datos de platos
- Funcionalidades:
  - CRUD de platos
  - Cálculo de costos
  - Categorización
  - Gestión de recetas

### 2. Gestión de Eventos
- **EventoModel**: Estructura para eventos
- **EventoViewModel**: Lógica de eventos
- **EventoService**: Acceso a datos de eventos
- Funcionalidades:
  - Programación de eventos
  - Gestión de reservaciones
  - Estados de eventos
  - Notificaciones

### 3. Gestión de Costos
- **CostoProduccionModel**: Estructura de costos
- **CostoProduccionViewModel**: Lógica de costos
- Funcionalidades:
  - Cálculo de costos directos
  - Costos indirectos
  - Márgenes de ganancia
  - Análisis de rentabilidad

## Tecnologías Utilizadas
- **Flutter**: Framework de UI
- **Firebase**:
  - Firestore: Base de datos
  - Auth: Autenticación
  - Storage: Almacenamiento
- **Provider**: Gestión de estado

## Gestión de Estado
- Provider para gestión de estado local
- ChangeNotifier para actualización de UI
- ViewModels para lógica de negocio

## Navegación
- Sistema de navegación basado en índices
- Soporte para diferentes tamaños de pantalla
- Navegación adaptativa (rail/bottom bar)

## Modelos de Datos Principales

### Plato
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

### Evento
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

## Flujos de Trabajo Principales

1. **Creación de Platos**
   - Ingreso de información básica
   - Asignación de categorías
   - Definición de receta
   - Cálculo de costos

2. **Gestión de Eventos**
   - Programación
   - Asignación de recursos
   - Seguimiento de estado
   - Confirmación y cierre

3. **Control de Costos**
   - Registro de costos directos
   - Asignación de costos indirectos
   - Cálculo de márgenes
   - Análisis de rentabilidad

## Configuración del Entorno

### Requisitos
- Flutter SDK
- Firebase CLI
- Windows SDK (para compilación Windows)

### Configuración
1. Clonar el repositorio
2. Instalar dependencias: `flutter pub get`
3. Configurar Firebase
4. Ejecutar la aplicación: `flutter run`

## Mejores Prácticas
1. **Código**
   - Clean Code
   - DRY (Don't Repeat Yourself)
   - SOLID principles

2. **UI/UX**
   - Material Design
   - Responsive Design
   - Accesibilidad

3. **Estado**
   - Inmutabilidad
   - Single Source of Truth
   - Separación de Concerns

## Roadmap
1. **Fase 1** (Actual)
   - CRUD básico de platos y eventos
   - Gestión de costos básica
   - UI responsive

2. **Fase 2**
   - Reportes avanzados
   - Integración con POS
   - Gestión de inventario

3. **Fase 3**
   - Análisis predictivo
   - Automatización de procesos
   - Integración con proveedores

