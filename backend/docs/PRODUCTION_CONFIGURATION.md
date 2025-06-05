# Configuración de Producción - Hero Budget Flutter

Esta guía explica cómo funciona el sistema de configuración de ambientes en Hero Budget y cómo cambiar entre desarrollo y producción.

## 🔧 Sistema de Configuración

La aplicación utiliza un sistema automático de detección de ambiente basado en el modo de compilación de Flutter:

### Ambientes Disponibles

1. **Development** (`Environment.development`)
   - URL Backend: `http://localhost` con puertos específicos
   - Logging habilitado
   - Debug mode activo
   - Timeouts más largos

2. **Production** (`Environment.production`)
   - URL Backend: `https://herobudget.jaimedigitalstudio.com`
   - Logging mínimo
   - Optimizado para rendimiento
   - Timeouts más cortos

3. **Staging** (`Environment.staging`)
   - URL Backend: `https://staging.herobudget.jaimedigitalstudio.com` (futuro)
   - Configuración intermedia

## 🚀 Detección Automática de Ambiente

### Por Defecto
- **Debug Mode** (`flutter run`): Ambiente de desarrollo
- **Release Mode** (`flutter build apk --release`): Ambiente de producción

### URLs Generadas Automáticamente

#### En Desarrollo (Debug Mode)
```
Signup: http://localhost:8082/signup
Signin: http://localhost:8084/signin
Google Auth: http://localhost:8081/auth/google
Dashboard: http://localhost:8085/fetch-dashboard
Budget: http://localhost:8088/budget
... (etc)
```

#### En Producción (Release Mode)
```
Signup: https://herobudget.jaimedigitalstudio.com/signup
Signin: https://herobudget.jaimedigitalstudio.com/signin
Google Auth: https://herobudget.jaimedigitalstudio.com/auth/google
Dashboard: https://herobudget.jaimedigitalstudio.com/fetch-dashboard
Budget: https://herobudget.jaimedigitalstudio.com/budget
... (etc)
```

## ⚙️ Configuración Manual (para Testing)

Si necesitas forzar un ambiente específico en debug mode, puedes hacerlo en `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DESCOMENTA LA SIGUIENTE LÍNEA PARA FORZAR PRODUCCIÓN EN DEBUG
  // EnvironmentConfig.setEnvironment(Environment.production);
  
  // ... resto del código
}
```

## 📱 Comandos de Compilación

### Para Desarrollo
```bash
# Correr en modo debug (automáticamente usa localhost)
flutter run

# Correr en modo debug con hot reload
flutter run --debug
```

### Para Producción

#### Android
```bash
# Generar APK de producción
flutter build apk --release

# Generar App Bundle para Google Play
flutter build appbundle --release

# Instalar APK de producción para testing
flutter install --release
```

#### iOS
```bash
# Generar build de producción para iOS
flutter build ios --release

# Generar build para App Store
flutter build ipa --release
```

## 🔍 Verificación de Configuración

### En los Logs de la App
Cuando inicies la app en debug mode, verás información como:

```
=== HERO BUDGET APP STARTUP ===
=== Environment Configuration ===
environment: development
baseUrl: http://localhost
isProduction: false
isDevelopment: true
enableLogging: true
enableDebugMode: true
================================
=== API Configuration ===
Signup URL: http://localhost:8082/signup
Signin URL: http://localhost:8084/signin
Google Auth URL: http://localhost:8081/auth/google
...
```

### Programáticamente
```dart
import 'config/environment.dart';
import 'config/api_config.dart';

// Verificar ambiente actual
print('Ambiente: ${EnvironmentConfig.currentEnvironment}');
print('Es producción: ${EnvironmentConfig.isProduction}');
print('Base URL: ${ApiConfig.baseApiUrl}');

// Ver todos los endpoints
ApiConfig.allEndpoints.forEach((service, url) {
  print('$service: $url');
});
```

## 🔧 Configuraciones por Ambiente

### Timeouts de Red
- **Desarrollo**: 60 segundos
- **Staging**: 45 segundos  
- **Producción**: 30 segundos

### Reintentos
- **Desarrollo**: 1 reintento
- **Staging**: 2 reintentos
- **Producción**: 3 reintentos

### Logging
- **Desarrollo**: Logging completo + requests HTTP
- **Staging**: Logging básico
- **Producción**: Solo errores críticos

### Headers HTTP
- **Desarrollo**: Incluye `X-Debug-Mode: true`
- **Producción**: Incluye `X-Client-Version: 1.0.0`

## 🚨 Importante para Despliegue

### Antes de Publicar en Stores

1. **Verificar que esté en Release Mode**:
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

2. **Verificar URLs en los logs**:
   - Debe mostrar `https://herobudget.jaimedigitalstudio.com`
   - NO debe mostrar `localhost`

3. **Testing en Release**:
   ```bash
   # Android - instalar APK de producción
   flutter install --release
   
   # Verificar que se conecte al servidor correcto
   ```

### Variables de Entorno de Producción

Si tu backend requiere configuraciones adicionales en producción, puedes agregar:

```dart
// lib/config/app_config.dart
static String get apiKey {
  switch (EnvironmentConfig.currentEnvironment) {
    case Environment.production:
      return 'tu-api-key-de-produccion';
    case Environment.development:
      return 'tu-api-key-de-desarrollo';
    // ...
  }
}
```

## 🔄 Migración desde Configuración Anterior

El sistema anterior que usaba solo `localhost` ha sido reemplazado por este sistema automático. No necesitas hacer cambios manuales en tu código existente - todo funciona automáticamente según el modo de compilación.

## 🐛 Debugging

### Problemas Comunes

1. **App se conecta a localhost en producción**:
   - Verifica que estés usando `flutter build --release`
   - No `flutter run` para producción

2. **Timeouts en desarrollo**:
   - Asegúrate de que tu backend local esté corriendo
   - Verifica que los puertos estén disponibles

3. **Errores CORS en producción**:
   - Verifica que tu backend en producción tenga CORS configurado
   - Verifica que las URLs en Nginx estén correctas

### Logs de Debug

Para ver más información de debug, busca en los logs:
- `API GET/POST/PUT/DELETE: [URL]` - Requests HTTP
- `API Response [código]: [URL]` - Respuestas HTTP  
- `Environment: production/development` - Ambiente actual

¡Tu app ahora cambia automáticamente entre desarrollo y producción sin necesidad de modificar código! 🎉 