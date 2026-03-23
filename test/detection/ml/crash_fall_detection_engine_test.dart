import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/detection/ml/crash_fall_detection_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrashFallDetectionEngine engine;

  setUp(() {
    // Mock the sensors_plus method channel to avoid platform errors.
    const channel = MethodChannel('dev.fluttercommunity.plus/sensors/method');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    const accelChannel = EventChannel(
      'dev.fluttercommunity.plus/sensors/accelerometer',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(accelChannel, MockStreamHandler.inline(
          onListen: (args, events) {
            // Don't emit any events — tests verify config, not sensor data.
          },
        ));

    engine = CrashFallDetectionEngine(
      cooldownDuration: const Duration(milliseconds: 100),
      postImpactWindowMs: 200,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('CrashFallDetectionEngine — Lifecycle', () {
    test('starts in stopped state', () {
      expect(engine.isRunning, false);
    });

    test('isRunning becomes true after start', () {
      engine.start(onDetection: (_) {});
      expect(engine.isRunning, true);
    });

    test('isRunning becomes false after stop', () {
      engine.start(onDetection: (_) {});
      engine.stop();
      expect(engine.isRunning, false);
    });

    test('start is idempotent (calling twice does not crash)', () {
      engine.start(onDetection: (_) {});
      engine.start(onDetection: (_) {}); // Should not throw
      expect(engine.isRunning, true);
    });

    test('stop is idempotent (calling twice does not crash)', () {
      engine.start(onDetection: (_) {});
      engine.stop();
      engine.stop(); // Should not throw
      expect(engine.isRunning, false);
    });

    test('dispose releases everything', () {
      engine.start(onDetection: (_) {});
      engine.dispose();
      expect(engine.isRunning, false);
    });
  });

  group('CrashFallDetectionEngine — Threshold Configuration', () {
    test('default fall threshold is 3G (Biomedical Research standard)', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.fallThresholdG, 3.0);
      defaultEngine.dispose();
    });

    test('default crash threshold is 4G (IEEE/WreckWatch standard)', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.crashThresholdG, 4.0);
      defaultEngine.dispose();
    });

    test('default hard impact threshold is 6G', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.hardImpactThresholdG, 6.0);
      defaultEngine.dispose();
    });

    test('custom thresholds are respected', () {
      final custom = CrashFallDetectionEngine(
        fallThresholdG: 2.5,
        crashThresholdG: 5.0,
        hardImpactThresholdG: 8.0,
        minConfidence: 0.3,
      );

      expect(custom.fallThresholdG, 2.5);
      expect(custom.crashThresholdG, 5.0);
      expect(custom.hardImpactThresholdG, 8.0);
      expect(custom.minConfidence, 0.3);
      custom.dispose();
    });
  });

  group('CrashFallDetectionEngine — Safety Parameters', () {
    test('minimum confidence is 0.5 (suppresses phone drops)', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.minConfidence, 0.5);
      defaultEngine.dispose();
    });

    test('cooldown is 10 seconds (prevents alert spam)', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.cooldownDuration.inSeconds, 10);
      defaultEngine.dispose();
    });

    test('post-impact observation window is 2000ms', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.postImpactWindowMs, 2000);
      defaultEngine.dispose();
    });

    test('sampling rate is 50Hz (battery vs accuracy sweet spot)', () {
      final defaultEngine = CrashFallDetectionEngine();
      expect(defaultEngine.samplingRateHz, 50);
      defaultEngine.dispose();
    });
  });

  group('DetectionEvent — Data Integrity', () {
    test('DetectionEvent toString includes all fields', () {
      final event = DetectionEvent(
        type: DetectionType.fall,
        confidence: 0.75,
        peakGForce: 4.2,
        timestamp: DateTime(2026, 3, 23),
        hadFreefall: true,
        postImpactStillness: true,
      );

      final str = event.toString();
      expect(str, contains('fall'));
      expect(str, contains('0.75'));
      expect(str, contains('4.2'));
      expect(str, contains('freefall: true'));
      expect(str, contains('stillness: true'));
    });

    test('DetectionType enum has exactly 3 values', () {
      expect(DetectionType.values.length, 3);
      expect(DetectionType.values, contains(DetectionType.fall));
      expect(DetectionType.values, contains(DetectionType.vehicleCrash));
      expect(DetectionType.values, contains(DetectionType.hardImpact));
    });
  });
}
