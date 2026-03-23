import 'package:flutter/foundation.dart';

/// Centralized application logger for error tracking.
///
/// In debug mode, logs to console via `debugPrint`.
/// In production, provides a hook point for crash reporting services
/// (e.g., Firebase Crashlytics, Sentry) without changing call sites.
///
/// Usage:
/// ```dart
/// AppLogger.error('Payment failed', error, stackTrace);
/// AppLogger.warning('Network slow, retrying');
/// AppLogger.info('User logged in');
/// ```
class AppLogger {
  AppLogger._();

  /// Optional callback for production crash reporting.
  /// Set this during initialization to forward errors to your crash
  /// reporting service (e.g., Firebase Crashlytics).
  ///
  /// ```dart
  /// AppLogger.onError = (message, error, stackTrace) {
  ///   FirebaseCrashlytics.instance.recordError(error, stackTrace);
  /// };
  /// ```
  static void Function(String message, Object? error, StackTrace? stackTrace)?
      onError;

  /// Optional callback for Flutter framework errors.
  /// ```dart
  /// AppLogger.onFlutterError = (details) {
  ///   FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  /// };
  /// ```
  static void Function(FlutterErrorDetails details)? onFlutterError;

  /// Log an error with optional error object and stack trace.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    // Forward to crash reporting in production.
    onError?.call(message, error, stackTrace);
  }

  /// Log a warning (non-fatal issue).
  static void warning(String message) {
    debugPrint('[WARN] $message');
  }

  /// Log an informational message (debug only).
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Handle Flutter framework errors.
  static void handleFlutterError(FlutterErrorDetails details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    if (kDebugMode) {
      debugPrint(details.stack?.toString() ?? 'No stack trace');
    }
    onFlutterError?.call(details);
  }

  /// Handle uncaught async errors (for use in runZonedGuarded).
  static void handleUncaughtError(Object error, StackTrace stackTrace) {
    AppLogger.error('Uncaught error', error, stackTrace);
  }

  /// Set up crash reporting callbacks.
  ///
  /// Call this during app initialization when your crash reporting
  /// service is ready.
  static void configureCrashReporting({
    void Function(String, Object?, StackTrace?)? errorCallback,
    void Function(FlutterErrorDetails)? flutterErrorCallback,
  }) {
    onError = errorCallback;
    onFlutterError = flutterErrorCallback;
  }
}
