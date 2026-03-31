import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_sounds.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/data/repositories/alerts_repository.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/services/risk_score_engine.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockAlertsRepository extends Mock implements AlertsRepository {}
class MockAlertPreferences extends Mock implements AlertPreferences {}
class MockRiskScoreEngine extends Mock implements RiskScoreEngine {}

void main() {
  late MockNotificationService notificationService;
  late MockAlertsRepository alertsRepository;
  late MockAlertPreferences alertPreferences;
  late AlertsCubit alertsCubit;

  setUpAll(() {
    registerFallbackValue(AlertType.earthquake);
  });

  setUp(() {
    notificationService = MockNotificationService();
    alertsRepository = MockAlertsRepository();
    alertPreferences = MockAlertPreferences();

    when(() => alertPreferences.isEnabled(any())).thenReturn(true);
    when(() => alertPreferences.shouldReceive(any())).thenReturn(true);

    when(() => alertsRepository.getAlertHistory(limit: any(named: 'limit')))
        .thenReturn([]);
    when(() => alertsRepository.saveAlerts(any())).thenAnswer((_) async {});

    when(() => notificationService.showDisasterAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          soundName: any(named: 'soundName'),
        )).thenAnswer((_) async {});

    alertsCubit = AlertsCubit(
      alertsRepository: alertsRepository,
      notificationService: notificationService,
      alertPreferences: alertPreferences,
    );
  });

  tearDown(() {
    alertsCubit.close();
  });

  group('Holistic Verification of All Alert Types (127)', () {
    test('Ensures AlertType attributes map without throwing errors', () {
      for (final type in AlertType.values) {
        expect(type.label, isNotEmpty);
        expect(type.category, isNotNull);
        expect(type.category.label, isNotEmpty);
        expect(type.priority, isNotNull);
        expect(type.isFree, isNotNull);
      }
    });

    test('Ensures AlertSounds resolve properly for every type', () {
      for (final type in AlertType.values) {
        final path = AlertSounds.forType(type);
        expect(path, isNotEmpty);
        expect(path.contains('/'), true);
        expect(path.endsWith('.mp3'), true, reason: 'Must be an MP3 file');
      }
    });

    test('Alert pipeline handles EVERY AlertType (127) safely', () {
      final now = DateTime.now();

      for (int i = 0; i < AlertType.values.length; i++) {
        final type = AlertType.values[i];
        
        final testAlert = AlertEvent(
          id: 'test_loop_$i',
          type: type,
          title: '${type.label} test',
          description: 'Testing ${type.label} parsing',
          timestamp: now,
          latitude: 0.0,
          longitude: 0.0,
          source: 'System',
        );

        // This checks if the risk engine / cubit formatting throws an error 
        // when inserting a new enum locally.
        expect(() => alertsCubit.addLocalAlert(testAlert), returnsNormally);
      }
    });

    test('Critical Priority directly calls notification (throttled across types)', () {
      final now = DateTime.now();

      int criticalCount = 0;

      for (int i = 0; i < AlertType.values.length; i++) {
        final type = AlertType.values[i];
        if (type.priority == AlertPriority.critical) {
          criticalCount++;
          
          final testAlert = AlertEvent(
            id: 'test_crit_${type.name}',
            type: type,
            title: '${type.label} Critical Test',
            timestamp: now,
            latitude: 0,
            longitude: 0,
            source: 'System',
          );

          alertsCubit.addLocalAlert(testAlert);
        }
      }

      // Verify that every critical alert correctly resolved to a notification call.
      // E.g., if there are 45 critical alert types, we should have 45 showDisasterAlert calls,
      // because they are all different AlertTypes and don't conflict the 10-second cache
      // if the cache is keyed by AlertType.
      verify(() => notificationService.showDisasterAlert(
            title: any(named: 'title'),
            body: any(named: 'body'),
            soundName: any(named: 'soundName'),
          )).called(criticalCount);
    });
  });
}
