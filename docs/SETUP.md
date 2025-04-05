# Configuración del Entorno de Desarrollo

## Requisitos Previos

### Software Necesario
1. **Flutter SDK**
   - Versión: 3.0.0 o superior
   - [Guía de instalación](https://flutter.dev/docs/get-started/install)

2. **Dart SDK**
   - Versión: 2.17.0 o superior
   - Incluido con Flutter SDK

3. **Android Studio**
   - Versión: 2021.2.1 o superior
   - Plugins requeridos:
     * Flutter
     * Dart
     * Firebase Tools

4. **VS Code** (Opcional)
   - Extensiones recomendadas:
     * Flutter
     * Dart
     * Firebase Explorer
     * Git History
     * Error Lens

5. **Git**
   - Versión: 2.30.0 o superior

6. **Node.js**
   - Versión: 14.x o superior
   - Necesario para Firebase Tools

### Configuración de Firebase

1. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Proyecto Firebase**
   - Crear nuevo proyecto en [Firebase Console](https://console.firebase.google.com)
   - Habilitar servicios:
     * Authentication
     * Firestore
     * Storage
     * Functions

3. **Configuración de Flutter**
   ```bash
   flutter pub add firebase_core
   flutter pub add firebase_auth
   flutter pub add cloud_firestore
   flutter pub add firebase_storage
   ```

## Configuración del Proyecto

### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/golo_app.git
cd golo_app
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase
```bash
flutterfire configure
```

### 4. Variables de Entorno
1. Crear archivo `.env`:
   ```env
   FIREBASE_API_KEY=tu_api_key
   FIREBASE_PROJECT_ID=tu_project_id
   FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
   ```

2. Configurar en `lib/core/config.dart`:
   ```dart
   class Config {
     static String apiKey = dotenv.env['FIREBASE_API_KEY']!;
     static String projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
   }
   ```

## Estructura del Proyecto

```
golo_app/
├── android/
├── ios/
├── lib/
│   ├── core/
│   ├── models/
│   ├── services/
│   ├── viewmodels/
│   └── ui/
├── test/
├── docs/
└── pubspec.yaml
```

## Configuración de VS Code

### settings.json
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.lineLength": 80,
  "dart.previewFlutterUiGuides": true
}
```

### launch.json
```json
{
  "configurations": [
    {
      "name": "Golo App (Development)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": ["--flavor", "development"]
    },
    {
      "name": "Golo App (Production)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": ["--flavor", "production"]
    }
  ]
}
```

## Scripts Útiles

### 1. Limpieza del Proyecto
```bash
# Limpiar caché y archivos generados
flutter clean

# Obtener dependencias nuevamente
flutter pub get
```

### 2. Generación de Código
```bash
# Ejecutar build_runner
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Tests
```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage
```

## Configuración de Firebase Local

### 1. Firebase Emulators
```bash
# Instalar emuladores
firebase init emulators

# Iniciar emuladores
firebase emulators:start
```

### 2. Configuración en la App
```dart
void main() async {
  if (kDebugMode) {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  runApp(MyApp());
}
```

## Solución de Problemas Comunes

### 1. Problemas de Dependencias
```bash
flutter pub cache repair
flutter pub get
```

### 2. Problemas de Android Studio
- Invalidar cachés: File > Invalidate Caches
- Sincronizar proyecto con Gradle

### 3. Problemas de Firebase
- Verificar configuración en `google-services.json`
- Comprobar reglas de Firestore
- Validar permisos de usuario

## CI/CD

### GitHub Actions
```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v1
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk
```

## Guías de Estilo

### 1. Dart
- Seguir [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Usar análisis estático estricto

### 2. Flutter
- Widgets pequeños y reutilizables
- Separación de concerns
- Uso de const cuando sea posible

## Recursos Adicionales

### Documentación
- [Flutter Dev](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Dart Dev](https://dart.dev/guides)

### Herramientas
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Firebase Console](https://console.firebase.google.com)
- [Pub.dev](https://pub.dev)
