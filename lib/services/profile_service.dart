import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/signin_service.dart';

/// Servicio para manejar las operaciones relacionadas con el perfil del usuario
class ProfileService {
  // URL base del servicio de gestión de perfiles
  static const String _baseUrl = 'http://localhost:8092';

  /// Actualiza el perfil del usuario con nueva información
  ///
  /// Recibe el ID del usuario, nombre, nombre propio, apellido y una imagen opcional en base64
  /// Devuelve un [UserModel] actualizado si la operación es exitosa o lanza una excepción
  static Future<UserModel> updateProfile({
    required int userId,
    String? name,
    String? givenName,
    String? familyName,
    String? profileImageBase64,
  }) async {
    try {
      // Preparar la URL del endpoint
      final Uri uri = Uri.parse('$_baseUrl/profile/update');

      // Registro inicial para depuración
      if (kDebugMode) {
        print(
          'ProfileService.updateProfile: Preparando actualización para usuario $userId',
        );
        if (profileImageBase64 != null) {
          print(
            'ProfileService.updateProfile: Con imagen (tamaño: ${profileImageBase64.length})',
          );
        }
      }

      // Construir el cuerpo de la solicitud con los campos no nulos
      final Map<String, dynamic> requestBody = {'user_id': userId};

      if (name != null && name.isNotEmpty) {
        requestBody['name'] = name;
      }

      if (givenName != null && givenName.isNotEmpty) {
        requestBody['given_name'] = givenName;
      }

      if (familyName != null && familyName.isNotEmpty) {
        requestBody['family_name'] = familyName;
      }

      if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
        // Asegurar que la imagen base64 no tenga prefijos
        String cleanImage = profileImageBase64;
        if (profileImageBase64.contains(';base64,')) {
          cleanImage = profileImageBase64.split(';base64,')[1];
        }
        requestBody['profile_image_base64'] = cleanImage;
      }

      // Convertir a JSON
      final String jsonBody = jsonEncode(requestBody);

      if (kDebugMode) {
        print('ProfileService.updateProfile: Enviando solicitud a $uri');
        print(
          'ProfileService.updateProfile: Campos incluidos: ${requestBody.keys.join(', ')}',
        );
      }

      // Enviar la solicitud
      final http.Response response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      // Verificar la respuesta
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          if (kDebugMode) {
            print('ProfileService.updateProfile: Actualización exitosa');
            print('ProfileService.updateProfile: Respuesta: ${response.body}');
          }

          // Parsear el usuario actualizado de la respuesta
          if (jsonResponse['data'] != null) {
            final UserModel updatedUser = UserModel.fromJson(
              jsonResponse['data'],
            );

            // Log extra para verificar la imagen en el usuario devuelto
            if (kDebugMode) {
              if (updatedUser.displayImage != null) {
                print(
                  'ProfileService.updateProfile: Usuario devuelto incluye imagen de tamaño: ${updatedUser.displayImage!.length}',
                );
              } else {
                print(
                  'ProfileService.updateProfile: Usuario devuelto NO incluye imagen',
                );
              }
            }

            return updatedUser;
          } else {
            throw Exception(
              'No se devolvieron datos de usuario en la respuesta',
            );
          }
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        if (kDebugMode) {
          print('ProfileService.updateProfile: Error ${response.statusCode}');
          print('ProfileService.updateProfile: Cuerpo: ${response.body}');
        }
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileService.updateProfile: Excepción: $e');
      }
      rethrow;
    }
  }

  /// Actualiza la contraseña del usuario
  ///
  /// Recibe el ID del usuario, contraseña actual y nueva contraseña
  /// Devuelve true si la operación es exitosa o lanza una excepción
  static Future<bool> updatePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/profile/update-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
            data['message'] ?? 'Error al actualizar la contraseña',
          );
        }
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error actualizando contraseña: $e');
      }
      rethrow;
    }
  }

  /// Convierte un archivo de imagen a una cadena base64
  ///
  /// Útil para enviar imágenes al servidor
  static Future<String> imageFileToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error convirtiendo imagen a base64: $e');
      }
      rethrow;
    }
  }

  /// Sincroniza los datos del usuario en el almacenamiento local
  ///
  /// Este método es útil para asegurarse de que los datos locales
  /// estén sincronizados con los del servidor después de actualizaciones
  static Future<void> syncUserLocalData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SignInService.userDataKey,
        jsonEncode(user.toJson()),
      );

      if (kDebugMode) {
        print(
          'ProfileService.syncUserLocalData: Datos del usuario sincronizados localmente',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'ProfileService.syncUserLocalData: Error sincronizando datos: $e',
        );
      }
    }
  }

  /// Verifica si el servicio de perfil está disponible
  ///
  /// Devuelve true si el servicio responde correctamente
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/profile/ping'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Método específico para probar la actualización de la imagen de perfil
  ///
  /// Este método se comunica con un endpoint específico de prueba que ofrece más
  /// información de depuración sobre el proceso de actualización de imágenes
  static Future<UserModel> testProfileImageUpdate({
    required int userId,
    required String testImageBase64,
  }) async {
    try {
      // Usar el nuevo endpoint específico para pruebas
      final Uri uri = Uri.parse('$_baseUrl/profile/test-image-update');

      if (kDebugMode) {
        print(
          'ProfileService.testProfileImageUpdate: Iniciando test para usuario $userId',
        );
        print(
          'ProfileService.testProfileImageUpdate: Tamaño de imagen de prueba: ${testImageBase64.length}',
        );
      }

      // Preparar cuerpo de la solicitud
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'profile_image_base64': testImageBase64,
      };

      // Enviar la solicitud
      final http.Response response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Procesar la respuesta
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (kDebugMode) {
          print(
            'ProfileService.testProfileImageUpdate: Respuesta: ${response.body}',
          );
        }

        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            final UserModel updatedUser = UserModel.fromJson(
              jsonResponse['data'],
            );
            return updatedUser;
          } else {
            throw Exception(
              'No hay datos de usuario en la respuesta de prueba',
            );
          }
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error en la prueba');
        }
      } else {
        if (kDebugMode) {
          print(
            'ProfileService.testProfileImageUpdate: Error ${response.statusCode}',
          );
          print(
            'ProfileService.testProfileImageUpdate: Cuerpo: ${response.body}',
          );
        }
        throw Exception(
          'Error en la prueba ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileService.testProfileImageUpdate: Excepción: $e');
      }
      rethrow;
    }
  }
}
