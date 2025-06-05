# Guía de Configuración Flutter - Conexión con Backend Desplegado

Esta guía te ayudará a modificar tu aplicación Flutter para conectar con el backend desplegado en `https://herobudget.jaimedigitalstudio.com`.

## Paso 1: Actualizar Configuración de API

### 1.1 Modificar `lib/config/api_config.dart`

Este es el archivo principal que necesitas modificar para cambiar todas las URLs del backend.

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuración para producción
  static String get baseApiUrl {
    if (kDebugMode) {
      // En modo debug, usar localhost para desarrollo
      return 'http://localhost';
    } else {
      // En modo release, usar el dominio de producción
      return 'https://herobudget.jaimedigitalstudio.com';
    }
  }

  // Método alternativo para forzar producción durante testing
  static String get productionApiUrl {
    return 'https://herobudget.jaimedigitalstudio.com';
  }

  // Método para desarrollo local
  static String get developmentApiUrl {
    return 'http://localhost';
  }

  // Helper method to detect if we're running on a simulator
  static bool isRunningOnSimulator() {
    try {
      return Platform.isIOS &&
          !Platform.environment.containsKey('FLUTTER_TEST') &&
          Platform.operatingSystemVersion.toLowerCase().contains('simulator');
    } catch (e) {
      print('Error detecting simulator: $e');
      return false;
    }
  }

  // Service ports (solo se usan en desarrollo local)
  static const int signupServicePort = 8082;
  static const int languageServicePort = 8083;
  static const int signinServicePort = 8084;
  static const int googleAuthServicePort = 8081;
  static const int fetchDashboardServicePort = 8085;
  static const int resetPasswordServicePort = 8086;
  static const int dashboardDataServicePort = 8087;
  static const int budgetManagementServicePort = 8088;
  static const int savingsManagementServicePort = 8089;
  static const int cashBankManagementServicePort = 8090;
  static const int billsManagementServicePort = 8091;
  static const int incomeManagementServicePort = 8093;
  static const int expenseManagementServicePort = 8094;
  static const int categoriesManagementServicePort = 8095;
  static const int budgetOverviewFetchServicePort = 8097;

  // Service endpoints - Actualizados para producción
  static String get signupServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$signupServicePort';
    } else {
      return '$productionApiUrl/signup';
    }
  }

  static String get languageServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$languageServicePort';
    } else {
      return '$productionApiUrl/language';
    }
  }

  static String get signinServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$signinServicePort';
    } else {
      return '$productionApiUrl/signin';
    }
  }

  static String get googleAuthServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$googleAuthServicePort';
    } else {
      return '$productionApiUrl';
    }
  }

  static String get fetchDashboardServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$fetchDashboardServicePort';
    } else {
      return '$productionApiUrl/fetch-dashboard';
    }
  }

  static String get resetPasswordServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$resetPasswordServicePort';
    } else {
      return '$productionApiUrl/reset-password';
    }
  }

  static String get dashboardDataServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$dashboardDataServicePort';
    } else {
      return '$productionApiUrl/dashboard-data';
    }
  }

  static String get budgetManagementUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$budgetManagementServicePort';
    } else {
      return '$productionApiUrl/budget';
    }
  }

  static String get savingsManagementUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$savingsManagementServicePort';
    } else {
      return '$productionApiUrl/savings';
    }
  }

  static String get cashBankManagementUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$cashBankManagementServicePort';
    } else {
      return '$productionApiUrl/cash-bank';
    }
  }

  static String get billsManagementUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$billsManagementServicePort';
    } else {
      return '$productionApiUrl/bills';
    }
  }

  static String get incomeManagementServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$incomeManagementServicePort';
    } else {
      return '$productionApiUrl/income';
    }
  }

  static String get expenseManagementServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$expenseManagementServicePort';
    } else {
      return '$productionApiUrl/expense';
    }
  }

  static String get categoriesEndpoint {
    if (kDebugMode) {
      return '$developmentApiUrl:$categoriesManagementServicePort/categories';
    } else {
      return '$productionApiUrl/categories';
    }
  }

  // Money Flow Sync Service (8096)
  static String get moneyFlowSyncServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:8096';
    } else {
      return '$productionApiUrl/money-flow-sync';
    }
  }

  // Budget Overview Fetch Service (8097)
  static String get budgetOverviewFetchServiceUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:$budgetOverviewFetchServicePort';
    } else {
      return '$productionApiUrl/budget-overview';
    }
  }

  // Profile Management Service
  static String get profileManagementUrl {
    if (kDebugMode) {
      return '$developmentApiUrl:8092';
    } else {
      return '$productionApiUrl/profile';
    }
  }
}
```

## Paso 2: Actualizar Servicios con URLs Hardcodeadas

### 2.1 Actualizar `lib/services/profile_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ProfileService {
  // Usar la configuración centralizada en lugar de URL hardcodeada
  static String get _baseUrl => ApiConfig.profileManagementUrl;

  // Resto del código del servicio permanece igual...
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // ... resto de métodos
}
```

### 2.2 Actualizar `lib/services/savings_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SavingsService {
  // Usar la configuración centralizada en lugar de URL hardcodeada
  static String get baseUrl => ApiConfig.savingsManagementUrl;

  // Resto del código del servicio permanece igual...
  static Future<List<Map<String, dynamic>>> getSavings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/savings/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load savings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching savings: $e');
    }
  }

  // ... resto de métodos
}
```

## Paso 3: Configurar Permisos de Red

### 3.1 Android - Actualizar `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.hero_budget">

    <!-- Permisos de internet -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="Hero Budget"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        
        <!-- Configuración para permitir HTTP en debug -->
        <meta-data
            android:name="io.flutter.network.http.usesCleartextTraffic"
            android:value="true" />

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 3.2 iOS - Actualizar `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Configuración existente... -->
    
    <!-- Permitir conexiones HTTP en desarrollo -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
            <key>herobudget.jaimedigitalstudio.com</key>
            <dict>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.0</string>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

## Paso 4: Actualizar Configuración de Google OAuth

### 4.1 Actualizar `backend/google_auth/main.go` en el servidor

En el VPS, necesitas actualizar la URL de callback de Google OAuth:

```bash
# Conectar al VPS
ssh root@178.16.130.178

