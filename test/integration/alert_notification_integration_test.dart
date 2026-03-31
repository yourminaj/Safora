import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/data/repositories/alerts_repository.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockAlertsRepository extends Mock implements AlertsRepository {}
class MockAlertPreferences extends Mock implements AlertPreferences {}

void main() {
  late MockNotificationService notificationService;
  late MockAlertsRepository alertsRepository;
  late MockAlertPreferences alertPreferences;
  late AlertsCubit alertsCubit;

  final now = DateTime.now();
  
  AlertEvent createAlert({
    required String id,
    required AlertType type,
    int? riskScore,
    double? distanceKm,
    double? confidenceLevel,
  }) {
    return AlertEvent(
      id: id,
      type: type,
      title: 'Test Alert: $id',
      description: 'Description for $id',
      timestamp: now,
      latitude: 0,
      longitude: 0,
      source: 'System',
      riskScore: riskScore,
      distanceKm: distanceKm,
      confidenceLevel: confidenceLevel,
    );
  }

  setUpAll(() {
    registerFallbackValue(AlertType.earthquake);
  });

  setUp(() {
    notificationService = MockNotificationService();
    alertsRepository = MockAlertsRepository();
    alertPreferences = MockAlertPreferences();

    when(() => notificationService.showDisasterAlert(
      title: any(named: 'title'),
      body: any(named: 'body'),
      soundName: any(named: 'soundName'),
    )).thenAnswer((_) async {});
    
    // Default preferences: all enabled
    when(() => alertPreferences.isEnabled(any())).thenReturn(true);
    when(() => alertPreferences.shouldReceive(any())).thenReturn(true);

    when(() => alertsRepository.getAlertHistory(limit: any(named: 'limit'))).thenReturn([]);

    alertsCubit = AlertsCubit(
      alertsRepository: alertsRepository,
      notificationService: notificationService,
      alertPreferences: alertPreferences,
    );
  });

  tearDown(() {
    alertsCubit.close();
  });

  group('Alert Pipeline Notifications', () {
    test('Critical alert triggers notification', () async {
      final criticalAlert = createAlert(
        id: '1', 
        type: AlertType.tsunami, 
      );
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => [criticalAlert],
      );

      await alertsCubit.loadAlerts(); // waits for loading
      
      verify(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      )).called(1);
    });

    test('Non-critical alert DOES NOT trigger notification', () async {
      final moderateAlert = createAlert(
        id: '2', 
        type: AlertType.strongWind, 
      );
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => [moderateAlert],
      );

      await alertsCubit.loadAlerts();
      
      // We assume heavyRain is not critical. If it is, this test fails and we can adjust.
      verifyNever(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      ));
    });

    test('Preference-gated suppression (disabled alert type)', () async {
      when(() => alertPreferences.shouldReceive(AlertType.earthquake)).thenReturn(false);
      when(() => alertPreferences.isEnabled(AlertType.earthquake)).thenReturn(false);

      final quake = createAlert(
        id: '3', 
        type: AlertType.earthquake, 
      );
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => [quake],
      );

      await alertsCubit.loadAlerts();
      
      // Should NOT notify because preference is disabled
      verifyNever(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      ));
      
      // List should be empty
      expect((alertsCubit.state as AlertsLoaded).alerts, isEmpty);
    });

    test('Flood gate limits to 3 notifications per refresh (assuming tsunamis are critical)', () async {
      final alerts = List.generate(5, (index) => createAlert(
        id: 'bulk_$index', 
        type: AlertType.tsunami, // tsunami is critical
      ));
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => alerts,
      );

      await alertsCubit.loadAlerts();
      
      // Should cap at 3 calls
      verify(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      )).called(3);
      
      // State should have all 5 alerts though
      expect((alertsCubit.state as AlertsLoaded).alerts.length, 5);
    });

    test('Deduplication prevents repeating notifications for same alert ID across refreshes', () async {
      final alert = createAlert(
        id: 'dedupe_1', 
        type: AlertType.tsunami,
      );
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => [alert],
      );

      // First load
      await alertsCubit.loadAlerts();
      verify(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      )).called(1);
      
      // After first load, history should return the alert to simulate cache
      when(() => alertsRepository.getAlertHistory(limit: any(named: 'limit'))).thenReturn([alert]);

      // Second load (pull to refresh) with same alert
      await alertsCubit.refreshAlerts();
      
      // Still only called 1 time total (not called again)
      verifyNever(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      ));
    });

    test('Risk score >= 80 overrides priority and triggers notification', () async {
      final highRiskLowPriority = createAlert(
        id: 'override_1', 
        type: AlertType.strongWind, // Normally would not trigger if it's not critical
        distanceKm: 0.0,
        confidenceLevel: 1.0,
      );
      
      when(() => alertsRepository.fetchLatestAlerts()).thenAnswer(
        (_) async => [highRiskLowPriority],
      );

      // We need to test local alert injection for Risk Score override
      // because loadAlerts only uses priority. Wait, the RiskScoreEngine sets riskScore in loadAlerts too. 
      // Actually, looking at AlertsCubit._notifyNewCritical, it ONLY checks `alert.type.priority == AlertPriority.critical`. 
      // The `riskScore >= 80` notification is ONLY for `addLocalAlert`!
      
      // So let's test addLocalAlert
      when(() => alertsRepository.saveAlerts(any())).thenAnswer((_) async {});

      alertsCubit.addLocalAlert(highRiskLowPriority);
      
      verify(() => notificationService.showDisasterAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        soundName: any(named: 'soundName'),
      )).called(1);
    });
  });
}
