/// Custom application exceptions.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Network error occurred'])
      : super(message, code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed'])
      : super(message, code: 'AUTH_ERROR');
}

class LocationException extends AppException {
  const LocationException([String message = 'Location access denied'])
      : super(message, code: 'LOCATION_ERROR');
}

class RouteException extends AppException {
  const RouteException([String message = 'Route calculation failed'])
      : super(message, code: 'ROUTE_ERROR');
}

class SafetyScoreException extends AppException {
  const SafetyScoreException([String message = 'Safety scoring failed'])
      : super(message, code: 'SAFETY_SCORE_ERROR');
}

class SOSException extends AppException {
  const SOSException([String message = 'SOS alert failed'])
      : super(message, code: 'SOS_ERROR');
}

class StorageException extends AppException {
  const StorageException([String message = 'Storage operation failed'])
      : super(message, code: 'STORAGE_ERROR');
}
