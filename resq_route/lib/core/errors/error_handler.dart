import 'package:flutter/foundation.dart';
import 'package:resq_route/core/errors/app_exceptions.dart';
import 'package:resq_route/core/utils/logger.dart';

/// Global error handler that logs and processes uncaught errors.
class ErrorHandler {
  ErrorHandler._();

  /// Initialize global error handlers.
  static void initialize() {
    FlutterError.onError = (details) {
      AppLogger.error(
        'Flutter Error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Platform Error', error, stack);
      return true;
    };
  }

  /// Get a user-friendly error message from any exception.
  static String getUserMessage(dynamic error) {
    if (error is AppException) return error.message;
    if (error is FormatException) return 'Invalid data format';
    return 'Something went wrong. Please try again.';
  }
}
