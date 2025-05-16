import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../config/api_config.dart';
import '../utils/api_exceptions.dart';

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

      // Realizar la solicitud HTTP
      final response = await http.get(Uri.parse(url));

      // Debug: Print the response status
      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          // Manejar caso donde data es null (usuario no tiene categorías)
          if (jsonData['data'] == null) {
            return []; // Devolver lista vacía
          }

          final categoriesJson = jsonData['data'] as List;
          return categoriesJson.map((json) => Category.fromJson(json)).toList();
        } else {
          throw ApiException(
            jsonData['message'] ?? 'Error al obtener categorías',
          );
        }
      } else {
        throw ApiException(
          'Error al obtener categorías: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Debug: Print any exceptions
      print('DEBUG - Exception caught: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException('Error de conexión: $e');
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

      // Crear una copia de la categoría con el ID de usuario
      final categoryWithUserId = category.copyWith(userId: userId);

      // URL for add endpoint - remove "/add" as it's already in the endpoint
      final String url = '$_baseUrl/add';
      print('DEBUG - Add category URL: $url');

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(categoryWithUserId.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG - Add response status: ${response.statusCode}');
      print('DEBUG - Add response body: ${response.body}');

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return Category.fromJson(jsonData['data']);
        } else {
          throw ApiException(
            jsonData['message'] ?? 'Error al añadir categoría',
          );
        }
      } else {
        throw ApiException('Error al añadir categoría: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG - Add category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException('Error de conexión: $e');
    }
  }

  // Método para actualizar una categoría existente
  Future<Category> updateCategory(Category category) async {
    try {
      if (category.id == null) {
        throw ApiException('ID de categoría no proporcionado');
      }

      // Obtener el ID de usuario almacenado
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw NotAuthenticatedException('Usuario no autenticado');
      }

      // Preparar el cuerpo de la solicitud
      final requestBody = {
        'user_id': userId,
        'category_id': category.id,
        'name': category.name,
        'type': category.type,
        'emoji': category.emoji,
      };

      // URL for update endpoint
      final String url = '$_baseUrl/update';
      print('DEBUG - Update category URL: $url');

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG - Update response status: ${response.statusCode}');
      print('DEBUG - Update response body: ${response.body}');

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return Category.fromJson(jsonData['data']);
        } else {
          throw ApiException(
            jsonData['message'] ?? 'Error al actualizar categoría',
          );
        }
      } else {
        throw ApiException(
          'Error al actualizar categoría: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG - Update category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException('Error de conexión: $e');
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

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG - Delete response status: ${response.statusCode}');
      print('DEBUG - Delete response body: ${response.body}');

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] != true) {
          throw ApiException(
            jsonData['message'] ?? 'Error al eliminar categoría',
          );
        }
      } else {
        throw ApiException(
          'Error al eliminar categoría: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG - Delete category exception: $e');
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException('Error de conexión: $e');
    }
  }
}
