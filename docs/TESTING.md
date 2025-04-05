# Estrategia de Testing

## Visión General

La estrategia de testing de Golo App se basa en la pirámide de testing, con énfasis en pruebas unitarias y de integración.

```
    /\
   /UI\
  /----\
 /WIDGET\
/--------\
/  UNIT   \
```

## Tipos de Tests

### 1. Unit Tests

#### Modelos
```dart
void main() {
  group('Plato Tests', () {
    test('should create valid Plato object', () {
      final plato = Plato(
        nombre: 'Test Plato',
        descripcion: 'Test Description',
        costoTotal: 100.0,
        precioVenta: 150.0,
        categorias: ['Test'],
      );
      
      expect(plato.nombre, 'Test Plato');
      expect(plato.precioVenta, 150.0);
    });
    
    test('should calculate margin correctly', () {
      final plato = Plato(
        costoTotal: 100.0,
        precioVenta: 150.0,
      );
      
      expect(plato.margenGanancia, 0.5); // 50% margin
    });
  });
}
```

#### ViewModels
```dart
void main() {
  group('PlatoViewModel Tests', () {
    late PlatoViewModel viewModel;
    late MockPlatoService mockService;

    setUp(() {
      mockService = MockPlatoService();
      viewModel = PlatoViewModel(mockService);
    });

    test('should load platos successfully', () async {
      when(mockService.obtenerTodos())
          .thenAnswer((_) async => [TestData.testPlato]);
          
      await viewModel.cargarPlatos();
      
      expect(viewModel.platos.length, 1);
      expect(viewModel.loading, false);
      expect(viewModel.error, null);
    });
  });
}
```

#### Services
```dart
void main() {
  group('PlatoService Tests', () {
    late PlatoService service;
    late MockFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirestore();
      service = PlatoService(firestore: mockFirestore);
    });

    test('should create plato in Firestore', () async {
      final plato = TestData.testPlato;
      
      when(mockFirestore.collection('platos').add(any))
          .thenAnswer((_) async => MockDocumentReference());
          
      final result = await service.crearPlato(plato);
      
      expect(result.id, isNotNull);
    });
  });
}
```

### 2. Widget Tests

#### Screens
```dart
void main() {
  group('PlatosScreen Tests', () {
    testWidgets('should display list of platos', (tester) async {
      final mockViewModel = MockPlatoViewModel();
      when(mockViewModel.platos).thenReturn([TestData.testPlato]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PlatoViewModel>.value(
            value: mockViewModel,
            child: PlatosScreen(),
          ),
        ),
      );

      expect(find.text('Test Plato'), findsOneWidget);
      expect(find.byType(PlatoCard), findsOneWidget);
    });
  });
}
```

#### Widgets
```dart
void main() {
  group('PlatoCard Tests', () {
    testWidgets('should display plato information', (tester) async {
      final plato = TestData.testPlato;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatoCard(plato: plato),
          ),
        ),
      );

      expect(find.text(plato.nombre), findsOneWidget);
      expect(find.text(plato.descripcion), findsOneWidget);
      expect(find.text('\$${plato.precioVenta}'), findsOneWidget);
    });
  });
}
```

### 3. Integration Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navegar a PlatosScreen
      await tester.tap(find.byIcon(Icons.restaurant_menu));
      await tester.pumpAndSettle();

      // Verificar que estamos en PlatosScreen
      expect(find.text('Platos'), findsOneWidget);

      // Abrir diálogo de nuevo plato
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Rellenar formulario
      await tester.enterText(
          find.byKey(Key('nombre_field')), 'Nuevo Plato');
      await tester.enterText(
          find.byKey(Key('precio_field')), '100.0');
      
      // Guardar plato
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Verificar que el plato se agregó
      expect(find.text('Nuevo Plato'), findsOneWidget);
    });
  });
}
```

## Configuración de Tests

### pubspec.yaml
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.0.0
  build_runner: ^2.0.0
```

### Mocks
```dart
@GenerateMocks([PlatoService, FirebaseFirestore])
void main() {}
```

## Datos de Prueba

### test/data/test_data.dart
```dart
class TestData {
  static final testPlato = Plato(
    id: 'test-id',
    nombre: 'Test Plato',
    descripcion: 'Test Description',
    costoTotal: 100.0,
    precioVenta: 150.0,
    categorias: ['Test'],
    intermedios: [],
    activo: true,
  );

  static final testEvento = Evento(
    id: 'test-event-id',
    nombre: 'Test Event',
    fecha: DateTime.now(),
    tipo: TipoEvento.privado,
    estado: EstadoEvento.confirmado,
    platosId: ['test-id'],
  );
}
```

## Cobertura de Código

### Generar Reporte
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Objetivos de Cobertura
- Models: 100%
- Services: 90%
- ViewModels: 90%
- Widgets: 80%
- Screens: 70%

## CI/CD Integration

### GitHub Actions
```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v1
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: VeryGoodOpenSource/very_good_coverage@v1
        with:
          path: coverage/lcov.info
          min_coverage: 80
```

## Best Practices

### 1. Organización
- Tests espejo de la estructura del código
- Un archivo de test por clase
- Nombres descriptivos para tests

### 2. Principios
- Arrange-Act-Assert pattern
- Tests independientes
- Setup y teardown claros
- Mocks para dependencias externas

### 3. Convenciones
```dart
test('should do something when something happens', () {
  // Arrange
  final input = ...;
  
  // Act
  final result = sut.doSomething(input);
  
  // Assert
  expect(result, expectedOutput);
});
```

## Debug y Troubleshooting

### Common Issues
1. Widget tests timing out
   ```dart
   await tester.pump(Duration(seconds: 1));
   ```

2. Mocks no registrados
   ```dart
   @GenerateMocks([
     PlatoService,
     FirebaseFirestore,
   ], customMocks: [
     MockSpec<NavigatorObserver>(returnNullOnMissingStub: true),
   ])
   ```

3. Async operations in tests
   ```dart
   await expectLater(
     stream,
     emitsInOrder([
       emits(1),
       emits(2),
       emitsDone,
     ]),
   );
   ```

## Performance Testing

### Memory Leaks
```dart
testWidgets('should not leak memory', (tester) async {
  await tester.binding.watchPerformance(() async {
    await tester.pumpWidget(MyWidget());
    await tester.pumpAndSettle();
  });
});
```

### Frame Timing
```dart
testWidgets('should maintain 60 FPS', (tester) async {
  final timeline = await tester.traceAction(() async {
    await tester.pumpWidget(MyWidget());
    await tester.pumpAndSettle();
  });
  
  expect(timeline.timestampMicros, lessThan(16667)); // 60 FPS
});
```
