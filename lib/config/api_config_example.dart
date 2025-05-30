// lib/config/api_config_example.dart
//
// ARCHIVO DE EJEMPLO - USO DE LA CONFIGURACIÓN DE API
//
// Este archivo muestra cómo configurar y usar las APIs tanto para
// desarrollo local (localhost) como para producción.

import 'package:flutter/material.dart';
import 'api_config.dart';
import 'environment.dart';

class ApiConfigurationExample {
  /// EJEMPLO 1: Configuración para desarrollo local
  ///
  /// Llama este método cuando quieras desarrollar usando los servicios
  /// locales que se ejecutan con start_services.sh
  static void setupForLocalDevelopment() {
    print('🏠 Setting up for LOCAL DEVELOPMENT');

    // Configurar para usar localhost
    ApiConfig.useLocalhost();

    // Verificar la configuración actual
    ApiConfig.printCurrentConfig();

    // Opcional: Validar que los servicios estén corriendo
    // ApiConfig.validateLocalServices();
  }

  /// EJEMPLO 2: Configuración para producción
  ///
  /// Llama este método cuando quieras probar con el backend real
  /// en https://herobudget.jaimedigitalstudio.com
  static void setupForProduction() {
    print('🌐 Setting up for PRODUCTION');

    // Configurar para usar producción
    ApiConfig.useProduction();

    // Verificar la configuración actual
    ApiConfig.printCurrentConfig();
  }

  /// EJEMPLO 3: Cambio rápido entre ambientes
  ///
  /// Útil durante el desarrollo para probar ambos backends
  static void toggleEnvironment() {
    print('🔄 Toggling environment...');
    ApiConfig.quickEnvironmentSwitch();
  }

  /// EJEMPLO 4: Verificar estado actual
  static void checkCurrentConfiguration() {
    print('\n📊 CURRENT CONFIGURATION:');
    EnvironmentConfig.printFullApiConfig();

    print('\n🔗 Available Endpoints:');
    final endpoints = ApiConfig.allEndpoints;
    endpoints.forEach((key, value) {
      print('$key: $value');
    });
  }

  /// EJEMPLO 5: Widget que muestra la configuración actual
  static Widget buildConfigWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            EnvironmentConfig.isDevelopment
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        border: Border.all(
          color: EnvironmentConfig.isDevelopment ? Colors.green : Colors.blue,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                EnvironmentConfig.isDevelopment
                    ? Icons.developer_mode
                    : Icons.cloud,
                color:
                    EnvironmentConfig.isDevelopment
                        ? Colors.green
                        : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                EnvironmentConfig.isDevelopment
                    ? 'DESARROLLO (Localhost)'
                    : 'PRODUCCIÓN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Base URL: ${EnvironmentConfig.baseUrl}'),
          if (EnvironmentConfig.isDevelopment) ...[
            const SizedBox(height: 4),
            const Text(
              'Los servicios deben estar corriendo con start_services.sh',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

// EJEMPLO DE USO EN MAIN.DART:
//
// void main() {
//   // Configurar ambiente antes de iniciar la app
//   
//   // Para desarrollo local:
//   ApiConfigurationExample.setupForLocalDevelopment();
//   
//   // O para producción:
//   // ApiConfigurationExample.setupForProduction();
//   
//   runApp(MyApp());
// }

// EJEMPLO DE USO EN UN WIDGET:
//
// class DebugScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('API Configuration')),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Mostrar configuración actual
//             ApiConfigurationExample.buildConfigWidget(),
//             
//             SizedBox(height: 20),
//             
//             // Botón para cambiar ambiente
//             ElevatedButton(
//               onPressed: () {
//                 ApiConfigurationExample.toggleEnvironment();
//                 // Reconstruir el widget para mostrar cambios
//                 (context as Element).markNeedsBuild();
//               },
//               child: Text('Cambiar Ambiente'),
//             ),
//             
//             // Botón para validar servicios locales
//             if (EnvironmentConfig.isDevelopment)
//               ElevatedButton(
//                 onPressed: () async {
//                   await ApiConfig.validateLocalServices();
//                 },
//                 child: Text('Validar Servicios Locales'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// } 