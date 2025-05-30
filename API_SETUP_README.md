# 🔧 Hero Budget - Configuración de API

Esta guía te explica cómo configurar Hero Budget para trabajar tanto con servicios locales (localhost) como con servicios de producción.

## 📋 Resumen de Configuración

### 🏠 Localhost (Desarrollo)
- **URL Base**: `http://localhost`
- **Servicios**: Puertos 8081-8097
- **Requisito**: Ejecutar `./start_services.sh`
- **Uso**: Desarrollo y testing local

### 🌐 Producción
- **URL Base**: `https://herobudget.jaimedigitalstudio.com`
- **Servicios**: Endpoints unificados
- **Requisito**: Conexión a internet
- **Uso**: Testing con backend real

## 🚀 Configuración Rápida

### Opción 1: Configuración Manual en main.dart

Edita `lib/main.dart` y descomenta la línea que necesites:

```dart
// Para desarrollo local
ApiConfig.useLocalhost();

// Para producción
ApiConfig.useProduction();
```

### Opción 2: Configuración Dinámica (Recomendada)

Usa los métodos de `ApiConfigurationExample`:

```dart
import 'lib/config/api_config_example.dart';

// En cualquier parte de tu código
ApiConfigurationExample.setupForLocalDevelopment();
// o
ApiConfigurationExample.setupForProduction();
```

## 🛠️ Configuración para Desarrollo Local

### 1. Iniciar Servicios Backend

```bash
# Ejecutar todos los servicios
./start_services.sh

# O servicios específicos
./start_services.sh google_auth signup signin dashboard_data
```

### 2. Configurar Flutter

```dart
// En main.dart o al inicio de tu app
ApiConfig.useLocalhost();

// Verificar configuración
ApiConfig.printCurrentConfig();

// Opcional: Validar que servicios estén corriendo
await ApiConfig.validateLocalServices();
```

### 3. Puertos de Servicios

| Servicio | Puerto | Endpoint Local |
|----------|--------|----------------|
| Google Auth | 8081 | `http://localhost:8081` |
| Signup | 8082 | `http://localhost:8082` |
| Language | 8083 | `http://localhost:8083` |
| Signin | 8084 | `http://localhost:8084` |
| Dashboard | 8085 | `http://localhost:8085` |
| Reset Password | 8086 | `http://localhost:8086` |
| Dashboard Data | 8087 | `http://localhost:8087` |
| Budget Management | 8088 | `http://localhost:8088` |
| Savings Management | 8089 | `http://localhost:8089` |
| Cash Bank Management | 8090 | `http://localhost:8090` |
| Bills Management | 8091 | `http://localhost:8091` |
| Profile Management | 8092 | `http://localhost:8092` |
| Income Management | 8093 | `http://localhost:8093` |
| Expense Management | 8094 | `http://localhost:8094` |
| Categories Management | 8095 | `http://localhost:8095` |
| Money Flow Sync | 8096 | `http://localhost:8096` |
| Budget Overview | 8097 | `http://localhost:8097` |

## 🌐 Configuración para Producción

### 1. Configurar Flutter

```dart
// En main.dart o al inicio de tu app
ApiConfig.useProduction();

// Verificar configuración
ApiConfig.printCurrentConfig();
```

### 2. URLs de Producción

Todos los servicios se acceden a través de:
- **Base URL**: `https://herobudget.jaimedigitalstudio.com`
- **Estructura**: `https://herobudget.jaimedigitalstudio.com/[endpoint]`

## 🔄 Cambio Dinámico de Ambiente

### Durante el Desarrollo

```dart
// Cambiar rápidamente entre ambientes
ApiConfig.quickEnvironmentSwitch();

// Verificar estado actual
ApiConfigurationExample.checkCurrentConfiguration();
```

### Widget de Debug (Opcional)

Puedes añadir un widget para cambiar ambiente desde la UI:

```dart
class DebugApiScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Configuration')),
      body: Column(
        children: [
          // Mostrar configuración actual
          ApiConfigurationExample.buildConfigWidget(),
          
          // Botón para cambiar ambiente
          ElevatedButton(
            onPressed: () {
              ApiConfigurationExample.toggleEnvironment();
              setState(() {}); // Actualizar UI
            },
            child: Text('Cambiar Ambiente'),
          ),
          
          // Validar servicios locales
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.validateLocalServices();
            },
            child: Text('Validar Servicios Locales'),
          ),
        ],
      ),
    );
  }
}
```

## 🐛 Troubleshooting

### Problema: Servicios locales no responden

```bash
# Verificar que los servicios estén corriendo
ps aux | grep -E "(google_auth|signup|signin)" 

# Verificar puertos ocupados
lsof -i :8081-8097

# Reiniciar servicios
./stop_services.sh
./start_services.sh
```

### Problema: Configuración no se aplica

```dart
// Forzar configuración
EnvironmentConfig.forceLocalDevelopment(); // o forceProduction()
ApiHelper.initialize(); // Reinicializar helper

// Verificar configuración
EnvironmentConfig.printFullApiConfig();
```

### Problema: Conexión rechazada en localhost

1. Verificar que `start_services.sh` se ejecutó correctamente
2. Verificar que no hay firewall bloqueando puertos
3. Usar la validación automática:

```dart
await ApiConfig.validateLocalServices();
```

## 📱 Configuración por Plataforma

### Android/iOS (Physical Device)
- Localhost funciona normalmente
- Producción funciona normalmente

### Android/iOS (Emulator/Simulator)
- Localhost: Puede requerir configuración de red
- Producción: Funciona normalmente

### Web
- Localhost: Posibles problemas de CORS
- Producción: Funciona normalmente

## 🔒 Configuración de Seguridad

### Desarrollo
- Logging habilitado
- Debug mode activo
- Validaciones relajadas

### Producción
- Logging deshabilitado
- Release mode
- Validaciones estrictas

## 📋 Checklist de Configuración

### Para Desarrollo Local:
- [ ] Backend services corriendo (`./start_services.sh`)
- [ ] `ApiConfig.useLocalhost()` configurado
- [ ] Puertos 8081-8097 disponibles
- [ ] Validación de servicios ejecutada

### Para Producción:
- [ ] `ApiConfig.useProduction()` configurado
- [ ] Conexión a internet disponible
- [ ] URL base correcta en environment.dart

### Para Release:
- [ ] Configuración de producción activa
- [ ] Logging deshabilitado
- [ ] Build en modo release

## 🆘 Comandos Útiles

```dart
// Ver configuración actual
ApiConfig.printCurrentConfig();

// Ver información completa del ambiente
EnvironmentConfig.printFullApiConfig();

// Ver todos los endpoints disponibles
print(ApiConfig.allEndpoints);

// Cambiar ambiente
ApiConfig.useLocalhost(); // o useProduction()

// Validar servicios locales
await ApiConfig.validateLocalServices();

// Cambio rápido de ambiente
ApiConfig.quickEnvironmentSwitch();
```

---

## 📞 Soporte

Si tienes problemas con la configuración:

1. Revisa que `start_services.sh` esté funcionando
2. Verifica la configuración con `ApiConfig.printCurrentConfig()`
3. Usa `ApiConfig.validateLocalServices()` para diagnóstico
4. Revisa los logs en la consola de Flutter

¡Happy coding! 🚀 