# Editar el archivo de configuración
cd /opt/hero_budget/backend/google_auth
nano main.go
```

Cambiar la línea:
```go
RedirectURL:  "http://localhost:8081/auth/google/callback",
```

Por:
```go
RedirectURL:  "https://herobudget.jaimedigitalstudio.com/auth/google/callback",
```

### 4.2 Actualizar configuración en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a "APIs & Services" > "Credentials"
4. Edita tu OAuth 2.0 Client ID
5. En "Authorized redirect URIs", agrega:
   - `https://herobudget.jaimedigitalstudio.com/auth/google/callback`

## Paso 5: Crear Configuración de Entorno

### 5.1 Crear `lib/config/environment.dart`

```dart
enum Environment { development, production }

class EnvironmentConfig {
  static const Environment _currentEnvironment = Environment.production;
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  // URLs base según el entorno
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://localhost';
      case Environment.production:
        return 'https://herobudget.jaimedigitalstudio.com';
    }
  }
  
  // Configuración de timeouts
  static Duration get connectionTimeout {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 60);
    }
  }
  
  // Configuración de logs
  static bool get enableLogging {
    switch (_currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.production:
        return false;
    }
  }
}
```

## Paso 6: Actualizar Cliente HTTP

### 6.1 Crear `lib/services/http_client.dart`

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  late http.Client _client;

  void initialize() {
    _client = http.Client();
  }

  http.Client get client => _client;

  // Headers comunes para todas las requests
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'HeroBudget-Flutter/1.0',
  };

  // Método para hacer requests GET con manejo de errores
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
      ).timeout(EnvironmentConfig.connectionTimeout);
      
      if (EnvironmentConfig.enableLogging) {
        print('GET $url - Status: ${response.statusCode}');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Método para hacer requests POST con manejo de errores
  Future<http.Response> post(String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: body,
      ).timeout(EnvironmentConfig.connectionTimeout);
      
      if (EnvironmentConfig.enableLogging) {
        print('POST $url - Status: ${response.statusCode}');
      }
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
```

## Paso 7: Actualizar main.dart

### 7.1 Inicializar servicios en `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'services/http_client.dart';
import 'config/environment.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  HttpClientService().initialize();
  
  // Log del entorno actual
  if (EnvironmentConfig.enableLogging) {
    print('Running in ${EnvironmentConfig.currentEnvironment} mode');
    print('API Base URL: ${EnvironmentConfig.apiBaseUrl}');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero Budget',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

// ... resto del código
```

## Paso 8: Testing y Verificación

### 8.1 Script de testing de conectividad

Crea `lib/utils/connectivity_test.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ConnectivityTest {
  static Future<bool> testBackendConnection() async {
    try {
      // Test de conectividad básica
      final response = await http.get(
        Uri.parse('${ApiConfig.googleAuthServiceUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('Backend connection test - Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 405; // 405 es esperado para GET en POST endpoint
    } catch (e) {
      print('Backend connection test failed: $e');
      return false;
    }
  }

  static Future<Map<String, bool>> testAllServices() async {
    final services = {
      'Google Auth': ApiConfig.googleAuthServiceUrl,
      'Signup': ApiConfig.signupServiceUrl,
      'Signin': ApiConfig.signinServiceUrl,
      'Dashboard': ApiConfig.dashboardDataServiceUrl,
      'Budget': ApiConfig.budgetManagementUrl,
      'Savings': ApiConfig.savingsManagementUrl,
      'Profile': ApiConfig.profileManagementUrl,
    };

    Map<String, bool> results = {};

    for (String serviceName in services.keys) {
      try {
        final response = await http.get(
          Uri.parse(services[serviceName]!),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        results[serviceName] = response.statusCode < 500;
        print('$serviceName: ${results[serviceName] ? "OK" : "FAIL"} (${response.statusCode})');
      } catch (e) {
        results[serviceName] = false;
        print('$serviceName: FAIL ($e)');
      }
    }

    return results;
  }
}
```

### 8.2 Agregar botón de test en desarrollo

En tu pantalla de desarrollo o debug, agrega:

```dart
ElevatedButton(
  onPressed: () async {
    final isConnected = await ConnectivityTest.testBackendConnection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isConnected 
          ? 'Backend connection successful!' 
          : 'Backend connection failed!'),
        backgroundColor: isConnected ? Colors.green : Colors.red,
      ),
    );
  },
  child: Text('Test Backend Connection'),
),
```

## Paso 9: Build y Deploy

### 9.1 Para Android (APK de producción)

```bash
# Limpiar build anterior
flutter clean
flutter pub get

# Build para producción
flutter build apk --release

# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

### 9.2 Para iOS (App Store)

```bash
# Limpiar build anterior
flutter clean
flutter pub get

# Build para iOS
flutter build ios --release

# Abrir en Xcode para firmar y subir
open ios/Runner.xcworkspace
```

## Paso 10: Verificación Final

### 10.1 Checklist de verificación

- [ ] `api_config.dart` actualizado con URLs de producción
- [ ] Servicios individuales actualizados para usar configuración centralizada
- [ ] Permisos de red configurados en Android e iOS
- [ ] Google OAuth callback URL actualizado
- [ ] Variables de entorno configuradas
- [ ] Cliente HTTP con manejo de errores implementado
- [ ] Tests de conectividad funcionando
- [ ] App compilada en modo release
- [ ] Conexión con backend verificada

### 10.2 Comandos de verificación

```bash
# Verificar que el backend esté funcionando
curl -k https://herobudget.jaimedigitalstudio.com/auth/google

# Verificar SSL
openssl s_client -connect herobudget.jaimedigitalstudio.com:443

# Test desde la app
# Usar el botón de test de conectividad en la app
```

## Solución de Problemas Comunes

### Problema: Error de certificado SSL
**Solución**: Verificar que el certificado esté correctamente instalado en el servidor.

### Problema: CORS errors
**Solución**: Verificar que la configuración de Nginx incluya los headers CORS correctos.

### Problema: Timeout en requests
**Solución**: Aumentar el timeout en `EnvironmentConfig.connectionTimeout`.

### Problema: Google OAuth no funciona
**Solución**: Verificar que la URL de callback esté correctamente configurada en Google Cloud Console.

¡Tu aplicación Flutter ahora está configurada para conectar con el backend desplegado en producción! 