import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/environment.dart';

/// Clase de ayuda para manejar respuestas API y asegurar la codificación correcta
class ApiHelper {
  /// Cliente HTTP con configuración personalizada
  static late http.Client _client;

  /// Inicializar el cliente HTTP con configuraciones del ambiente
  static void initialize() {
    _client = http.Client();
  }

  /// Obtener headers por defecto con configuraciones del ambiente
  static Map<String, String> get _defaultHeaders {
    final headers = Map<String, String>.from(AppConfig.defaultHeaders);

    if (EnvironmentConfig.enableLogging) {
      headers['X-Environment'] =
          EnvironmentConfig.currentEnvironment.toString().split('.').last;
    }

    return headers;
  }

  /// Decodificar una respuesta HTTP asegurando que se use UTF-8 correctamente
  static dynamic decodeResponse(http.Response response) {
    if (AppConfig.enableNetworkLogging) {
      print('API Response [${response.statusCode}]: ${response.request?.url}');
      if (response.statusCode >= 400) {
        print('Error Response Body: ${response.body}');
      }
    }

    // Asegurar que estamos usando UTF-8 para la decodificación
    final responseBody = utf8.decode(response.bodyBytes);

    // Verificar que la respuesta sea exitosa
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Decodificar el JSON
      return json.decode(responseBody);
    } else {
      // Manejar errores
      throw ApiException(
        statusCode: response.statusCode,
        message: responseBody,
        url: response.request?.url.toString() ?? 'Unknown URL',
      );
    }
  }

  /// Enviar una solicitud POST con JSON y manejar la respuesta correctamente
  static Future<Map<String, dynamic>> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? additionalHeaders,
    Duration? timeout,
  }) async {
    if (AppConfig.enableNetworkLogging) {
      print('API POST: $url');
      print('Request Body: ${json.encode(body)}');
    }

    final headers = Map<String, String>.from(_defaultHeaders);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    try {
      final response = await _client
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(timeout ?? AppConfig.apiTimeout);

      // Decodificar la respuesta con manejo UTF-8
      return decodeResponse(response) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'No hay conexión a internet: ${e.message}',
        url: url,
      );
    } on HttpException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error HTTP: ${e.message}',
        url: url,
      );
    } catch (e) {
      if (AppConfig.enableNetworkLogging) {
        print('API Error: $e');
      }
      rethrow;
    }
  }

  /// Realizar una solicitud GET y manejar la respuesta correctamente
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? additionalHeaders,
    Duration? timeout,
  }) async {
    if (AppConfig.enableNetworkLogging) {
      print('API GET: $url');
    }

    final headers = Map<String, String>.from(_defaultHeaders);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(timeout ?? AppConfig.apiTimeout);

      // Decodificar la respuesta con manejo UTF-8
      return decodeResponse(response) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'No hay conexión a internet: ${e.message}',
        url: url,
      );
    } on HttpException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error HTTP: ${e.message}',
        url: url,
      );
    } catch (e) {
      if (AppConfig.enableNetworkLogging) {
        print('API Error: $e');
      }
      rethrow;
    }
  }

  /// Realizar una solicitud PUT
  static Future<Map<String, dynamic>> putJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? additionalHeaders,
    Duration? timeout,
  }) async {
    if (AppConfig.enableNetworkLogging) {
      print('API PUT: $url');
      print('Request Body: ${json.encode(body)}');
    }

    final headers = Map<String, String>.from(_defaultHeaders);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    try {
      final response = await _client
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(timeout ?? AppConfig.apiTimeout);

      return decodeResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (AppConfig.enableNetworkLogging) {
        print('API Error: $e');
      }
      rethrow;
    }
  }

  /// Realizar una solicitud DELETE
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? additionalHeaders,
    Duration? timeout,
  }) async {
    if (AppConfig.enableNetworkLogging) {
      print('API DELETE: $url');
    }

    final headers = Map<String, String>.from(_defaultHeaders);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    try {
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(timeout ?? AppConfig.apiTimeout);

      return decodeResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (AppConfig.enableNetworkLogging) {
        print('API Error: $e');
      }
      rethrow;
    }
  }

  /// Limpiar recursos
  static void dispose() {
    _client.close();
  }
}

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String url;

  const ApiException({
    required this.statusCode,
    required this.message,
    required this.url,
  });

  @override
  String toString() {
    return 'ApiException: [$statusCode] $message (URL: $url)';
  }

  /// Verificar si es un error de red (sin conexión)
  bool get isNetworkError => statusCode == 0;

  /// Verificar si es un error del servidor (5xx)
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Verificar si es un error del cliente (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Verificar si es un error de autenticación
  bool get isAuthError => statusCode == 401 || statusCode == 403;
}
