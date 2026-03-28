import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/detection/ml/crash_fall_detection_engine.dart';
import 'package:safora/detection/ml/crash_fall_detection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrashFallDetectionService service;

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
          onListen: (args, events) {},
        ));

    service = CrashFallDetectionService();
  });

  tearDown(() {
    service.dispose();
  });

  group('CrashFallDetectionService — Lifecycle', () {
    test('starts in stopped state', () {
      expect(service.isRunning, false);
    });

    test('isRunning becomes true after start', () async {
      await service.start();
      expect(service.isRunning, true);
    });

    test('isRunning becomes false after stop', () async {
      await service.start();
      service.stop();
      expect(service.isRunning, false);
    });

    test('alerts stream does not error before starting', () {
      expect(service.alerts, isNotNull);
    });

    test('dispose closes the stream', () {
      service.dispose();
      final newService = CrashFallDetectionService();
      expect(newService.isRunning, false);
      newService.dispose();
    });
  });

  group('CrashFallDetectionService — Alert Type Mapping', () {
    test('DetectionType enum values match expected names', () {
      expect(DetectionType.fall.name, 'fall');
      expect(DetectionType.vehicleCrash.name, 'vehicleCrash');
      expect(DetectionType.hardImpact.name, 'hardImpact');
    });
  });

  group('CrashFallDetectionService — Custom Engine', () {
    test('accepts custom engine configuration', () async {
      final customEngine = CrashFallDetectionEngine(
        fallThresholdG: 2.0,
        crashThresholdG: 3.0,
      );

      final customService = CrashFallDetectionService(engine: customEngine);
      expect(customService.isRunning, false);

      await customService.start();
      expect(customService.isRunning, true);

      customService.dispose();
    });
  });
}
