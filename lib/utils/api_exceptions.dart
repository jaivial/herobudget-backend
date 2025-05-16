// Clase base para excepciones de la API
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

// Excepción para usuario no autenticado
class NotAuthenticatedException extends ApiException {
  NotAuthenticatedException(String message) : super(message);
}

// Excepción para recurso no encontrado
class ResourceNotFoundException extends ApiException {
  ResourceNotFoundException(String message) : super(message);
}

// Excepción para errores de validación
class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}

// Excepción para errores de conexión
class ConnectionException extends ApiException {
  ConnectionException(String message) : super(message);
}
