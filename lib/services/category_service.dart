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

      // Realizar la solicitud HTTP
      final response = await http.get(Uri.parse(url));

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
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

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse('$_baseUrl/add'),
        body: json.encode(categoryWithUserId.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

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

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

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

      // Realizar la solicitud HTTP
      final response = await http.post(
        Uri.parse('$_baseUrl/delete'),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

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
      if (e is ApiException || e is NotAuthenticatedException) {
        rethrow;
      }
      throw ApiException('Error de conexión: $e');
    }
  }
}
