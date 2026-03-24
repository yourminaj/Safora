import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/sos_foreground_service.dart';

void main() {
  group('SosForegroundService', () {
    group('Singleton Pattern', () {
      test('instance returns same object', () {
        final a = SosForegroundService.instance;
        final b = SosForegroundService.instance;
        expect(identical(a, b), true);
      });

      test('instance is not null', () {
        expect(SosForegroundService.instance, isNotNull);
      });
    });
  });

  group('SosTaskHandler', () {
    late SosTaskHandler handler;

    setUp(() {
      handler = SosTaskHandler();
    });

    group('Instantiation', () {
      test('can be instantiated', () {
        expect(handler, isNotNull);
        expect(handler, isA<SosTaskHandler>());
      });
    });

    group('Notification Callbacks', () {
      test('onNotificationDismissed does not throw', () {
        expect(() => handler.onNotificationDismissed(), returnsNormally);
      });

      test('onNotificationPressed does not throw', () {
        // In test env, FlutterForegroundTask is not initialized,
        // but the method should handle this gracefully.
        expect(() => handler.onNotificationPressed(), returnsNormally);
      });

      test('onNotificationButtonPressed with stop_sos does not throw', () {
        expect(
          () => handler.onNotificationButtonPressed('stop_sos'),
          returnsNormally,
        );
      });

      test('onNotificationButtonPressed with unknown id does not throw', () {
        expect(
          () => handler.onNotificationButtonPressed('unknown'),
          returnsNormally,
        );
      });

      test('onNotificationButtonPressed with empty id does not throw', () {
        expect(
          () => handler.onNotificationButtonPressed(''),
          returnsNormally,
        );
      });
    });

    group('Lifecycle Methods', () {
      test('onRepeatEvent does not throw', () {
        expect(
          () => handler.onRepeatEvent(DateTime.now()),
          returnsNormally,
        );
      });

      test('onStart does not throw', () async {
        await expectLater(
          handler.onStart(DateTime.now(), TaskStarter.developer),
          completes,
        );
      });

      test('onDestroy does not throw', () async {
        await expectLater(
          handler.onDestroy(DateTime.now(), false),
          completes,
        );
      });

      test('onDestroy with isTimeout=true does not throw', () async {
        await expectLater(
          handler.onDestroy(DateTime.now(), true),
          completes,
        );
      });
    });
  });
}
