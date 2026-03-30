import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:safora/services/dead_man_switch_service.dart';

void main() {
  group('DeadManSwitchService', () {
    late bool triggered;

    setUp(() {
      triggered = false;
    });

    DeadManSwitchService make({
      Duration interval = const Duration(seconds: 3),
      int warningBefore = 1,
      TimerFactory? createTimer,
    }) => DeadManSwitchService(
      onTrigger: () => triggered = true,
      checkInInterval: interval,
      warningBeforeSeconds: warningBefore,
      createTimer: createTimer,
    );

    tearDownAll(() {});

    test('starts inactive', () {
      final s = make();
      addTearDown(s.dispose);
      expect(s.isActive, isFalse);
      expect(s.nextDeadline, isNull);
    });

    test('becomes active after start', () {
      final s = make();
      addTearDown(s.dispose);
      s.start();
      expect(s.isActive, isTrue);
      expect(s.nextDeadline, isNotNull);
    });

    test('becomes inactive after stop', () {
      final s = make();
      addTearDown(s.dispose);
      s.start();
      s.stop();
      expect(s.isActive, isFalse);
      expect(s.nextDeadline, isNull);
    });

    test('checkIn resets the timer without stopping', () {
      fakeAsync((fake) {
        final s = make(interval: const Duration(seconds: 10), warningBefore: 0);
        addTearDown(s.dispose);
        s.start();
        final firstDeadline = s.nextDeadline;

        fake.elapse(const Duration(seconds: 3));
        s.checkIn();

        expect(s.isActive, isTrue);
        expect(s.nextDeadline, isNotNull);
        expect(s.nextDeadline!.isAfter(firstDeadline!), isTrue);
      });
    });

    test('remainingTime returns a non-null duration when active', () {
      final s = make();
      addTearDown(s.dispose);
      s.start();
      final remaining = s.remainingTime;
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('remainingTime is null when inactive', () {
      final s = make();
      addTearDown(s.dispose);
      expect(s.remainingTime, isNull);
    });

    test('triggers onTrigger callback after interval expires', () {
      fakeAsync((fake) {
        final s = make(interval: const Duration(seconds: 2), warningBefore: 0);
        addTearDown(s.dispose);
        s.start();
        expect(triggered, isFalse);

        fake.elapse(const Duration(seconds: 2, milliseconds: 100));

        expect(triggered, isTrue);
        expect(s.isActive, isFalse);
      });
    });

    test('emits warning before deadline', () {
      fakeAsync((fake) {
        final warnings = <Duration>[];
        final s = make(interval: const Duration(seconds: 5), warningBefore: 2);
        addTearDown(s.dispose);
        s.warningStream.listen(warnings.add);

        s.start();
        // Warning fires at 5s - 2s = 3s
        fake.elapse(const Duration(seconds: 3, milliseconds: 100));

        expect(warnings, isNotEmpty);
      });
    });

    test('stop prevents trigger', () {
      fakeAsync((fake) {
        final s = make(interval: const Duration(seconds: 2), warningBefore: 0);
        addTearDown(s.dispose);
        s.start();
        s.stop();

        fake.elapse(const Duration(seconds: 3));

        expect(triggered, isFalse);
      });
    });

    test('checkIn prevents trigger within interval', () {
      fakeAsync((fake) {
        final s = make(interval: const Duration(seconds: 4), warningBefore: 0);
        addTearDown(s.dispose);
        s.start();

        // Check in halfway through
        fake.elapse(const Duration(seconds: 2));
        s.checkIn();

        // Wait past original deadline but not past reset deadline
        fake.elapse(const Duration(seconds: 3));

        expect(triggered, isFalse);
      });
    });
  });
}
