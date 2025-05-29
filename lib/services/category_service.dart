import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../config/api_config.dart';
import '../utils/emoji_utils.dart';
import 'api_helper.dart';

// Excepciones específicas para este servicio
class NotAuthenticatedException implements Exception {
  final String message;
  NotAuthenticatedException(this.message);
  @override
  String toString() => message;
}

class CategoryService {
  // URL base para el servicio de categorías
  final String _baseUrl = ApiConfig.categoriesEndpoint;

  // Método para obtener todas las categorías del usuario
  Future<List<Category>> fetchCategories({String? type}) async {
    try {
      // Obtener el ID de usuario almacenado
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw NotAuthenticatedException('Usuario no autenticado');
      }

      // Construir URL con parámetros
      var url = '$_baseUrl?user_id=$userId';
      if (type != null && type.isNotEmpty) {
        url += '&type=$type';
      }

      // Debug: Print the URL and base URL for debugging
      print('DEBUG - Base URL: $_baseUrl');
      print('DEBUG - Full URL being called: $url');

      // Usar ApiHelper para la solicitud HTTP con manejo UTF-8 correcto
      final jsonData = await ApiHelper.get(url);

      // Debug: Print the response for debugging
      print('DEBUG - Datos recibidos correctamente con ApiHelper');

      // Verificar el código de éxito
      if (jsonData['success'] == true) {
        // Manejar caso donde data es null (usuario no tiene categorías)
        if (jsonData['data'] == null) {
          return []; // Devolver lista vacía
        }

        final categoriesJson = jsonData['data'] as List;
        return categoriesJson.map((json) => Category.fromJson(json)).toList();
      } else {
        throw ApiException(
          statusCode: 400,
          message: jsonData['message'] ?? 'Error al obtener categorías',
          url: url,
        );
      }
    } catch (e) {
      // Debug: Print any exceptions
      print('DEBUG - Exception caught: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: $e',
        url: _baseUrl,
      );
    }
  }

  // Método para añadir una nueva categoría
  Future<Category> addCategory(Category category) async {
    try {
      // Obtener el ID de usuario almacenado
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw NotAuthenticatedException('Usuario no autenticado');
      }

      // Asegurar que el emoji esté codificado
      String encodedEmoji = EmojiUtils.prepareForStorage(category.emoji);

      // Crear una copia de la categoría con el ID de usuario y emoji codificado
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'name': category.name,
        'type': category.type,
        'emoji': encodedEmoji,
      };

      // URL for add endpoint
      final String url = '$_baseUrl/add';
      print('DEBUG - Add category URL: $url');
      print('DEBUG - Request body: $requestBody');

      // Usar ApiHelper para la solicitud HTTP con manejo UTF-8 correcto
      final jsonData = await ApiHelper.postJson(url, requestBody);

      print('DEBUG - Add response procesada correctamente');

      // Verificar el código de éxito
      if (jsonData['success'] == true) {
        return Category.fromJson(jsonData['data']);
      } else {
        throw ApiException(
          statusCode: 400,
          message: jsonData['message'] ?? 'Error al añadir categoría',
          url: url,
        );
      }
    } catch (e) {
      print('DEBUG - Add category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: $e',
        url: _baseUrl,
      );
    }
  }

  // Método para actualizar una categoría existente
  Future<Category> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de categoría no proporcionado',
          url: _baseUrl,
        );
      }

      // Obtener el ID de usuario almacenado
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw NotAuthenticatedException('Usuario no autenticado');
      }

      // Asegurar que el emoji esté codificado
      String encodedEmoji = EmojiUtils.prepareForStorage(category.emoji);

      // Preparar el cuerpo de la solicitud
      final requestBody = {
        'user_id': userId,
        'category_id': category.id,
        'name': category.name,
        'type': category.type,
        'emoji': encodedEmoji,
      };

      // Logs detallados para depurar problema de emoji
      print('DEBUG - Solicitud de actualización:');
      print('DEBUG - ID: ${category.id}');
      print('DEBUG - Nombre: ${category.name}');
      print('DEBUG - Tipo: ${category.type}');
      print('DEBUG - Emoji (objeto Category): ${category.emoji}');
      print('DEBUG - Emoji codificado: $encodedEmoji');
      print('DEBUG - requestBody completo: $requestBody');

      // URL for update endpoint
      final String url = '$_baseUrl/update';
      print('DEBUG - Update category URL: $url');

      // Usar ApiHelper para la solicitud HTTP con manejo UTF-8 correcto
      final jsonData = await ApiHelper.postJson(url, requestBody);

      print('DEBUG - Update response procesada correctamente');

      // Verificar el código de éxito
      if (jsonData['success'] == true) {
        final updatedCategory = Category.fromJson(jsonData['data']);

        // Verificar que el emoji se actualizó correctamente
        print(
          'DEBUG - Emoji actualizado recibido del servidor: ${updatedCategory.emoji}',
        );
        print(
          'DEBUG - ¿Coincide con el enviado? ${updatedCategory.emoji == category.emoji}',
        );

        return updatedCategory;
      } else {
        throw ApiException(
          statusCode: 400,
          message: jsonData['message'] ?? 'Error al actualizar categoría',
          url: url,
        );
      }
    } catch (e) {
      print('DEBUG - Update category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: $e',
        url: _baseUrl,
      );
    }
  }

  // Método para eliminar una categoría
  Future<void> deleteCategory(int categoryId) async {
    try {
      // Obtener el ID de usuario almacenado
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw NotAuthenticatedException('Usuario no autenticado');
      }

      // Preparar el cuerpo de la solicitud
      final requestBody = {'user_id': userId, 'category_id': categoryId};

      // URL for delete endpoint
      final String url = '$_baseUrl/delete';
      print('DEBUG - Delete category URL: $url');

      // Usar ApiHelper para la solicitud HTTP con manejo UTF-8 correcto
      final jsonData = await ApiHelper.postJson(url, requestBody);

      print('DEBUG - Delete response procesada correctamente');

      // Verificar el código de éxito
      if (jsonData['success'] != true) {
        throw ApiException(
          statusCode: 400,
          message: jsonData['message'] ?? 'Error al eliminar categoría',
          url: url,
        );
      }
    } catch (e) {
      print('DEBUG - Delete category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: $e',
        url: _baseUrl,
      );
    }
  }
}
