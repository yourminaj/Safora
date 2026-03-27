import 'package:flutter_test/flutter_test.dart';
import 'package:safora/services/dead_man_switch_service.dart';

void main() {
  group('DeadManSwitchService', () {
    late DeadManSwitchService service;
    late bool triggered;

    setUp(() {
      triggered = false;
      service = DeadManSwitchService(
        onTrigger: () => triggered = true,
        checkInInterval: const Duration(seconds: 3),
        warningBeforeSeconds: 1,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('starts inactive', () {
      expect(service.isActive, isFalse);
      expect(service.nextDeadline, isNull);
    });

    test('becomes active after start', () {
      service.start();
      expect(service.isActive, isTrue);
      expect(service.nextDeadline, isNotNull);
    });

    test('becomes inactive after stop', () {
      service.start();
      service.stop();
      expect(service.isActive, isFalse);
      expect(service.nextDeadline, isNull);
    });

    test('checkIn resets the timer without stopping', () {
      service.start();
      final firstDeadline = service.nextDeadline;

      // Wait a bit then check in.
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        service.checkIn();
      });

      // After checkIn, deadline should be updated.
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        expect(service.isActive, isTrue);
        expect(service.nextDeadline, isNotNull);
        if (firstDeadline != null) {
          expect(service.nextDeadline!.isAfter(firstDeadline), isTrue);
        }
      });
    });

    test('remainingTime returns a non-null duration when active', () {
      service.start();
      final remaining = service.remainingTime;
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('remainingTime is null when inactive', () {
      expect(service.remainingTime, isNull);
    });

    test('triggers onTrigger callback after interval expires', () async {
      service = DeadManSwitchService(
        onTrigger: () => triggered = true,
        checkInInterval: const Duration(seconds: 1),
        warningBeforeSeconds: 0,
      );

      service.start();
      expect(triggered, isFalse);

      // Wait for the interval to expire.
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(triggered, isTrue);
      expect(service.isActive, isFalse);
    });

    test('emits warning before deadline', () async {
      final warnings = <Duration>[];
      service.warningStream.listen(warnings.add);

      service.start();

      // Wait for the warning to fire (3s interval - 1s warning = 2s delay).
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      expect(warnings, isNotEmpty);
    });

    test('stop prevents trigger', () async {
      service = DeadManSwitchService(
        onTrigger: () => triggered = true,
        checkInInterval: const Duration(seconds: 1),
        warningBeforeSeconds: 0,
      );

      service.start();
      service.stop();

      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(triggered, isFalse);
    });

    test('checkIn prevents trigger within interval', () async {
      service = DeadManSwitchService(
        onTrigger: () => triggered = true,
        checkInInterval: const Duration(seconds: 2),
        warningBeforeSeconds: 0,
      );

      service.start();

      // Check in halfway through.
      await Future<void>.delayed(const Duration(seconds: 1));
      service.checkIn();

      // Wait past original deadline but not past reset deadline.
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(triggered, isFalse);
    });
  });
}
