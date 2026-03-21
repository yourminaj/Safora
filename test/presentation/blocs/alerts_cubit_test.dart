import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/repositories/alerts_repository.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';

class MockAlertsRepository extends Mock implements AlertsRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late AlertsCubit cubit;
  late MockAlertsRepository mockRepo;
  late MockNotificationService mockNotifs;

  setUp(() {
    mockRepo = MockAlertsRepository();
    mockNotifs = MockNotificationService();

    when(() => mockRepo.getAlertHistory(limit: any(named: 'limit')))
        .thenReturn([]);
    when(() => mockRepo.fetchLatestAlerts()).thenAnswer((_) async => []);
    when(
      () => mockNotifs.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});

    cubit = AlertsCubit(
      alertsRepository: mockRepo,
      notificationService: mockNotifs,
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
}
