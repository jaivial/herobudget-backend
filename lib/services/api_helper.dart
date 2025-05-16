import 'dart:convert';
import 'package:http/http.dart' as http;

/// Clase de ayuda para manejar respuestas API y asegurar la codificación correcta
class ApiHelper {
  /// Decodificar una respuesta HTTP asegurando que se use UTF-8 correctamente
  static dynamic decodeResponse(http.Response response) {
    // Asegurar que estamos usando UTF-8 para la decodificación
    final responseBody = utf8.decode(response.bodyBytes);

    // Decodificar el JSON
    return json.decode(responseBody);
  }

  /// Enviar una solicitud POST con JSON y manejar la respuesta correctamente
  static Future<Map<String, dynamic>> postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: json.encode(body),
    );

    // Decodificar la respuesta con manejo UTF-8
    return decodeResponse(response);
  }

  /// Realizar una solicitud GET y manejar la respuesta correctamente
  static Future<Map<String, dynamic>> get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json; charset=utf-8'},
    );

    // Decodificar la respuesta con manejo UTF-8
    return decodeResponse(response);
  }
}
