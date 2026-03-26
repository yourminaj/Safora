import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/services/context_alert_service.dart';
import 'package:safora/core/services/weather_feed_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/weather_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WeatherFeedService service;

  setUp(() {
    service = WeatherFeedService(
      locationService: LocationService(),
      weatherApiClient: WeatherApiClient(),
      contextAlertService: ContextAlertService(),
    );
  });

  group('WeatherFeedService', () {
    test('isRunning is false initially', () {
      expect(service.isRunning, false);
    });

    test('start sets isRunning to true', () {
      service.start(intervalMinutes: 60); // Long interval to avoid firing
      expect(service.isRunning, true);
      service.stop();
    });

    test('stop sets isRunning to false', () {
      service.start(intervalMinutes: 60);
      service.stop();
      expect(service.isRunning, false);
    });

    test('start is idempotent (no-op if already running)', () {
      service.start(intervalMinutes: 60);
      service.start(intervalMinutes: 60); // Should not throw or create 2nd timer
      expect(service.isRunning, true);
      service.stop();
    });

    test('stop is idempotent (no-op if already stopped)', () {
      service.stop(); // Should not throw
      expect(service.isRunning, false);
    });

    test('dispose stops the feed', () {
      service.start(intervalMinutes: 60);
      service.dispose();
      expect(service.isRunning, false);
    });

    test('can restart after stop', () {
      service.start(intervalMinutes: 60);
      service.stop();
      service.start(intervalMinutes: 60);
      expect(service.isRunning, true);
      service.stop();
    });

    test('start with custom interval', () {
      service.start(intervalMinutes: 10);
      expect(service.isRunning, true);
      service.stop();
    });
  });
}
