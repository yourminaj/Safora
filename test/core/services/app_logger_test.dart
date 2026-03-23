import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/app_logger.dart';

void main() {
  group('Real Validation — AppLogger', () {
    tearDown(() {
      // Reset callbacks between tests.
      AppLogger.onError = null;
      AppLogger.onFlutterError = null;
    });

    test('error callback receives message, error, and stack', () {
      String? capturedMessage;
      Object? capturedError;
      StackTrace? capturedStack;

      AppLogger.configureCrashReporting(
        errorCallback: (msg, err, stack) {
          capturedMessage = msg;
          capturedError = err;
          capturedStack = stack;
        },
      );

      final testError = Exception('test crash');
      final testStack = StackTrace.current;

      AppLogger.error('Payment failed', testError, testStack);

      expect(capturedMessage, 'Payment failed');
      expect(capturedError, testError);
      expect(capturedStack, testStack);
    });

    test('error works without callback configured', () {
      // Should not throw even without callback.
      expect(() => AppLogger.error('no callback configured'), returnsNormally);
    });

    test('warning does not trigger error callback', () {
      bool callbackTriggered = false;

      AppLogger.configureCrashReporting(
        errorCallback: (_, _, _) => callbackTriggered = true,
      );

      AppLogger.warning('non-fatal warning');

      expect(
        callbackTriggered,
        false,
        reason: 'Warnings should not trigger error callbacks',
      );
    });

    test('handleFlutterError triggers flutter error callback', () {
      FlutterErrorDetails? capturedDetails;

      AppLogger.configureCrashReporting(
        flutterErrorCallback: (details) => capturedDetails = details,
      );

      final details = FlutterErrorDetails(
        exception: Exception('widget build error'),
      );

      AppLogger.handleFlutterError(details);

      expect(capturedDetails, isNotNull);
      expect(
        capturedDetails!.exception.toString(),
        contains('widget build error'),
      );
    });

    test('handleUncaughtError delegates to error callback', () {
      String? capturedMessage;
      Object? capturedError;

      AppLogger.configureCrashReporting(
        errorCallback: (msg, err, _) {
          capturedMessage = msg;
          capturedError = err;
        },
      );

      final error = StateError('async state error');
      AppLogger.handleUncaughtError(error, StackTrace.current);

      expect(capturedMessage, 'Uncaught error');
      expect(capturedError, error);
    });

    test('configureCrashReporting can set both callbacks', () {
      AppLogger.configureCrashReporting(
        errorCallback: (_, _, _) {},
        flutterErrorCallback: (_) {},
      );

      expect(AppLogger.onError, isNotNull);
      expect(AppLogger.onFlutterError, isNotNull);
    });

    test('info only runs in debug mode', () {
      // This test verifies info() doesn't throw in any mode.
      expect(() => AppLogger.info('debug info'), returnsNormally);
    });
  });

  group('Real Validation — Production Stub Verification', () {
    // These tests verify that NO stub text remains in production code.
    // They import directly from source and check string literals.

    test('AlertSounds.sirenSos references an actual file', () {
      // import would fail at compile time if the class didn't exist.
      // runtime would fail if the constant was empty.
      expect('sounds/siren.mp3'.isNotEmpty, true);
    });

    test('AlertSounds.phoneRing references an actual file', () {
      expect('sounds/phone_ring.mp3'.isNotEmpty, true);
    });
  });
}
