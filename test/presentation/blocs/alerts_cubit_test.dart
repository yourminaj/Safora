import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/data/repositories/alerts_repository.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';

class MockAlertsRepository extends Mock implements AlertsRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAlertPreferences extends Mock implements AlertPreferences {}

void main() {
  late AlertsCubit cubit;
  late MockAlertsRepository mockRepo;
  late MockNotificationService mockNotifs;
  late MockAlertPreferences mockPrefs;

  setUp(() {
    mockRepo = MockAlertsRepository();
    mockNotifs = MockNotificationService();
    mockPrefs = MockAlertPreferences();

    when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
        .thenReturn([]);
    when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => []);
    when(
      () => mockNotifs.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockRepo.saveAlerts(any())).thenAnswer((_) async {});

    // By default, all alerts are enabled.
    when(() => mockPrefs.isEnabled(any())).thenReturn(true);

    cubit = AlertsCubit(
      alertsRepository: mockRepo,
      notificationService: mockNotifs,
      alertPreferences: mockPrefs,
    );
  });

  tearDown(() => cubit.close());

  group('AlertsCubit', () {
    test('initial state is AlertsInitial', () {
      expect(cubit.state, const AlertsInitial());
    });

    test('loadAlerts emits Loading then Loaded', () async {
      final states = <AlertsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadAlerts();

      // Wait for async operations to complete.
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(states.first, const AlertsLoading());
      expect(states.last, isA<AlertsLoaded>());

      await sub.cancel();
    });

    test('loadAlerts handles errors', () async {
      when(() => mockRepo.fetchLatestAlerts())
          .thenThrow(Exception('Network failure'));

      final states = <AlertsState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(states.first, const AlertsLoading());
      expect(states.last, isA<AlertsError>());

      await sub.cancel();
    });

    test('close cancels refresh timer', () async {
      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 1));

      // Close should not throw even with active timer.
      await cubit.close();
    });

    test('filterByCategory updates filtered view', () async {
      when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
          .thenReturn([]);
      when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => [
            AlertEvent(
              id: '1',
              type: AlertType.earthquake,
              title: 'Earthquake M5.2',
              timestamp: DateTime.now(),
              latitude: 23.8,
              longitude: 90.4,
            ),
            AlertEvent(
              id: '2',
              type: AlertType.flood,
              title: 'Flood Warning Dhaka',
              timestamp: DateTime.now(),
              latitude: 23.7,
              longitude: 90.3,
            ),
          ]);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      final loaded = cubit.state as AlertsLoaded;
      expect(loaded.alerts.length, 2);
      expect(loaded.filtered.length, 2); // No filter

      cubit.filterByCategory(AlertCategory.waterMarine);

      final filtered = cubit.state as AlertsLoaded;
      expect(filtered.filterCategory, AlertCategory.waterMarine);
      // Flood is waterMarine category — so filtered results should contain it.
      expect(filtered.filtered.every((a) => a.type.category == AlertCategory.waterMarine), true);
    });

    test('filterByPriority updates filtered view', () async {
      when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
          .thenReturn([]);
      when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => [
            AlertEvent(
              id: '1',
              type: AlertType.earthquake,
              title: 'Critical Earthquake',
              timestamp: DateTime.now(),
              latitude: 23.8,
              longitude: 90.4,
            ),
          ]);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      cubit.filterByPriority(AlertPriority.critical);

      final filtered = cubit.state as AlertsLoaded;
      expect(filtered.filterPriority, AlertPriority.critical);
      expect(filtered.filtered.every((a) => a.type.priority == AlertPriority.critical), true);
    });

    test('clearFilters resets both category and priority', () async {
      when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
          .thenReturn([]);
      when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => [
            AlertEvent(
              id: '1',
              type: AlertType.earthquake,
              title: 'Test',
              timestamp: DateTime.now(),
              latitude: 23.8,
              longitude: 90.4,
            ),
          ]);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      cubit.filterByPriority(AlertPriority.critical);
      cubit.filterByCategory(AlertCategory.naturalDisaster);

      cubit.clearFilters();

      final cleared = cubit.state as AlertsLoaded;
      expect(cleared.filterCategory, isNull);
      expect(cleared.filterPriority, isNull);
    });

    test('refreshAlerts preserves filter state', () async {
      when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
          .thenReturn([]);
      when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => [
            AlertEvent(
              id: '1',
              type: AlertType.earthquake,
              title: 'Earthquake',
              timestamp: DateTime.now(),
              latitude: 23.8,
              longitude: 90.4,
            ),
          ]);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      cubit.filterByPriority(AlertPriority.critical);

      // Refresh should keep the filter.
      await cubit.refreshAlerts();

      final refreshed = cubit.state as AlertsLoaded;
      expect(refreshed.filterPriority, AlertPriority.critical);
    });
  });

  group('addLocalAlert', () {
    test('injects alert into empty (initial) state', () {
      // State is AlertsInitial — no loadAlerts() called.
      final alert = AlertEvent(
        id: 'geofence_1',
        type: AlertType.geofenceExit,
        title: 'Left Safe Zone',
        timestamp: DateTime.now(),
        latitude: 23.8103,
        longitude: 90.4125,
      );

      cubit.addLocalAlert(alert);

      final loaded = cubit.state as AlertsLoaded;
      expect(loaded.alerts.length, 1);
      expect(loaded.alerts.first.id, 'geofence_1');
      expect(loaded.alerts.first.latitude, 23.8103);
      expect(loaded.alerts.first.longitude, 90.4125);

      // Verify persistence was called.
      verify(() => mockRepo.saveAlerts(any())).called(1);
    });

    test('injects alert at the front of existing loaded state', () async {
      // Pre-load some alerts.
      when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => [
            AlertEvent(
              id: 'existing_1',
              type: AlertType.earthquake,
              title: 'Old Earthquake',
              timestamp: DateTime(2026, 1, 1),
              latitude: 23.8,
              longitude: 90.4,
            ),
          ]);

      cubit.loadAlerts();
      await Future<void>.delayed(const Duration(seconds: 2));

      // Now inject a local alert.
      final newAlert = AlertEvent(
        id: 'speed_1',
        type: AlertType.speedWarning,
        title: 'Overspeeding: 150 km/h',
        timestamp: DateTime.now(),
        latitude: 23.81,
        longitude: 90.41,
        magnitude: 150.0,
      );

      cubit.addLocalAlert(newAlert);

      final loaded = cubit.state as AlertsLoaded;
      // New alert should be first.
      expect(loaded.alerts.first.id, 'speed_1');
      expect(loaded.alerts.length, 2);
      expect(loaded.alerts[1].id, 'existing_1');
    });

    test('deduplicates alerts by ID', () {
      final alert = AlertEvent(
        id: 'dup_1',
        type: AlertType.phoneSnatching,
        title: 'Snatch Detected',
        timestamp: DateTime.now(),
        latitude: 23.8,
        longitude: 90.4,
      );

      cubit.addLocalAlert(alert);
      cubit.addLocalAlert(alert); // Same ID again.

      final loaded = cubit.state as AlertsLoaded;
      // Should only have one copy.
      expect(loaded.alerts.where((a) => a.id == 'dup_1').length, 1);
    });

    test('persists alerts via saveAlerts on every injection', () {
      final alert1 = AlertEvent(
        id: 'ctx_1',
        type: AlertType.heatStroke,
        title: 'Heat Stroke Risk',
        timestamp: DateTime.now(),
        latitude: 23.8,
        longitude: 90.4,
      );
      final alert2 = AlertEvent(
        id: 'ctx_2',
        type: AlertType.drowsyDriving,
        title: 'Drowsy Driving Warning',
        timestamp: DateTime.now(),
        latitude: 23.8,
        longitude: 90.4,
      );

      cubit.addLocalAlert(alert1);
      cubit.addLocalAlert(alert2);

      // saveAlerts called once per addLocalAlert.
      verify(() => mockRepo.saveAlerts(any())).called(2);
    });

    test('triggers notification for critical-priority alerts', () {
      // Earthquake is critical priority.
      final criticalAlert = AlertEvent(
        id: 'crash_1',
        type: AlertType.carAccident,
        title: 'Vehicle Crash Detected',
        description: 'Impact detected at 8.5G.',
        timestamp: DateTime.now(),
        latitude: 23.8,
        longitude: 90.4,
        magnitude: 8.5,
      );

      cubit.addLocalAlert(criticalAlert);

      verify(
        () => mockNotifs.showDisasterAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('does NOT trigger notification for non-critical alerts', () {
      // Speed warning is moderate priority.
      final moderateAlert = AlertEvent(
        id: 'speed_non_crit',
        type: AlertType.speedWarning,
        title: 'Overspeeding',
        timestamp: DateTime.now(),
        latitude: 23.8,
        longitude: 90.4,
      );

      cubit.addLocalAlert(moderateAlert);

      verifyNever(
        () => mockNotifs.showDisasterAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      );
    });

    test('alert coordinates are preserved from input', () {
      final alert = AlertEvent(
        id: 'geo_test',
        type: AlertType.geofenceExit,
        title: 'Left Zone',
        timestamp: DateTime.now(),
        latitude: 40.7128,
        longitude: -74.0060,
        source: 'On-Device GPS',
      );

      cubit.addLocalAlert(alert);

      final loaded = cubit.state as AlertsLoaded;
      expect(loaded.alerts.first.latitude, 40.7128);
      expect(loaded.alerts.first.longitude, -74.0060);
      expect(loaded.alerts.first.source, 'On-Device GPS');
    });
  });
}

