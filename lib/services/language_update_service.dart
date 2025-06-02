import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Servicio para actualizar el idioma del usuario tanto en la aplicación como en la base de datos
class LanguageUpdateService {
  /// Actualiza el idioma del usuario en la base de datos SQLite
  static Future<bool> updateUserLocaleInDatabase(String locale) async {
    try {
      // Obtener el usuario actual
      final UserModel? currentUser = await AuthService.getCurrentUser();

      if (currentUser == null || currentUser.id == null) {
        print('No hay usuario autenticado para actualizar el idioma');
        return false;
      }

      // Construir la URL para la API de actualización de idioma
      final url =
          ApiConfig.isProduction
              ? '${ApiConfig.baseApiUrl}/update/locale'
              : '${ApiConfig.baseApiUrl}:${ApiConfig.profileManagementServicePort}/update/locale';

      print('Actualizando idioma en la base de datos - URL: $url');
      print('Datos: user_id=${currentUser.id}, locale=$locale');

      // Convertir el ID a entero para asegurar que sea compatible con la API
      int userId;
      try {
        userId = int.parse(currentUser.id);
      } catch (e) {
        print('Error convirtiendo ID a entero: ${currentUser.id} - $e');
        // Si no es un entero válido, intentar usarlo tal cual
        userId = int.tryParse(currentUser.id) ?? 1;
      }

      // Enviar la solicitud para actualizar el idioma
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, // Usar el ID convertido a entero
          'locale': locale,
        }),
      );

      if (response.statusCode == 200) {
        // La actualización fue exitosa
        print('Idioma actualizado en la base de datos: $locale');

        // Actualizar también los datos del usuario en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = prefs.getString(AuthService.userDataKey);

        if (userDataJson != null) {
          final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
          userData['locale'] = locale;
          await prefs.setString(AuthService.userDataKey, jsonEncode(userData));
          print('Datos de usuario actualizados en SharedPreferences');
        }

        return true;
      } else {
        print(
          'Error al actualizar el idioma en la base de datos: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error en updateUserLocaleInDatabase: $e');
      return false;
    }
  }
}
