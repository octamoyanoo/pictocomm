/// Jerarquía de errores de la aplicación.
///
/// Cualquier capa (data, domain, presentation) lanza estas excepciones en vez
/// de propagar errores tipados de librerías (dart:io, http, sqflite...). Así
/// la capa de presentación nunca depende de detalles de infraestructura.
library;

sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? message : '$message (causa: $cause)';
}

/// No se pudo leer o escribir en el almacenamiento local.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Falla al hablar con el backend.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// El recurso pedido no existe.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

/// Los datos no cumplen las reglas del dominio.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// La operación todavía no está implementada.
class UnimplementedFeatureException extends AppException {
  const UnimplementedFeatureException(super.message) : super(cause: null);
}
