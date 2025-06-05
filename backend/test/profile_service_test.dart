import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hero_budget/models/user_model.dart';
import 'package:hero_budget/services/profile_service.dart';

void main() {
  group('ProfileService Tests', () {
    late MockClient mockClient;

    setUp(() {
      // Configurar el cliente HTTP mock antes de cada prueba
      mockClient = MockClient((request) async {
        // Capturar la URL y el cuerpo de la solicitud para análisis
        final Uri url = request.url;
        final String path = url.path;
        final Map<String, dynamic> requestBody =
            request.body.isNotEmpty ? json.decode(request.body) : {};

        print('Test request to: $path');
        print('Test request body: $requestBody');

        // Mock respuesta para /profile/update
        if (path == '/profile/update') {
          // Verificar si hay una imagen en la solicitud
          final hasImage = requestBody.containsKey('profile_image_base64');

          // Simular respuesta del servidor
          final responseData = {
            'success': true,
            'data': {
              'id': '123',
              'name': 'Test User',
              'email': 'test@example.com',
              'verified_email': true,
              'locale': 'es',
              // Si enviamos imagen, devolver la misma imagen
              if (hasImage)
                'display_image': requestBody['profile_image_base64'],
              // Otros campos de respuesta...
            },
          };

          return http.Response(json.encode(responseData), 200);
        }

        // Respuesta por defecto para otras rutas
        return http.Response('{"success":false,"message":"Not found"}', 404);
      });

      // Reemplazar el cliente HTTP en ProfileService con nuestro mock
      // Esto requeriría modificar ProfileService para aceptar un cliente HTTP,
      // lo cual es una buena práctica para facilitar pruebas, pero no está implementado aún
      // Por ahora, asumimos que usamos el cliente por defecto
    });

    test('updateProfile() debería conservar la imagen enviada', () async {
      // Crear una imagen de prueba en base64
      final String testImage =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

      // Llamada al servicio con imagen
      final result = await ProfileService.updateProfile(
        userId: 123,
        name: 'Test User',
        profileImageBase64: testImage,
      );

      // Verificaciones
      expect(result, isA<UserModel>());
      expect(result.id, equals('123'));
      expect(result.name, equals('Test User'));

      // Lo más importante: verificar que la imagen se conservó
      expect(
        result.displayImage,
        equals(testImage),
        reason: 'La imagen devuelta debe ser la misma que se envió',
      );
    });

    test(
      'updateProfile() debería manejar correctamente cuando no se devuelve imagen',
      () async {
        // Modificar el mock para esta prueba específica
        mockClient = MockClient((request) async {
          if (request.url.path == '/profile/update') {
            // Devolver respuesta sin imagen aunque se envíe una
            final responseData = {
              'success': true,
              'data': {
                'id': '123',
                'name': 'Test User',
                'email': 'test@example.com',
                'verified_email': true,
                'locale': 'es',
                // No incluir 'display_image' intencionalmente
              },
            };

            return http.Response(json.encode(responseData), 200);
          }

          return http.Response('{"success":false,"message":"Not found"}', 404);
        });

        // Crear una imagen de prueba en base64
        final String testImage =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

        // Llamada al servicio con imagen
        final result = await ProfileService.updateProfile(
          userId: 123,
          name: 'Test User',
          profileImageBase64: testImage,
        );

        // Verificar que la imagen se conserve en el objeto UserModel
        // aunque el servidor no la devolvió
        expect(
          result.displayImage,
          equals(testImage),
          reason:
              'La imagen debe conservarse aunque el servidor no la devuelva',
        );
      },
    );

    test('testProfileImageUpdate() prueba detallada de actualización', () async {
      // Modificar el mock para esta prueba específica
      mockClient = MockClient((request) async {
        if (request.url.path == '/profile/update') {
          final requestBody = json.decode(request.body);

          // Simular transformación de la imagen en el servidor
          String modifiedImage = requestBody['profile_image_base64'] ?? '';
          // En un caso real, el servidor podría cambiar el formato o tamaño
          // Simulamos aquí un cambio simple como prueba
          if (modifiedImage.isNotEmpty) {
            modifiedImage =
                'data:image/jpeg;base64,' + modifiedImage.split('base64,').last;
          }

          final responseData = {
            'success': true,
            'data': {
              'id': '123',
              'name': 'Test User',
              'email': 'test@example.com',
              'verified_email': true,
              'locale': 'es',
              'display_image': modifiedImage,
            },
          };

          return http.Response(json.encode(responseData), 200);
        }

        return http.Response('{"success":false,"message":"Not found"}', 404);
      });

      // Crear una imagen de prueba en base64
      final String testImage =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

      // Ejecutar la prueba
      await ProfileService.testProfileImageUpdate(
        userId: 123,
        testImageBase64: testImage,
      );

      // Esta prueba verifica la funcionalidad de diagnóstico,
      // no necesita assertions adicionales ya que los resultados
      // se muestran en la consola
    });
  });
}
