import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/alerts_local_datasource.dart';
import 'package:safora/data/datasources/disaster_api_client.dart';
import 'package:safora/data/datasources/military_alert_client.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/repositories/alerts_repository.dart';

class MockDisasterApiClient extends Mock implements DisasterApiClient {}

class MockMilitaryAlertClient extends Mock implements MilitaryAlertClient {}

class MockAlertsLocalDataSource extends Mock
    implements AlertsLocalDataSource {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late AlertsRepositoryImpl repo;
  late MockDisasterApiClient mockApi;
  late MockMilitaryAlertClient mockMilitary;
  late MockAlertsLocalDataSource mockLocal;
  late MockLocationService mockLocation;

  final testPosition = Position(
    latitude: 23.8103,
    longitude: 90.4125,
    timestamp: DateTime(2026, 3, 21),
    accuracy: 10.0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  final earthquakeAlert = AlertEvent(
    id: 'eq1',
    type: AlertType.earthquake,
    title: 'M 5.2 - Alaska',
    timestamp: DateTime(2026, 3, 21, 10),
    source: 'USGS',
    latitude: 61.5,
    longitude: -150.2,
  );

  final cycloneAlert = AlertEvent(
    id: 'tc1',
    type: AlertType.cyclone,
    title: 'Cyclone Mocha',
    timestamp: DateTime(2026, 3, 21, 12),
    source: 'GDACS',
    latitude: 20.0,
    longitude: 90.0,
  );

  final floodAlert = AlertEvent(
    id: 'flood_2026-03-21',
    type: AlertType.flood,
    title: 'Flood Risk Alert',
    timestamp: DateTime(2026, 3, 21, 8),
    source: 'Open-Meteo',
    latitude: 23.8,
    longitude: 90.4,
  );

  setUp(() {
    mockApi = MockDisasterApiClient();
    mockMilitary = MockMilitaryAlertClient();
    mockLocal = MockAlertsLocalDataSource();
    mockLocation = MockLocationService();

    repo = AlertsRepositoryImpl(
      apiClient: mockApi,
      militaryAlertClient: mockMilitary,
      localDataSource: mockLocal,
      locationService: mockLocation,
    );

    // Default stubs.
    when(() => mockApi.fetchUsgsEarthquakes())
        .thenAnswer((_) async => [earthquakeAlert]);
    when(() => mockApi.fetchGdacsEvents())
        .thenAnswer((_) async => [cycloneAlert]);
    when(() => mockLocation.getCurrentPosition())
        .thenAnswer((_) async => testPosition);
    when(() => mockApi.fetchFloodRisk(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => [floodAlert]);
    when(() => mockApi.fetchWeatherAlerts(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => []);
    when(() => mockApi.fetchAirQualityAlerts(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => []);
    when(() => mockApi.fetchWildfireHotspots(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => []);
    when(() => mockApi.fetchNasaEonetEvents())
        .thenAnswer((_) async => []);
    when(() => mockMilitary.fetchMilitaryAlerts(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        )).thenAnswer((_) async => []);
    when(() => mockLocal.saveAll(any())).thenAnswer((_) async {});
    when(() => mockLocal.getRecent(limit: any(named: 'limit')))
        .thenReturn([]);
    when(() => mockLocal.clear()).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(<AlertEvent>[]);
  });

  group('AlertsRepositoryImpl', () {
    test('fetches from all sources concurrently', () async {
      final alerts = await repo.fetchLatestAlerts();

      verify(() => mockApi.fetchUsgsEarthquakes()).called(1);
      verify(() => mockApi.fetchGdacsEvents()).called(1);
      verify(() => mockApi.fetchFloodRisk(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          )).called(1);

      expect(alerts, hasLength(3));
    });

    test('sorts alerts newest first', () async {
      final alerts = await repo.fetchLatestAlerts();

      // Cyclone 12:00 > Earthquake 10:00 > Flood 08:00
      expect(alerts[0].title, 'Cyclone Mocha');
      expect(alerts[1].title, 'M 5.2 - Alaska');
      expect(alerts[2].title, 'Flood Risk Alert');
    });

    test('deduplicates by alert ID', () async {
      // Return the same earthquake from both USGS and GDACS.
      when(() => mockApi.fetchGdacsEvents())
          .thenAnswer((_) async => [earthquakeAlert]);

      final alerts = await repo.fetchLatestAlerts();

      // Should have 2, not 3 (earthquake deduped).
      expect(alerts, hasLength(2));
    });

    test('deduplicates by title+timestamp when ID is null', () async {
      final noIdAlert1 = AlertEvent(
        type: AlertType.earthquake,
        title: 'Same Event',
        timestamp: DateTime(2026, 3, 21, 10),
        source: 'USGS',
        latitude: 0,
        longitude: 0,
      );
      final noIdAlert2 = AlertEvent(
        type: AlertType.earthquake,
        title: 'Same Event',
        timestamp: DateTime(2026, 3, 21, 10),
        source: 'GDACS',
        latitude: 0,
        longitude: 0,
      );

      when(() => mockApi.fetchUsgsEarthquakes())
          .thenAnswer((_) async => [noIdAlert1]);
      when(() => mockApi.fetchGdacsEvents())
          .thenAnswer((_) async => [noIdAlert2]);

      final alerts = await repo.fetchLatestAlerts();

      // Title + timestamp composite key → deduped.
      expect(alerts, hasLength(2)); // 1 unique earthquake + 1 flood
    });

    test('persists fetched alerts to local storage', () async {
      await repo.fetchLatestAlerts();

      verify(() => mockLocal.saveAll(any())).called(1);
    });

    test('skips flood risk when location unavailable', () async {
      when(() => mockLocation.getCurrentPosition())
          .thenAnswer((_) async => null);

      final alerts = await repo.fetchLatestAlerts();

      // 2 alerts: earthquake + cyclone (no flood).
      expect(alerts, hasLength(2));
      verifyNever(() => mockApi.fetchFloodRisk(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ));
    });

    test('handles single source failure gracefully', () async {
      when(() => mockApi.fetchUsgsEarthquakes())
          .thenAnswer((_) async => []);

      final alerts = await repo.fetchLatestAlerts();

      // Still returns GDACS + flood.
      expect(alerts, hasLength(2));
    });

    test('getAlertHistory delegates to local datasource', () {
      when(() => mockLocal.getRecent(limit: 10))
          .thenReturn([earthquakeAlert]);

      final history = repo.getAlertHistory(limit: 10);

      expect(history, hasLength(1));
      verify(() => mockLocal.getRecent(limit: 10)).called(1);
    });

    test('saveAlerts delegates to local datasource', () async {
      await repo.saveAlerts([earthquakeAlert]);

      verify(() => mockLocal.saveAll([earthquakeAlert])).called(1);
    });

    test('clearHistory delegates to local datasource', () async {
      await repo.clearHistory();

      verify(() => mockLocal.clear()).called(1);
    });
  });
}
