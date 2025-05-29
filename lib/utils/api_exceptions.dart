// Importar la nueva ApiException
import '../services/api_helper.dart';

// Clase base para excepciones de la API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String url;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.url,
  });

  @override
  String toString() => message;
}

// Excepción para usuario no autenticado
class NotAuthenticatedException extends ApiException {
  NotAuthenticatedException({required String message, required String url})
    : super(statusCode: 401, message: message, url: url);
}

// Excepción para recurso no encontrado
class ResourceNotFoundException extends ApiException {
  ResourceNotFoundException({required String message, required String url})
    : super(statusCode: 404, message: message, url: url);
}

// Excepción para errores de validación
class ValidationException extends ApiException {
  ValidationException({required String message, required String url})
    : super(statusCode: 400, message: message, url: url);
}

// Excepción para errores de conexión
class ConnectionException extends ApiException {
  ConnectionException({required String message, required String url})
    : super(statusCode: 0, message: message, url: url);
}
