import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/battery_service.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/core/services/sms_service.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/battery/battery_cubit.dart';
import 'package:safora/presentation/blocs/battery/battery_state.dart';

class MockBatteryService extends Mock implements BatteryService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockSmsService extends Mock implements SmsService {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockAlertsCubit extends Mock implements AlertsCubit {}

void main() {
  late BatteryCubit cubit;
  late MockBatteryService mockBattery;
  late MockNotificationService mockNotification;
  late MockSmsService mockSms;
  late MockContactsRepository mockContacts;
  late MockAlertsCubit mockAlerts;

  // Callback holder for driving the cubit.
  late void Function(int level, bp.BatteryState state) batteryCallback;

  setUp(() {
    mockBattery = MockBatteryService();
    mockNotification = MockNotificationService();
    mockSms = MockSmsService();
    mockContacts = MockContactsRepository();
    mockAlerts = MockAlertsCubit();

    // Stub AlertsCubit.addLocalAlert so battery critical path works.
    when(() => mockAlerts.addLocalAlert(any())).thenReturn(null);

    // Capture the callback when startMonitoring is called.
    when(() => mockBattery.startMonitoring(
          onLevelChanged: any(named: 'onLevelChanged'),
        )).thenAnswer((invocation) {
      batteryCallback = invocation.namedArguments[#onLevelChanged]
          as void Function(int, bp.BatteryState);
    });
    when(() => mockBattery.stopMonitoring()).thenReturn(null);

    when(() => mockNotification.showBatteryAlert(any()))
        .thenAnswer((_) async {});
    when(() => mockSms.sendBatteryAlert(
          contact: any(named: 'contact'),
          batteryLevel: any(named: 'batteryLevel'),
        )).thenAnswer((_) async => true);

    when(() => mockContacts.getAll()).thenReturn([
      const EmergencyContact(
        id: '1',
        name: 'Mom',
        phone: '+8801712345678',
        isPrimary: true,
      ),
    ]);

    cubit = BatteryCubit(
      batteryService: mockBattery,
      notificationService: mockNotification,
      smsService: mockSms,
      contactsRepository: mockContacts,
      alertsCubit: mockAlerts,
    );
  });

  setUpAll(() {
    registerFallbackValue(const EmergencyContact(
      name: 'fallback',
      phone: '000',
    ));
    registerFallbackValue(AlertEvent(
      type: AlertType.batteryCritical,
      title: 'fallback',
      latitude: 0,
      longitude: 0,
      timestamp: DateTime(2026),
    ));
  });

  tearDown(() => cubit.close());

  group('BatteryCubit', () {
    test('initial state is BatteryUnknown', () {
      expect(cubit.state, const BatteryUnknown());
    });

    test('startMonitoring registers callback', () {
      cubit.startMonitoring();

      verify(() => mockBattery.startMonitoring(
            onLevelChanged: any(named: 'onLevelChanged'),
          )).called(1);
    });

    test('emits BatteryNormal for level > 15%', () async {
      cubit.startMonitoring();
      batteryCallback(80, bp.BatteryState.discharging);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BatteryNormal>());
      expect(cubit.state.level, 80);
    });

    test('emits BatteryLow for level ≤ 15%', () async {
      cubit.startMonitoring();
      batteryCallback(12, bp.BatteryState.discharging);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BatteryLow>());
      expect(cubit.state.level, 12);
    });

    test('emits BatteryCritical for level ≤ 5%', () async {
      cubit.startMonitoring();
      batteryCallback(3, bp.BatteryState.discharging);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BatteryCritical>());
      expect(cubit.state.level, 3);
    });

    test('sends SMS alert on critical level', () async {
      cubit.startMonitoring();
      batteryCallback(3, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockNotification.showBatteryAlert(3)).called(1);
      verify(() => mockSms.sendBatteryAlert(
            contact: any(named: 'contact'),
            batteryLevel: 3,
          )).called(1);
    });

    test('sends critical alert only once', () async {
      cubit.startMonitoring();
      batteryCallback(4, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      batteryCallback(3, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Only the first critical call should trigger SMS.
      verify(() => mockSms.sendBatteryAlert(
            contact: any(named: 'contact'),
            batteryLevel: any(named: 'batteryLevel'),
          )).called(1);
    });

    test('resets critical flag when charging', () async {
      cubit.startMonitoring();
      // Go critical.
      batteryCallback(3, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Start charging — resets flag.
      batteryCallback(10, bp.BatteryState.charging);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Go critical again — should trigger new alert.
      batteryCallback(4, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSms.sendBatteryAlert(
            contact: any(named: 'contact'),
            batteryLevel: any(named: 'batteryLevel'),
          )).called(2); // 2 alerts total
    });

    test('emits BatteryNormal when charging', () async {
      cubit.startMonitoring();
      batteryCallback(50, bp.BatteryState.charging);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BatteryNormal>());
    });

    test('skips SMS when no contacts', () async {
      when(() => mockContacts.getAll()).thenReturn([]);

      cubit.startMonitoring();
      batteryCallback(3, bp.BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockNotification.showBatteryAlert(3)).called(1);
      verifyNever(() => mockSms.sendBatteryAlert(
            contact: any(named: 'contact'),
            batteryLevel: any(named: 'batteryLevel'),
          ));
    });

    test('close stops monitoring', () async {
      await cubit.close();

      verify(() => mockBattery.stopMonitoring()).called(1);
    });
  });
}
